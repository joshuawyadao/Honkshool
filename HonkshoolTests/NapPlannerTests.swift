import XCTest

@testable import Honkshool

final class NapPlannerTests: XCTestCase {
  private let now = Date(timeIntervalSince1970: 1_000)

  func testExactFitIncludesSettlingNarrationAndDriftWithFixedAlarm() throws {
    let catalog = try catalog(durations: [10, 15])
    var request = request(duration: 35)
    request.settlingDuration = 4
    request.driftDuration = 6
    request.alarmEnabled = true

    let plan = try plan(request, catalog: catalog)

    XCTAssertEqual(plan.route.map(\.session.id), ["s0", "s1"])
    XCTAssertEqual(
      plan.segments.map(\.kind),
      [
        .settling(.silence), .narration(routeIndex: 0), .narration(routeIndex: 1),
        .drift(.silence),
      ])
    XCTAssertEqual(plan.segments.map(\.duration), [4, 10, 15, 6])
    XCTAssertEqual(plan.route.first?.estimatedStart, now.addingTimeInterval(4))
    XCTAssertEqual(plan.route.last?.estimatedEnd, now.addingTimeInterval(29))
    XCTAssertEqual(plan.deadline, now.addingTimeInterval(35))
    XCTAssertEqual(plan.wakeAlarm, plan.deadline)
    XCTAssertEqual(plan.routeEndReason, .windowFilled)
    assertContinuous(plan)
  }

  func testUnusedTimeBecomesRestAfterDrift() throws {
    var request = request(duration: 40)
    request.settlingDuration = 3
    request.driftDuration = 5

    let plan = try plan(request, catalog: catalog(durations: [10]))

    XCTAssertEqual(
      plan.segments.map(\.kind),
      [
        .settling(.silence), .narration(routeIndex: 0), .drift(.silence), .rest(.silence),
      ])
    XCTAssertEqual(plan.segments.map(\.duration), [3, 10, 5, 22])
    XCTAssertEqual(plan.routeEndReason, .journeyEnded)
    XCTAssertNil(plan.wakeAlarm)
    assertContinuous(plan)
  }

  func testFractionalEstimatesExactlyFillWindowAtModernDatePrecision() throws {
    let start = Date(timeIntervalSinceReferenceDate: 800_000_000)
    let plan = try NapPlanner.makePlan(
      id: "fractional", request: request(duration: 1_200.4), startingAt: start, now: start,
      catalog: catalog(durations: [600.2, 600.2]))

    XCTAssertEqual(plan.route.map(\.session.id), ["s0", "s1"])
    XCTAssertEqual(plan.route.last?.estimatedEnd, plan.deadline)
    XCTAssertEqual(plan.routeEndReason, .windowFilled)
    XCTAssertEqual(plan.segments.count, 2)
    assertContinuous(plan)
  }

  func testFractionalFitToleranceDoesNotAdmitSessionBeyondDeadline() throws {
    let start = Date(timeIntervalSinceReferenceDate: 800_000_000)
    let plan = try NapPlanner.makePlan(
      id: "fractional", request: request(duration: 1_200.399), startingAt: start, now: start,
      catalog: catalog(durations: [600.2, 600.2]))

    XCTAssertEqual(plan.route.map(\.session.id), ["s0"])
    XCTAssertEqual(plan.routeEndReason, .nextSessionDoesNotFit)
    XCTAssertEqual(plan.segments.last?.kind, .rest(.silence))
    XCTAssertLessThan(try XCTUnwrap(plan.route.last?.estimatedEnd), plan.deadline)
    assertContinuous(plan)
  }

  func testWakeTimeUsesInjectedStartAndNow() throws {
    let start = now.addingTimeInterval(20)
    let deadline = now.addingTimeInterval(50)
    let request = NapRequest(window: .wakeTime(deadline), startingAt: selection())
    let catalog = try catalog(durations: [10, 20])

    let plan = try NapPlanner.makePlan(
      id: "future", request: request, startingAt: start, now: now, catalog: catalog)

    XCTAssertEqual(plan.start, start)
    XCTAssertEqual(plan.deadline, deadline)
    XCTAssertEqual(plan.segments.map(\.duration), [10, 20])
    XCTAssertEqual(
      plan,
      try NapPlanner.makePlan(
        id: "future", request: request, startingAt: start, now: now, catalog: catalog))
  }

