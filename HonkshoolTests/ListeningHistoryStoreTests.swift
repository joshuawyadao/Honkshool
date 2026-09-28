import Foundation
import SwiftData
import XCTest

@testable import Honkshool

@MainActor
final class ListeningHistoryStoreTests: XCTestCase {
  private let start = Date(timeIntervalSince1970: 1_000)

  private func makePlan(id: String = "plan", selection: SessionSelection? = nil) throws -> NapPlan {
    let session = try Session(id: "one", revision: "v1", title: "One", estimatedDuration: 40)
    let journey = try Journey(id: "a", title: "A", sessionIDs: ["one"])
    let catalog = try NapCatalog(journeys: [journey], sessions: [session])
    let request = NapRequest(
      window: .duration(120),
      startingAt: selection ?? SessionSelection(journeyID: "a", sessionID: "one"),
      settlingDuration: 10)
    return try NapPlanner.makePlan(
      id: id, request: request, startingAt: start, now: start, catalog: catalog)
  }

  private func record(
    runID: String, at seconds: TimeInterval, completed: Bool = false,
    reason: PartialPlaybackReason = .interrupted, audioFingerprint: String? = nil,
    audioOffset: TimeInterval? = nil, planID: String = "plan"
  ) throws -> PlaybackRecord {
    let plan = try makePlan(id: planID)
    var playback = try NapPlayback(plan: plan, runID: runID)
    let outcome: PlaybackOutcome
    if completed {
      outcome = .completed
    } else {
      let point = try ResumePoint(
        session: plan.route[0].session, audioOffset: audioOffset ?? seconds - 10,
        estimatedRemainingDuration: 20, audioAssetSHA256: audioFingerprint)
      outcome = .partial(reason: reason, resumePoint: point)
    }
    return try playback.recordSession(
      startedAt: start.addingTimeInterval(10), endedAt: start.addingTimeInterval(seconds),
      playedDuration: seconds - 10, outcome: outcome)
  }

  private func tempStoreURL() throws -> URL {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
    return directory.appendingPathComponent("History.store")
  }

  func testDiskReopenRestoresPartialCompletionAndJourneyProgress() throws {
    let url = try tempStoreURL()
    let first = ListeningHistoryStore(storeURL: url)
    XCTAssertNil(first.errorMessage)
    let partial = try record(
      runID: "attempt-one", at: 20, audioFingerprint: String(repeating: "a", count: 64))
    let completed = try record(runID: "attempt-two", at: 30, completed: true)
    first.save(partial, isCheckpoint: false)
    first.save(completed, isCheckpoint: false)
    XCTAssertNil(first.errorMessage)

    let reopened = ListeningHistoryStore(storeURL: url)
    XCTAssertNil(reopened.errorMessage)
    XCTAssertEqual(reopened.entries.map(\.record), [completed, partial])
    XCTAssertEqual(reopened.history.records, [partial, completed])
    XCTAssertEqual(
      reopened.history.resumeSelection(for: partial.id)?.resumePoint?.audioAssetSHA256,
      String(repeating: "a", count: 64))
    let journey = try Journey(id: "a", title: "A", sessionIDs: ["one"])
    XCTAssertNil(reopened.history.nextSessionID(in: journey))
  }

  func testCheckpointRecoveryFinalReplacementAndIdempotency() throws {
    let url = try tempStoreURL()
    let first = ListeningHistoryStore(storeURL: url)
    let early = try record(runID: "run", at: 20)
    let later = try record(runID: "run", at: 25)
    let final = try record(runID: "run", at: 30, reason: .stopped)
    first.save(early, isCheckpoint: true)
    first.save(later, isCheckpoint: true)
    first.save(early, isCheckpoint: true)
    XCTAssertEqual(first.entries, [ListeningHistoryEntry(record: later, isCheckpoint: true)])

    let reopened = ListeningHistoryStore(storeURL: url)
    XCTAssertEqual(reopened.entries, [ListeningHistoryEntry(record: later, isCheckpoint: true)])
    reopened.save(final, isCheckpoint: false)
    reopened.save(later, isCheckpoint: true)
    reopened.save(final, isCheckpoint: false)
    XCTAssertEqual(reopened.entries, [ListeningHistoryEntry(record: final, isCheckpoint: false)])
    XCTAssertEqual(ListeningHistoryStore(storeURL: url).entries, reopened.entries)
  }

  func testStaleFinalCannotEraseNewerCheckpoint() throws {
    let store = ListeningHistoryStore(inMemoryOnly: true)
    let older = try record(runID: "run", at: 20)
    let newer = try record(runID: "run", at: 30)
    store.save(newer, isCheckpoint: true)
    store.save(older, isCheckpoint: false)
    XCTAssertEqual(store.entries, [ListeningHistoryEntry(record: newer, isCheckpoint: true)])
  }

