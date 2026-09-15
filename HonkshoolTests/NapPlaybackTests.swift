import XCTest

@testable import Honkshool

final class NapPlaybackTests: XCTestCase {
  private let start = Date(timeIntervalSince1970: 1_000)

  private func session(_ id: String, duration: TimeInterval = 40) throws -> Session {
    try Session(id: id, revision: "v1", title: id, estimatedDuration: duration)
  }

  private func plan(
    duration: TimeInterval = 120, alarm: Bool = true, drift: TimeInterval = 10,
    startingAt selection: SessionSelection? = nil, transition: JourneyTransition? = nil
  ) throws -> NapPlan {
    let a = try Journey(
      id: "a", title: "A", sessionIDs: ["one", "two"], nextJourneyIDs: ["b", "c"])
    let b = try Journey(id: "b", title: "B", sessionIDs: ["three"])
    let c = try Journey(id: "c", title: "C", sessionIDs: ["four"])
    let catalog = try NapCatalog(
      journeys: [a, b, c],
      sessions: [session("one"), session("two"), session("three"), session("four")])
    let request = NapRequest(
      window: .duration(duration),
      startingAt: selection ?? SessionSelection(journeyID: "a", sessionID: "one"),
      approvedTransitions: transition.map { [$0] } ?? [],
      settlingDuration: 10, driftDuration: drift, fallback: .ambience(id: "rain"),
      alarmEnabled: alarm)
    return try NapPlanner.makePlan(
      id: "plan", request: request, startingAt: start, now: start, catalog: catalog,
      availableAmbienceIDs: ["rain"])
  }

  private func at(_ seconds: TimeInterval) -> Date { start.addingTimeInterval(seconds) }

  private func point(_ id: String = "one", offset: Int = 100, remaining: TimeInterval = 20) throws
    -> ResumePoint
  {
    try ResumePoint(
      session: session(id), utf16Offset: offset, estimatedRemainingDuration: remaining)
  }

  func testEarlyCompletionAdvancesOnlyWithinApprovedRouteAndFillsRemainingRest() throws {
    let approved = try plan()
    var playback = try NapPlayback(plan: approved, runID: "early")
    XCTAssertNil(try playback.nextSession(at: at(9)))
    XCTAssertEqual(try playback.nextSession(at: at(10))?.session.id, "one")
    XCTAssertNil(try playback.remainingRestSegments())
    try playback.recordSession(
      startedAt: at(10), endedAt: at(30), playedDuration: 20, outcome: .completed)
    XCTAssertEqual(try playback.nextSession(at: at(30))?.session.id, "two")
    XCTAssertLessThan(at(30), approved.route[1].estimatedStart)
    try playback.recordSession(
      startedAt: at(30), endedAt: at(50), playedDuration: 20, outcome: .completed)
    XCTAssertNil(try playback.nextSession(at: at(50)))
    let rest = try XCTUnwrap(playback.remainingRestSegments())
    XCTAssertEqual(rest.map(\.kind), [.drift(.ambience(id: "rain")), .rest(.ambience(id: "rain"))])
    XCTAssertEqual(rest.map(\.duration), [10, 60])
    XCTAssertEqual(rest.last?.end, at(120))
    XCTAssertEqual(playback.plan, approved)
    XCTAssertEqual(playback.plan.wakeAlarm, at(120))
  }

  func testElapsedEstimateAloneDoesNotAdvanceOrComplete() throws {
    var playback = try NapPlayback(plan: plan(), runID: "partial")
    XCTAssertEqual(try playback.nextSession(at: at(90))?.session.id, "one")
    XCTAssertTrue(playback.records.isEmpty)
    let record = try playback.recordSession(
      startedAt: at(10), endedAt: at(90), playedDuration: 70,
      outcome: .partial(reason: .interrupted, resumePoint: point()))
    XCTAssertFalse(record.isCompleted)
    XCTAssertEqual(record.playedDuration, 70)
    XCTAssertEqual(record.resumePoint?.utf16Offset, 100)
    XCTAssertNil(try playback.nextSession(at: at(90)))
    XCTAssertNil(try playback.remainingRestSegments())
  }