  func testPastStartAndNonfiniteClockInputsAreRejected() throws {
    let catalog = try catalog(durations: [10])
    for start in [
      now.addingTimeInterval(-1), Date(timeIntervalSince1970: .infinity),
      Date(timeIntervalSince1970: .nan),
    ] {
      XCTAssertThrowsError(
        try NapPlanner.makePlan(
          id: "plan", request: request(duration: 20), startingAt: start, now: now,
          catalog: catalog)
      ) { XCTAssertEqual($0 as? NapDomainError, .invalidDeadline) }
    }
    XCTAssertThrowsError(
      try NapPlanner.makePlan(
        id: "plan", request: request(duration: 20), startingAt: now,
        now: Date(timeIntervalSince1970: .nan), catalog: catalog)
    ) { XCTAssertEqual($0 as? NapDomainError, .invalidDeadline) }
  }

  func testPastEqualAndNonfiniteWakeDeadlinesAreRejected() throws {
    let catalog = try catalog(durations: [10])
    for deadline in [
      now.addingTimeInterval(-1), now,
      Date(timeIntervalSince1970: .infinity), Date(timeIntervalSince1970: .nan),
    ] {
      let request = NapRequest(window: .wakeTime(deadline), startingAt: selection())
      XCTAssertThrowsError(try plan(request, catalog: catalog)) {
        XCTAssertEqual($0 as? NapDomainError, .invalidDeadline)
      }
    }
  }

  func testInvalidWindowSettlingAndDriftDurationsAreRejected() throws {
    let catalog = try catalog(durations: [10])
    for duration in [0, -1, TimeInterval.infinity, .nan] {
      XCTAssertThrowsError(try plan(request(duration: duration), catalog: catalog)) {
        XCTAssertEqual($0 as? NapDomainError, .invalidDuration)
      }
    }
    for duration in [-1, TimeInterval.infinity, .nan] {
      var settling = request(duration: 20)
      settling.settlingDuration = duration
      XCTAssertThrowsError(try plan(settling, catalog: catalog)) {
        XCTAssertEqual($0 as? NapDomainError, .invalidDuration)
      }
      var drift = request(duration: 20)
      drift.driftDuration = duration
      XCTAssertThrowsError(try plan(drift, catalog: catalog)) {
        XCTAssertEqual($0 as? NapDomainError, .invalidDuration)
      }
    }
  }

  func testVeryShortWindowAllocatesSettlingBeforeDriftWithoutNarration() throws {
    var request = request(duration: 4)
    request.settlingDuration = 3
    request.driftDuration = 6

    let plan = try plan(request, catalog: catalog(durations: [10]))

    XCTAssertTrue(plan.route.isEmpty)
    XCTAssertEqual(plan.segments.map(\.kind), [.settling(.silence), .drift(.silence)])
    XCTAssertEqual(plan.segments.map(\.duration), [3, 1])
    XCTAssertEqual(plan.deadline, now.addingTimeInterval(4))
    assertContinuous(plan)
  }

  func testSettlingCanOccupyTheEntireShortWindow() throws {
    var request = request(duration: 2)
    request.settlingDuration = 3
    request.driftDuration = 6

    let plan = try plan(request, catalog: catalog(durations: [10]))

    XCTAssertTrue(plan.route.isEmpty)
    XCTAssertEqual(plan.segments.map(\.kind), [.settling(.silence)])
    XCTAssertEqual(plan.segments.map(\.duration), [2])
    XCTAssertEqual(plan.driftDuration, 0)
    assertContinuous(plan)
  }

  func testShortWindowUsesAvailableSelectedAmbienceWithoutTruncatingSession() throws {
    var request = request(duration: 5)
    request.fallback = .ambience(id: "rain")

    let plan = try plan(
      request, catalog: catalog(durations: [10]), availableAmbienceIDs: ["rain"])

    XCTAssertTrue(plan.route.isEmpty)
    XCTAssertFalse(plan.usedShorterAlternative)
    XCTAssertEqual(plan.routeEndReason, .nextSessionDoesNotFit)
    XCTAssertEqual(plan.fallback, .ambience(id: "rain"))
    XCTAssertEqual(plan.segments.map(\.kind), [.rest(.ambience(id: "rain"))])
    XCTAssertEqual(plan.segments.map(\.duration), [5])
  }

