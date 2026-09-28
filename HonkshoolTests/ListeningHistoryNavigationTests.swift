import XCTest

@testable import Honkshool

final class ListeningHistoryNavigationTests: XCTestCase {
  func testPartialResumeRequiresCurrentRevisionAndAvailableAudio() throws {
    let catalog = try PreparedCatalog.load()
    let record = try makeRecord(in: catalog, completed: false)
    let selection = try XCTUnwrap(
      ListeningHistoryNavigation.resume(
        record, in: catalog, isNarrationAvailable: { _ in true }))
    XCTAssertEqual(selection.resumePoint?.audioOffset, 120)
    XCTAssertEqual(selection.sessionID, record.plannedSession.session.id)

    XCTAssertNil(
      ListeningHistoryNavigation.resume(
        record, in: catalog, isNarrationAvailable: { _ in false }))
    XCTAssertNil(
      ListeningHistoryNavigation.replay(
        record, in: catalog, isNarrationAvailable: { _ in false }))

    let changed = try makeRecord(in: catalog, completed: false, revision: "previous")
    XCTAssertNil(
      ListeningHistoryNavigation.resume(
        changed, in: catalog, isNarrationAvailable: { _ in true }))
    XCTAssertNotNil(
      ListeningHistoryNavigation.replay(
        changed, in: catalog, isNarrationAvailable: { _ in true }))
    var staleHistory = ListeningHistory()
    try staleHistory.append(changed)
    XCTAssertNil(
      ListeningHistoryNavigation.next(
        in: catalog, history: staleHistory,
        isNarrationAvailable: { _ in true })?.resumePoint)
  }

  func testContinueAdvancesOnlyAfterCompletionAndKeepsEarlierAttempt() throws {
    let catalog = try PreparedCatalog.load()
    let partial = try makeRecord(in: catalog, completed: false)
    var history = ListeningHistory()
    try history.append(partial)
    let continued = ListeningHistoryNavigation.next(
      in: catalog, history: history, isNarrationAvailable: { _ in true })
    XCTAssertEqual(continued?.sessionID, partial.plannedSession.session.id)
    XCTAssertEqual(continued?.resumePoint, partial.resumePoint)
    XCTAssertFalse(
      ListeningHistoryNavigation.allAvailableJourneysCompleted(
        in: catalog, history: history))
    XCTAssertNil(
      ListeningHistoryNavigation.next(
        in: catalog, history: history, isNarrationAvailable: { _ in false }))

    let laterPartial = try makeRecord(
      in: catalog, completed: false, runID: "later-partial", startOffset: 1_000)
    try history.append(laterPartial)
    XCTAssertEqual(
      ListeningHistoryNavigation.next(
        in: catalog, history: history, isNarrationAvailable: { _ in true })?.resumePoint,
      laterPartial.resumePoint)

    let completed = try makeRecord(in: catalog, completed: true)
    try history.append(completed)
    XCTAssertEqual(history.records.count, 3)
    let second = ListeningHistoryNavigation.next(
      in: catalog, history: history, isNarrationAvailable: { _ in true })
    XCTAssertEqual(second?.sessionID, "air-fuel-and-spark")
    XCTAssertNil(second?.resumePoint)
    XCTAssertFalse(
      ListeningHistoryNavigation.allAvailableJourneysCompleted(
        in: catalog, history: history))
    XCTAssertNotNil(history.resumeSelection(for: partial.id))

    let secondPartial = try makeRecord(
      in: catalog, completed: false, runID: "second-partial",
      sessionID: "air-fuel-and-spark")
    try history.append(secondPartial)
    let resumedSecond = ListeningHistoryNavigation.next(
      in: catalog, history: history, isNarrationAvailable: { _ in true })
    XCTAssertEqual(resumedSecond?.sessionID, "air-fuel-and-spark")
    XCTAssertEqual(resumedSecond?.resumePoint, secondPartial.resumePoint)

    let replay = try XCTUnwrap(
      ListeningHistoryNavigation.replay(
        completed, in: catalog, isNarrationAvailable: { _ in true }))
    XCTAssertEqual(replay.sessionID, "turning-fuel-into-motion")
    XCTAssertNil(replay.resumePoint)
    XCTAssertEqual(history.records.count, 4)
    XCTAssertEqual(history.completedSessionIDs(in: "how-a-car-works"), ["turning-fuel-into-motion"])
    let replayAttempt = try makeRecord(
      in: catalog, completed: true, runID: "replay-first")
    try history.append(replayAttempt)
    XCTAssertEqual(history.records.count, 5)
    XCTAssertEqual(
      ListeningHistoryNavigation.next(
        in: catalog, history: history, isNarrationAvailable: { _ in true })?.sessionID,
      "air-fuel-and-spark")

    let secondCompleted = try makeRecord(
      in: catalog, completed: true, runID: "second-completed",
      sessionID: "air-fuel-and-spark")
    try history.append(secondCompleted)
    XCTAssertNil(
      ListeningHistoryNavigation.next(
        in: catalog, history: history, isNarrationAvailable: { _ in true }))
    XCTAssertTrue(
      ListeningHistoryNavigation.allAvailableJourneysCompleted(
        in: catalog, history: history))
    XCTAssertNotNil(
      ListeningHistoryNavigation.resume(
        secondPartial, in: catalog, isNarrationAvailable: { _ in true }))
  }

  private func makeRecord(
    in catalog: PreparedCatalog, completed: Bool, revision: String? = nil,
    runID: String? = nil, startOffset: TimeInterval = 0,
    sessionID: String = "turning-fuel-into-motion"
  ) throws -> PlaybackRecord {
    let journey = try XCTUnwrap(catalog.journeys.first { $0.id == "how-a-car-works" })
    let prepared = try XCTUnwrap(catalog.sessions[sessionID])
    let asset = try XCTUnwrap(prepared.narrationAsset)
    let session = try Session(
      id: prepared.session.id, revision: revision ?? prepared.session.revision,
      title: prepared.session.title, estimatedDuration: prepared.session.estimatedDuration)
    let start = Date(timeIntervalSince1970: 1_800_000_000 + startOffset)
    let point = try ResumePoint(
      session: session, audioOffset: startOffset == 0 ? 120 : 180,
      estimatedRemainingDuration: asset.duration - (startOffset == 0 ? 120 : 180),
      audioAssetSHA256: asset.sha256)
    let planned = PlannedSession(
      journeyID: journey.id, session: session, resumePoint: nil,
      estimatedStart: start, estimatedEnd: start.addingTimeInterval(session.estimatedDuration))
    return try PlaybackRecord(
      restoringID: .init(runID: runID ?? (completed ? "completed" : "partial"), routeIndex: 0),
      planID: "plan", plannedSession: planned, startedAt: start,
      endedAt: start.addingTimeInterval(120), checkpointCapturedAt: nil,
      playedDuration: 120,
      outcome: completed ? .completed : .partial(reason: .stopped, resumePoint: point))
  }
}