  func testOverrunStopsAtFixedDeadlineRetainsCheckpointAndLeavesLaterSessionUnplayed() throws {
    let approved = try plan()
    var playback = try NapPlayback(plan: approved, runID: "overrun")
    XCTAssertFalse(try playback.mustStop(at: at(119)))
    XCTAssertTrue(try playback.mustStop(at: at(120)))
    XCTAssertNil(try playback.nextSession(at: at(120)))
    let record = try playback.recordSession(
      startedAt: at(10), endedAt: at(120), playedDuration: 100,
      outcome: .partial(reason: .deadlineReached, resumePoint: point(offset: 800, remaining: 5)))
    XCTAssertEqual(
      record.outcome,
      .partial(
        reason: .deadlineReached, resumePoint: try point(offset: 800, remaining: 5)))
    XCTAssertEqual(playback.records.count, 1)
    XCTAssertEqual(playback.plan.route.map { $0.session.id }, ["one", "two"])
    XCTAssertEqual(playback.plan.deadline, at(120))
    XCTAssertEqual(playback.plan.wakeAlarm, at(120))
    var history = ListeningHistory()
    try history.append(record)
    let journey = try Journey(id: "a", title: "A", sessionIDs: ["one", "two"])
    XCTAssertEqual(history.nextSessionID(in: journey), "one")
  }

  func testLateNaturalEndCannotBecomeCompletionOrInventACutoffCheckpoint() throws {
    var playback = try NapPlayback(plan: plan(), runID: "late")
    XCTAssertThrowsError(
      try playback.recordSession(
        startedAt: at(10), endedAt: at(121), playedDuration: 111, outcome: .completed
      )
    ) { XCTAssertEqual($0 as? NapDomainError, .deadlineExceeded) }
    XCTAssertTrue(playback.records.isEmpty)
    // A callback delivered late can still carry actual evidence captured at the cutoff.
    let record = try playback.recordSession(
      startedAt: at(10), endedAt: at(120), playedDuration: 110,
      outcome: .partial(reason: .stopped, resumePoint: point()))
    XCTAssertEqual(record.outcome, .partial(reason: .deadlineReached, resumePoint: try point()))
    XCTAssertThrowsError(
      try playback.recordSession(
        startedAt: at(120), endedAt: at(120), playedDuration: 0, outcome: .completed
      )
    ) { XCTAssertEqual($0 as? NapDomainError, .playbackEnded) }
  }

  func testActualCompletionExactlyAtDeadlineCountsEvenWhenEstimateWasShorter() throws {
    var playback = try NapPlayback(plan: plan(duration: 60), runID: "exact")
    let record = try playback.recordSession(
      startedAt: at(10), endedAt: at(60), playedDuration: 50, outcome: .completed)
    XCTAssertTrue(record.isCompleted)
    XCTAssertNil(record.resumePoint)
    XCTAssertEqual(try playback.remainingRestSegments(), [])
    XCTAssertTrue(try playback.mustStop(at: at(60)))
  }

  func testDeadlineStillAppliesWithAlarmDisabled() throws {
    var playback = try NapPlayback(plan: plan(alarm: false), runID: "no-alarm")
    XCTAssertNil(playback.plan.wakeAlarm)
    XCTAssertTrue(try playback.mustStop(at: at(120)))
    let record = try playback.recordSession(
      startedAt: at(10), endedAt: at(120), playedDuration: 110,
      outcome: .partial(reason: .deadlineReached, resumePoint: point()))
    XCTAssertFalse(record.isCompleted)
  }