  func testUnavailableAmbienceFallsBackToSilence() throws {
    var request = request(duration: 5)
    request.fallback = .ambience(id: "missing")
    let plan = try plan(
      request, catalog: catalog(durations: [10]), availableAmbienceIDs: ["rain"])

    XCTAssertEqual(plan.fallback, .silence)
    XCTAssertEqual(plan.segments.map(\.kind), [.rest(.silence)])
  }

  func testSilenceSelectionStaysSilentWhenAmbienceIsAvailable() throws {
    let plan = try plan(
      request(duration: 5), catalog: catalog(durations: [10]),
      availableAmbienceIDs: ["rain"])

    XCTAssertTrue(plan.route.isEmpty)
    XCTAssertEqual(plan.fallback, .silence)
    XCTAssertEqual(plan.segments.map(\.kind), [.rest(.silence)])
  }

  func testExplicitAvailableShorterAlternativeFitsWithItsOriginalEstimate() throws {
    var request = request(duration: 6)
    request.shorterAlternatives = [selection(sessionID: "s1")]

    let plan = try plan(request, catalog: catalog(durations: [10, 4]))

    XCTAssertEqual(plan.route.map(\.session.id), ["s1"])
    XCTAssertEqual(plan.route.first?.session.estimatedDuration, 4)
    XCTAssertTrue(plan.usedShorterAlternative)
    XCTAssertEqual(plan.segments.map(\.duration), [4, 2])
  }

  func testShorterAlternativesRespectPreapprovedPreferenceAndSkipUnavailableContent() throws {
    let journey = try Journey(id: "j", title: "Journey", sessionIDs: ["long", "missing", "a", "b"])
    let catalog = try NapCatalog(
      journeys: [journey], sessions: [session("long", 20), session("a", 4), session("b", 3)])
    var request = NapRequest(window: .duration(5), startingAt: selection(sessionID: "long"))
    request.shorterAlternatives = [
      selection(sessionID: "missing"), selection(sessionID: "a"), selection(sessionID: "b"),
    ]

    let plan = try plan(request, catalog: catalog)

    XCTAssertEqual(plan.route.map(\.session.id), ["a"])
    XCTAssertTrue(plan.usedShorterAlternative)
    XCTAssertEqual(plan.segments.map(\.duration), [4, 1])
  }

  func testUnapprovedShorterSessionIsNeverSelectedAutomatically() throws {
    let plan = try plan(request(duration: 5), catalog: catalog(durations: [10, 4]))

    XCTAssertTrue(plan.route.isEmpty)
    XCTAssertFalse(plan.usedShorterAlternative)
    XCTAssertEqual(plan.segments.map(\.kind), [.rest(.silence)])
  }

  func testAlternativeDoesNotReplaceAnAlreadyFittingMainRoute() throws {
    var request = request(duration: 10)
    request.shorterAlternatives = [selection(sessionID: "s1")]

    let plan = try plan(request, catalog: catalog(durations: [8, 3]))

    XCTAssertEqual(plan.route.map(\.session.id), ["s0"])
    XCTAssertFalse(plan.usedShorterAlternative)
    XCTAssertEqual(plan.routeEndReason, .nextSessionDoesNotFit)
  }

  func testLongPlanCrossesOnlyThePreapprovedJourneyBoundary() throws {
    let first = try Journey(
      id: "j", title: "First", sessionIDs: ["a", "b"], nextJourneyIDs: ["k", "other"])
    let next = try Journey(id: "k", title: "Next", sessionIDs: ["c", "d"])
    let other = try Journey(id: "other", title: "Other", sessionIDs: ["e"])
    let catalog = try NapCatalog(
      journeys: [first, next, other],
      sessions: [
        session("a", 10), session("b", 10), session("c", 15), session("d", 5), session("e", 1),
      ])
    let transition = JourneyTransition(from: "j", to: "k")
    var request = NapRequest(window: .duration(45), startingAt: selection(sessionID: "a"))
    request.approvedTransitions = [transition]

    let plan = try plan(request, catalog: catalog)

    XCTAssertEqual(plan.route.map(\.session.id), ["a", "b", "c", "d"])
    XCTAssertEqual(plan.route.map(\.journeyID), ["j", "j", "k", "k"])
    XCTAssertEqual(plan.transitions, [transition])
    XCTAssertEqual(plan.segments.map(\.duration), [10, 10, 15, 5, 5])
    XCTAssertEqual(plan.routeEndReason, .journeyEnded)
    assertContinuous(plan)
  }

