import XCTest

@testable import Honkshool

final class NapPlanReviewTests: XCTestCase {
  private let now = Date(timeIntervalSince1970: 1_800_000_000)

  func testDurationAndExactWakeTimeUseInjectedStartAndFixedDeadline() throws {
    let catalog = try makeCatalog()
    var state = NapPlanReviewState()
    var request = NapRequest(window: .duration(1_000), startingAt: selection("first"))
    request.alarmEnabled = true

    try state.review(
      id: "duration", request: request, startingAt: now, now: now, catalog: catalog)
    XCTAssertEqual(state.reviewed?.plan.deadline, now.addingTimeInterval(1_000))
    XCTAssertEqual(state.reviewed?.plan.wakeAlarm, now.addingTimeInterval(1_000))
    XCTAssertEqual(state.reviewed?.route.map(\.planned.session.id), ["first", "second"])

    let laterStart = now.addingTimeInterval(30)
    let wake = now.addingTimeInterval(1_500)
    request = NapRequest(window: .wakeTime(wake), startingAt: selection("first"))
    try state.review(
      id: "wake", request: request, startingAt: laterStart, now: now, catalog: catalog)
    XCTAssertEqual(state.reviewed?.plan.start, laterStart)
    XCTAssertEqual(state.reviewed?.plan.deadline, wake)
    XCTAssertNil(state.reviewed?.plan.wakeAlarm)
    XCTAssertEqual(state.reviewed?.selectedWindow, .wakeTime(wake))
  }

  func testInvalidAndPastDeadlineCannotLeaveStaleReview() throws {
    let catalog = try makeCatalog()
    var state = NapPlanReviewState()
    try state.review(
      id: "valid", request: NapRequest(window: .duration(1_000), startingAt: selection("first")),
      startingAt: now, now: now, catalog: catalog)

    for window in [
      NapWindow.duration(0), .duration(-1), .duration(.infinity),
      .wakeTime(now), .wakeTime(now.addingTimeInterval(-1)),
    ] {
      XCTAssertThrowsError(
        try state.review(
          id: "invalid", request: NapRequest(window: window, startingAt: selection("first")),
          startingAt: now, now: now, catalog: catalog))
      XCTAssertNil(state.reviewed)
    }
    XCTAssertThrowsError(
      try state.review(
        id: "past-start",
        request: NapRequest(window: .duration(1_000), startingAt: selection("first")),
        startingAt: now.addingTimeInterval(-1), now: now, catalog: catalog))
    XCTAssertNil(state.reviewed)
  }

  func testShortWindowUsesApprovedShorterSessionOrSoundOnly() throws {
    let catalog = try makeCatalog()
    var state = NapPlanReviewState()
    var request = NapRequest(window: .duration(300), startingAt: selection("first"))
    request.shorterAlternatives = [selection("short")]
    request.fallback = .ambience(id: "approved-rain")

    try state.review(
      id: "short", request: request, startingAt: now, now: now, catalog: catalog,
      availableAmbienceIDs: ["approved-rain"])
    XCTAssertEqual(state.reviewed?.route.map(\.planned.session.id), ["short"])
    XCTAssertEqual(state.reviewed?.plan.usedShorterAlternative, true)
    XCTAssertEqual(state.reviewed?.plan.fallback, .ambience(id: "approved-rain"))
    XCTAssertEqual(state.reviewed?.plan.segments.last?.kind, .rest(.ambience(id: "approved-rain")))

    request.shorterAlternatives = []
    try state.review(
      id: "sound-only", request: request, startingAt: now, now: now, catalog: catalog)
    XCTAssertTrue(try XCTUnwrap(state.reviewed).route.isEmpty)
    XCTAssertEqual(state.reviewed?.plan.routeEndReason, .nextSessionDoesNotFit)
    XCTAssertEqual(state.reviewed?.requestedSound, .ambience(id: "approved-rain"))
    XCTAssertEqual(state.reviewed?.plan.fallback, .silence)
    XCTAssertEqual(state.reviewed?.plan.segments.map(\.kind), [.rest(.silence)])
  }

  func testPreapprovedTransitionAndMissingNextContentAppearInFixedReview() throws {
    let catalog = try makeCatalog()
    var state = NapPlanReviewState()
    var request = NapRequest(window: .duration(2_000), startingAt: selection("first"))
    let transition = JourneyTransition(from: "cars", to: "rally")
    request.approvedTransitions = [transition]

    try state.review(
      id: "branch", request: request, startingAt: now, now: now, catalog: catalog)
    XCTAssertEqual(
      state.reviewed?.route.map(\.planned.session.id), ["first", "second", "short", "rally-one"])
    XCTAssertEqual(
      state.reviewed?.route.map(\.journeyTitle),
      ["How a Car Works", "How a Car Works", "How a Car Works", "Rally Engineering"])
    XCTAssertEqual(state.reviewed?.plan.transitions, [transition])
    XCTAssertEqual(state.reviewed?.approvedTransitions, [transition])
    XCTAssertEqual(state.reviewed?.plan.routeEndReason, .contentUnavailable)
    XCTAssertEqual(state.reviewed?.plan.segments.last?.kind, .rest(.silence))
  }

  func testConfirmationRetainsExactReviewedRouteWhenInputsChange() throws {
    let catalog = try makeCatalog()
    var state = NapPlanReviewState()
    var request = NapRequest(window: .duration(2_000), startingAt: selection("first"))
    request.approvedTransitions = [JourneyTransition(from: "cars", to: "rally")]
    request.alarmEnabled = true

    try state.review(
      id: "fixed", request: request, startingAt: now, now: now, catalog: catalog)
    let reviewed = try XCTUnwrap(state.reviewed)
    state.confirm()
    request = NapRequest(window: .duration(30), startingAt: selection("short"))
    XCTAssertThrowsError(
      try state.review(
        id: "changed", request: request, startingAt: now.addingTimeInterval(10),
        now: now.addingTimeInterval(10), catalog: catalog)
    ) {
      XCTAssertEqual($0 as? NapPlanReviewError, .alreadyConfirmed)
    }
    state.clearReview()

    XCTAssertEqual(state.confirmed, reviewed)
    XCTAssertEqual(state.confirmed?.plan.id, "fixed")
    XCTAssertEqual(state.confirmed?.plan.deadline, now.addingTimeInterval(2_000))
    XCTAssertEqual(state.confirmed?.plan.wakeAlarm, state.confirmed?.plan.deadline)
    XCTAssertEqual(state.confirmed?.plan.transitions, reviewed.plan.transitions)
    XCTAssertEqual(state.confirmed?.approvedTransitions, reviewed.approvedTransitions)
    XCTAssertEqual(state.confirmed?.route, reviewed.route)
  }

  private func selection(_ id: String) -> SessionSelection {
    SessionSelection(journeyID: id == "rally-one" ? "rally" : "cars", sessionID: id)
  }

  private func makeCatalog() throws -> NapCatalog {
    let cars = try Journey(
      id: "cars", title: "How a Car Works", sessionIDs: ["first", "second", "short"],
      nextJourneyIDs: ["rally"])
    let rally = try Journey(
      id: "rally", title: "Rally Engineering", sessionIDs: ["rally-one", "missing"])
    let durations: [(String, TimeInterval)] = [
      ("first", 600), ("second", 400), ("short", 180), ("rally-one", 300),
    ]
    return try NapCatalog(
      journeys: [cars, rally],
      sessions: durations.map {
        try Session(id: $0.0, revision: "1", title: $0.0, estimatedDuration: $0.1)
      })
  }
}