  func testFractionalPlayedDurationToleratesOnlyDateRepresentationRounding() throws {
    var playback = try NapPlayback(plan: plan(), runID: "fractional")
    XCTAssertThrowsError(
      try playback.recordSession(
        startedAt: at(10), endedAt: at(10.2), playedDuration: 0.201, outcome: .completed))
    let record = try playback.recordSession(
      startedAt: at(10), endedAt: at(10.2), playedDuration: 0.2, outcome: .completed)
    XCTAssertTrue(record.isCompleted)
    XCTAssertEqual(record.playedDuration, 0.2)
    XCTAssertEqual(record.endedAt, at(10.2))
  }

  func testPartialResumeUsesContentPositionAndRemainingEstimateThenActualCompletionAdvances() throws
  {
    var first = try NapPlayback(plan: plan(), runID: "original")
    let partial = try first.recordSession(
      startedAt: at(10), endedAt: at(25), playedDuration: 15,
      outcome: .partial(reason: .stopped, resumePoint: point(offset: 75, remaining: 12)))
    var history = ListeningHistory()
    try history.append(partial)
    let selection = try XCTUnwrap(history.resumeSelection(for: partial.id))
    XCTAssertEqual(selection.resumePoint?.utf16Offset, 75)
    let resumedPlan = try plan(duration: 32, startingAt: selection)
    XCTAssertEqual(resumedPlan.route.count, 1)
    XCTAssertEqual(resumedPlan.route[0].estimatedEnd, at(22))
    var resumed = try NapPlayback(plan: resumedPlan, runID: "resumed")
    let complete = try resumed.recordSession(
      startedAt: at(10), endedAt: at(30), playedDuration: 20, outcome: .completed)
    try history.append(complete)
    let journey = try Journey(id: "a", title: "A", sessionIDs: ["one", "two"])
    XCTAssertEqual(history.nextSessionID(in: journey), "two")
    XCTAssertEqual(history.records, [partial, complete])
    XCTAssertEqual(history.resumeSelection(for: partial.id), selection)
    XCTAssertNil(history.resumeSelection(for: complete.id))
  }

  func testInvalidPlaybackEvidenceDoesNotMutateRun() throws {
    var playback = try NapPlayback(plan: plan(), runID: "invalid")
    let invalidTimes: [(Date, Date, TimeInterval)] = [
      (at(9), at(20), 10), (at(10), at(9), 0), (at(10), at(20), 11),
      (at(10), at(20), -1), (at(10), at(20), .nan),
      (Date(timeIntervalSince1970: .infinity), at(20), 0), (at(120), at(120), 0),
    ]
    for (began, ended, played) in invalidTimes {
      XCTAssertThrowsError(
        try playback.recordSession(
          startedAt: began, endedAt: ended, playedDuration: played, outcome: .completed))
    }
    XCTAssertThrowsError(
      try playback.recordSession(
        startedAt: at(10), endedAt: at(20), playedDuration: 10,
        outcome: .partial(reason: .deadlineReached, resumePoint: point())))
    XCTAssertThrowsError(
      try playback.recordSession(
        startedAt: at(10), endedAt: at(20), playedDuration: 10,
        outcome: .partial(reason: .stopped, resumePoint: point("two"))))
    XCTAssertTrue(playback.records.isEmpty)
    XCTAssertThrowsError(try playback.mustStop(at: Date(timeIntervalSince1970: .nan)))
  }

  func testResumedCheckpointCannotMoveBackwardsOrChangeRevision() throws {
    let selection = SessionSelection(journeyID: "a", sessionID: "one", resumePoint: try point())
    var playback = try NapPlayback(plan: plan(startingAt: selection), runID: "resume")
    let revised = try Session(id: "one", revision: "v2", title: "One", estimatedDuration: 40)
    for resume in [
      try point(offset: 99),
      try ResumePoint(
        session: revised, utf16Offset: 150, estimatedRemainingDuration: 20),
    ] {
      XCTAssertThrowsError(
        try playback.recordSession(
          startedAt: at(10), endedAt: at(20), playedDuration: 10,
          outcome: .partial(reason: .stopped, resumePoint: resume))
      ) {
        XCTAssertEqual($0 as? NapDomainError, .invalidResumePoint)
      }
    }
    XCTAssertTrue(playback.records.isEmpty)
  }