  func testAvailableJourneyBoundaryRequiresPreapproval() throws {
    let first = try Journey(id: "j", title: "First", sessionIDs: ["a"], nextJourneyIDs: ["k"])
    let next = try Journey(id: "k", title: "Next", sessionIDs: ["b"])
    let catalog = try NapCatalog(
      journeys: [first, next], sessions: [session("a", 5), session("b", 5)])
    let request = NapRequest(window: .duration(20), startingAt: selection(sessionID: "a"))

    let plan = try plan(request, catalog: catalog)

    XCTAssertEqual(plan.route.map(\.session.id), ["a"])
    XCTAssertTrue(plan.transitions.isEmpty)
    XCTAssertEqual(plan.segments.map(\.duration), [5, 15])
    XCTAssertEqual(plan.routeEndReason, .journeyEnded)
  }

  func testMissingSubsequentSessionStopsBeforeLaterAvailableContent() throws {
    let journey = try Journey(id: "j", title: "Journey", sessionIDs: ["a", "missing", "c"])
    let catalog = try NapCatalog(journeys: [journey], sessions: [session("a", 5), session("c", 5)])
    let request = NapRequest(window: .duration(30), startingAt: selection(sessionID: "a"))

    let plan = try plan(request, catalog: catalog)

    XCTAssertEqual(plan.route.map(\.session.id), ["a"])
    XCTAssertEqual(plan.routeEndReason, .contentUnavailable)
    XCTAssertEqual(plan.segments.map(\.duration), [5, 25])
  }

  func testMissingStartingContentUsesFallback() throws {
    let journey = try Journey(id: "j", title: "Journey", sessionIDs: ["s0"])
    let catalog = try NapCatalog(journeys: [journey], sessions: [])

    let plan = try plan(request(duration: 30), catalog: catalog)

    XCTAssertTrue(plan.route.isEmpty)
    XCTAssertEqual(plan.routeEndReason, .contentUnavailable)
    XCTAssertEqual(plan.segments.map(\.kind), [.rest(.silence)])
    XCTAssertEqual(plan.segments.map(\.duration), [30])
  }

  func testMissingOrEmptyPreapprovedNextJourneyUsesFallback() throws {
    let first = try Journey(id: "j", title: "First", sessionIDs: ["s0"], nextJourneyIDs: ["k"])
    let empty = try Journey(id: "k", title: "Empty", sessionIDs: [])
    var request = request(duration: 20)
    request.approvedTransitions = [JourneyTransition(from: "j", to: "k")]

    for journeys in [[first], [first, empty]] {
      let plan = try plan(
        request, catalog: NapCatalog(journeys: journeys, sessions: [session("s0", 5)]))
      XCTAssertEqual(plan.route.map(\.session.id), ["s0"])
      XCTAssertTrue(plan.transitions.isEmpty)
      XCTAssertEqual(plan.routeEndReason, .contentUnavailable)
      XCTAssertEqual(plan.segments.map(\.duration), [5, 15])
    }
  }

  func testOrderedRouteDoesNotSkipANonfittingSession() throws {
    let plan = try plan(request(duration: 12), catalog: catalog(durations: [5, 10, 3]))

    XCTAssertEqual(plan.route.map(\.session.id), ["s0"])
    XCTAssertEqual(plan.routeEndReason, .nextSessionDoesNotFit)
    XCTAssertEqual(plan.segments.map(\.duration), [5, 7])
  }

  func testInvalidStartingJourneyOrSessionIsRejected() throws {
    let catalog = try catalog(durations: [5])
    for startingAt in [selection(journeyID: "missing"), selection(sessionID: "missing")] {
      let request = NapRequest(window: .duration(20), startingAt: startingAt)
      XCTAssertThrowsError(try plan(request, catalog: catalog)) {
        XCTAssertEqual($0 as? NapDomainError, .invalidStartingPoint)
      }
    }
  }

  func testUnlistedAndAmbiguousTransitionsAreRejected() throws {
    let first = try Journey(
      id: "j", title: "First", sessionIDs: ["s0"], nextJourneyIDs: ["k", "other"])
    let catalog = try NapCatalog(journeys: [first], sessions: [session("s0", 5)])
    for transitions in [
      [JourneyTransition(from: "j", to: "unlisted")],
      [JourneyTransition(from: "absent", to: "k")],
      [JourneyTransition(from: "j", to: "k"), JourneyTransition(from: "j", to: "other")],
    ] {
      var request = request(duration: 20)
      request.approvedTransitions = transitions
      XCTAssertThrowsError(try plan(request, catalog: catalog)) {
        XCTAssertEqual($0 as? NapDomainError, .invalidTransition)
      }
    }
  }