  func testIncompatibleOrRegressedEvidenceCannotReplaceCheckpoint() throws {
    let store = ListeningHistoryStore(inMemoryOnly: true)
    let original = try record(runID: "run", at: 20, audioOffset: 10)
    store.save(original, isCheckpoint: true)
    store.save(try record(runID: "run", at: 25, audioOffset: 9), isCheckpoint: true)
    store.save(
      try record(runID: "run", at: 25, audioOffset: 15, planID: "other"),
      isCheckpoint: false)
    XCTAssertEqual(store.entries, [ListeningHistoryEntry(record: original, isCheckpoint: true)])
  }

  func testFailedSaveKeepsNewestEvidenceForRetry() throws {
    enum InjectedFailure: Error { case save }
    let store = ListeningHistoryStore(inMemoryOnly: true)
    let early = try record(runID: "run", at: 20)
    let newer = try record(runID: "run", at: 30)
    let final = try record(runID: "run", at: 35, completed: true)
    let otherRun = try record(runID: "other", at: 25)
    store.beforeSave = { throw InjectedFailure.save }
    store.save(early, isCheckpoint: true)
    store.save(newer, isCheckpoint: true)
    store.save(final, isCheckpoint: false)
    store.save(otherRun, isCheckpoint: true)
    XCTAssertNotNil(store.errorMessage)
    XCTAssertTrue(store.entries.isEmpty)

    store.beforeSave = nil
    store.retrySave()
    XCTAssertNil(store.errorMessage)
    XCTAssertEqual(
      store.entries,
      [
        ListeningHistoryEntry(record: final, isCheckpoint: false),
        ListeningHistoryEntry(record: otherRun, isCheckpoint: true),
      ])
  }

  func testCompletedRecordCannotBeClaimedAsCheckpoint() throws {
    let store = ListeningHistoryStore(inMemoryOnly: true)
    store.save(try record(runID: "run", at: 30, completed: true), isCheckpoint: true)
    XCTAssertNotNil(store.errorMessage)
    XCTAssertTrue(store.entries.isEmpty)
  }

  func testLateDeadlineEvidenceRoundTrips() throws {
    let url = try tempStoreURL()
    let plan = try makePlan()
    var playback = try NapPlayback(plan: plan, runID: "late")
    let point = try ResumePoint(
      session: plan.route[0].session, audioOffset: 17,
      estimatedRemainingDuration: 23, audioAssetSHA256: String(repeating: "b", count: 64))
    let late = try playback.recordSession(
      startedAt: start.addingTimeInterval(10), endedAt: start.addingTimeInterval(123),
      playedDuration: 108,
      outcome: .partial(reason: .deadlineMissed, resumePoint: point),
      checkpointCapturedAt: start.addingTimeInterval(119))
    let first = ListeningHistoryStore(storeURL: url)
    first.save(late, isCheckpoint: false)
    let restored = try XCTUnwrap(ListeningHistoryStore(storeURL: url).entries.first?.record)
    XCTAssertEqual(restored, late)
    XCTAssertEqual(restored.checkpointCapturedAt, start.addingTimeInterval(119))
    XCTAssertEqual(restored.endedAt, start.addingTimeInterval(123))
  }

  func testUnavailableStoreExposesFailureWithoutDiscardingLaterSave() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
    let blocker = directory.appendingPathComponent("file")
    try Data("blocker".utf8).write(to: blocker)
    let store = ListeningHistoryStore(storeURL: blocker.appendingPathComponent("History.store"))
    XCTAssertNotNil(store.errorMessage)
    store.save(try record(runID: "run", at: 20), isCheckpoint: true)
    store.retrySave()
    XCTAssertNotNil(store.errorMessage)
    XCTAssertTrue(store.entries.isEmpty)
    XCTAssertEqual(try Data(contentsOf: blocker), Data("blocker".utf8))
    try FileManager.default.removeItem(at: blocker)
    try FileManager.default.createDirectory(at: blocker, withIntermediateDirectories: true)
    store.retrySave()
    XCTAssertNil(store.errorMessage)
    XCTAssertEqual(store.entries.count, 1)
    XCTAssertEqual(
      ListeningHistoryStore(storeURL: blocker.appendingPathComponent("History.store")).entries,
      store.entries)
  }

  func testMalformedEvidenceIsReportedAndLeftOnDisk() throws {
    let url = try tempStoreURL()
    let schema = Schema(versionedSchema: ListeningHistorySchemaV1.self)
    let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
    let container = try ModelContainer(
      for: schema, migrationPlan: ListeningHistoryMigrationPlan.self,
      configurations: [configuration])
    let context = ModelContext(container)
    context.insert(
      ListeningHistorySchemaV1.StoredPlayback(
        key: "corrupt", payload: Data("not JSON".utf8), isCheckpoint: true,
        endedAt: start))
    try context.save()

    let store = ListeningHistoryStore(storeURL: url)
    XCTAssertNotNil(store.errorMessage)
    XCTAssertTrue(store.entries.isEmpty)
    XCTAssertEqual(
      try context.fetch(FetchDescriptor<ListeningHistorySchemaV1.StoredPlayback>()).count, 1)
  }
}
