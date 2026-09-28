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
    XCTAssertNil(
      ListeningHistoryNavigation.next(
        in: catalog, history: history, isNarrationAvailable: { _ in true }))
    XCTAssertTrue(
      ListeningHistoryNavigation.allAvailableJourneysCompleted(
        in: catalog, history: history))
    XCTAssertNotNil(history.resumeSelection(for: partial.id))
  }

  private func makeRecord(
    in catalog: PreparedCatalog, completed: Bool, revision: String? = nil,
    runID: String? = nil, startOffset: TimeInterval = 0
  ) throws -> PlaybackRecord {
    let journey = try XCTUnwrap(catalog.journeys.first)
    let prepared = try XCTUnwrap(catalog.sessions[XCTUnwrap(journey.sessionIDs.first)])
    let session = try Session(
      id: prepared.session.id, revision: revision ?? prepared.session.revision,
      title: prepared.session.title, estimatedDuration: prepared.session.estimatedDuration)
    let start = Date(timeIntervalSince1970: 1_800_000_000 + startOffset)
    let point = try ResumePoint(
      session: session, audioOffset: startOffset == 0 ? 120 : 180,
      estimatedRemainingDuration: startOffset == 0 ? 500 : 440)
    let planned = PlannedSession(
      journeyID: journey.id, session: session, resumePoint: nil,
      estimatedStart: start, estimatedEnd: start.addingTimeInterval(730))
    return try PlaybackRecord(
      restoringID: .init(runID: runID ?? (completed ? "completed" : "partial"), routeIndex: 0),
      planID: "plan", plannedSession: planned, startedAt: start,
      endedAt: start.addingTimeInterval(120), checkpointCapturedAt: nil,
      playedDuration: 120,
      outcome: completed ? .completed : .partial(reason: .stopped, resumePoint: point))
  }
}