  func testCyclicPreapprovedRouteIsRejected() throws {
    let first = try Journey(id: "j", title: "First", sessionIDs: ["s0"], nextJourneyIDs: ["k"])
    let next = try Journey(id: "k", title: "Next", sessionIDs: ["s1"], nextJourneyIDs: ["j"])
    let catalog = try NapCatalog(
      journeys: [first, next], sessions: [session("s0", 5), session("s1", 5)])
    var request = request(duration: 20)
    request.approvedTransitions = [
      JourneyTransition(from: "j", to: "k"), JourneyTransition(from: "k", to: "j"),
    ]

    XCTAssertThrowsError(try plan(request, catalog: catalog)) {
      XCTAssertEqual($0 as? NapDomainError, .cyclicRoute)
    }
  }

  func testDuplicateCatalogAndJourneyIdentitiesAreRejected() throws {
    let session = try session("s0", 5)
    let journey = try Journey(id: "j", title: "Journey", sessionIDs: [session.id])
    XCTAssertThrowsError(try NapCatalog(journeys: [journey, journey], sessions: [session])) {
      XCTAssertEqual($0 as? NapDomainError, .duplicateIdentity)
    }
    XCTAssertThrowsError(try NapCatalog(journeys: [journey], sessions: [session, session])) {
      XCTAssertEqual($0 as? NapDomainError, .duplicateIdentity)
    }
    XCTAssertThrowsError(try Journey(id: "j", title: "Journey", sessionIDs: ["s0", "s0"])) {
      XCTAssertEqual($0 as? NapDomainError, .duplicateIdentity)
    }
    XCTAssertThrowsError(
      try Journey(id: "j", title: "Journey", sessionIDs: [], nextJourneyIDs: ["k", "k"])
    ) {
      XCTAssertEqual($0 as? NapDomainError, .duplicateIdentity)
    }
  }

  func testEmptyStableIdentitiesAreRejected() throws {
    XCTAssertThrowsError(try session("", 5)) {
      XCTAssertEqual($0 as? NapDomainError, .invalidIdentity)
    }
    XCTAssertThrowsError(try session("s", 5, revision: "")) {
      XCTAssertEqual($0 as? NapDomainError, .invalidIdentity)
    }
    XCTAssertThrowsError(try Journey(id: "", title: "Journey", sessionIDs: [])) {
      XCTAssertEqual($0 as? NapDomainError, .invalidIdentity)
    }
    let catalog = try catalog(durations: [5])
    XCTAssertThrowsError(
      try NapPlanner.makePlan(
        id: "", request: request(duration: 10), startingAt: now,
        now: now, catalog: catalog)
    ) { XCTAssertEqual($0 as? NapDomainError, .invalidIdentity) }
  }

  func testInvalidSessionAndResumeDurationsAreRejected() throws {
    let valid = try session("s0", 5)
    for duration in [0, -1, TimeInterval.infinity, .nan] {
      XCTAssertThrowsError(try session("s0", duration)) {
        XCTAssertEqual($0 as? NapDomainError, .invalidDuration)
      }
      XCTAssertThrowsError(
        try ResumePoint(session: valid, utf16Offset: 1, estimatedRemainingDuration: duration)
      ) { XCTAssertEqual($0 as? NapDomainError, .invalidDuration) }
    }
    XCTAssertThrowsError(
      try ResumePoint(session: valid, utf16Offset: -1, estimatedRemainingDuration: 2)
    ) { XCTAssertEqual($0 as? NapDomainError, .invalidResumePoint) }
  }