  func testReplayRestartAndAlternateBranchesAppendHistoryWithoutErasingEarlierPaths() throws {
    var history = ListeningHistory()
    var first = try NapPlayback(
      plan: plan(duration: 160, transition: .init(from: "a", to: "b")), runID: "first")
    for index in 0..<3 {
      try history.append(
        first.recordSession(
          startedAt: at(10 + Double(index) * 40), endedAt: at(50 + Double(index) * 40),
          playedDuration: 40, outcome: .completed))
    }
    let original = history.records
    var replay = try NapPlayback(plan: plan(), runID: "replay")
    try history.append(
      replay.recordSession(
        startedAt: at(10), endedAt: at(20), playedDuration: 10,
        outcome: .partial(reason: .stopped, resumePoint: point())))
    var restart = try NapPlayback(
      plan: plan(duration: 160, transition: .init(from: "a", to: "c")), runID: "restart-alternate")
    for index in 0..<3 {
      try history.append(
        restart.recordSession(
          startedAt: at(10 + Double(index) * 40), endedAt: at(50 + Double(index) * 40),
          playedDuration: 40, outcome: .completed))
    }
    XCTAssertEqual(Array(history.records.prefix(3)), original)
    XCTAssertEqual(history.records.count, 7)
    XCTAssertEqual(history.completedSessionIDs(in: "a"), ["one", "two"])
    XCTAssertEqual(history.completedSessionIDs(in: "b"), ["three"])
    XCTAssertEqual(history.completedSessionIDs(in: "c"), ["four"])
    XCTAssertEqual(first.plan.transitions, [.init(from: "a", to: "b")])
    XCTAssertEqual(restart.plan.transitions, [.init(from: "a", to: "c")])
    XCTAssertThrowsError(try history.append(original[0])) {
      XCTAssertEqual($0 as? NapDomainError, .duplicatePlaybackRecord)
    }
    XCTAssertEqual(history.records.count, 7)
  }

  func testCompletingLaterSessionDoesNotSkipEarlierIncompleteGap() throws {
    var playback = try NapPlayback(
      plan: plan(startingAt: .init(journeyID: "a", sessionID: "two")), runID: "later")
    var history = ListeningHistory()
    try history.append(
      playback.recordSession(
        startedAt: at(10), endedAt: at(50), playedDuration: 40, outcome: .completed))
    let journey = try Journey(id: "a", title: "A", sessionIDs: ["one", "two"])
    XCTAssertEqual(history.completedSessionIDs(in: "a"), ["two"])
    XCTAssertEqual(history.nextSessionID(in: journey), "one")
  }

  func testOverlappingReportsAreRejectedAndEmptyRouteHasRestWithoutPlayedHistory() throws {
    var playback = try NapPlayback(plan: plan(), runID: "overlap")
    try playback.recordSession(
      startedAt: at(10), endedAt: at(30), playedDuration: 20, outcome: .completed)
    XCTAssertNil(try playback.nextSession(at: at(29)))
    XCTAssertThrowsError(
      try playback.recordSession(
        startedAt: at(29), endedAt: at(60), playedDuration: 30, outcome: .completed))
    XCTAssertEqual(playback.records.count, 1)
    let empty = try NapPlayback(plan: plan(duration: 30), runID: "empty")
    XCTAssertTrue(empty.plan.route.isEmpty)
    XCTAssertNil(try empty.nextSession(at: at(10)))
    XCTAssertTrue(empty.records.isEmpty)
    XCTAssertEqual(try empty.remainingRestSegments()?.map(\.duration), [10, 10])
  }
}