  func testResumeUsesRemainingEstimateOnlyForItsMatchingFirstSession() throws {
    let first = try session("s0", 20)
    let next = try session("s1", 5)
    let resume = try ResumePoint(session: first, utf16Offset: 120, estimatedRemainingDuration: 3)
    let journey = try Journey(id: "j", title: "Journey", sessionIDs: [first.id, next.id])
    let catalog = try NapCatalog(journeys: [journey], sessions: [first, next])
    let startingAt = SessionSelection(journeyID: "j", sessionID: first.id, resumePoint: resume)

    let plan = try plan(NapRequest(window: .duration(8), startingAt: startingAt), catalog: catalog)

    XCTAssertEqual(plan.route.map(\.session.id), [first.id, next.id])
    XCTAssertEqual(plan.route.map(\.resumePoint), [resume, nil])
    XCTAssertEqual(plan.route.first?.session.estimatedDuration, 20)
    XCTAssertEqual(plan.segments.map(\.duration), [3, 5])
    XCTAssertEqual(plan.routeEndReason, .windowFilled)
  }

  func testResumeFromDifferentRevisionOrSessionIsRejected() throws {
    let original = try session("s0", 20)
    let resume = try ResumePoint(session: original, utf16Offset: 120, estimatedRemainingDuration: 3)
    for current in [try session("s0", 20, revision: "v2"), try session("other", 20)] {
      let journey = try Journey(id: "j", title: "Journey", sessionIDs: [current.id])
      let catalog = try NapCatalog(journeys: [journey], sessions: [current])
      let startingAt = SessionSelection(journeyID: "j", sessionID: current.id, resumePoint: resume)
      XCTAssertThrowsError(
        try plan(NapRequest(window: .duration(10), startingAt: startingAt), catalog: catalog)
      ) { XCTAssertEqual($0 as? NapDomainError, .invalidResumePoint) }
    }
  }

  func testPlanSnapshotsCatalogEstimatesAndRequestChoices() throws {
    var request = request(duration: 20)
    request.fallback = .ambience(id: "rain")
    var catalog = try catalog(durations: [10, 10])
    let original = try plan(request, catalog: catalog, availableAmbienceIDs: ["rain"])
    let snapshot = original

    request.settlingDuration = 4
    request.fallback = .silence
    request.alarmEnabled = true
    catalog = try self.catalog(durations: [8, 30])
    let replanned = try plan(request, catalog: catalog)

    XCTAssertEqual(original, snapshot)
    XCTAssertEqual(original.route.map(\.session.estimatedDuration), [10, 10])
    XCTAssertEqual(original.route.map(\.session.id), ["s0", "s1"])
    XCTAssertEqual(original.fallback, .ambience(id: "rain"))
    XCTAssertNil(original.wakeAlarm)
    XCTAssertEqual(replanned.route.map(\.session.id), ["s0"])
    XCTAssertEqual(replanned.route.first?.session.estimatedDuration, 8)
    XCTAssertEqual(replanned.wakeAlarm, original.deadline)
  }

  private func session(_ id: String, _ duration: TimeInterval, revision: String = "v1") throws
    -> Session
  {
    try Session(id: id, revision: revision, title: "Session \(id)", estimatedDuration: duration)
  }

  private func catalog(durations: [TimeInterval]) throws -> NapCatalog {
    let sessions = try durations.enumerated().map { try session("s\($0.offset)", $0.element) }
    let journey = try Journey(id: "j", title: "Journey", sessionIDs: sessions.map(\.id))
    return try NapCatalog(journeys: [journey], sessions: sessions)
  }

  private func selection(journeyID: String = "j", sessionID: String = "s0") -> SessionSelection {
    SessionSelection(journeyID: journeyID, sessionID: sessionID)
  }

  private func request(duration: TimeInterval) -> NapRequest {
    NapRequest(window: .duration(duration), startingAt: selection())
  }

  private func plan(
    _ request: NapRequest, catalog: NapCatalog, availableAmbienceIDs: Set<String> = []
  ) throws -> NapPlan {
    try NapPlanner.makePlan(
      id: "plan", request: request, startingAt: now, now: now,
      catalog: catalog, availableAmbienceIDs: availableAmbienceIDs)
  }

  private func assertContinuous(_ plan: NapPlan, file: StaticString = #filePath, line: UInt = #line)
  {
    XCTAssertEqual(plan.segments.first?.start, plan.start, file: file, line: line)
    XCTAssertEqual(plan.segments.last?.end, plan.deadline, file: file, line: line)
    for (first, next) in zip(plan.segments, plan.segments.dropFirst()) {
      XCTAssertEqual(first.end, next.start, file: file, line: line)
    }
    XCTAssertTrue(plan.segments.allSatisfy { $0.duration > 0 }, file: file, line: line)
  }
}
