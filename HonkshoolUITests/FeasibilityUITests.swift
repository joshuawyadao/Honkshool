import XCTest

final class FeasibilityUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testBlockedStartPresentsAnExplanation() {
    let app = XCUIApplication()
    app.launch()
    let start = app.buttons["startTest"]
    scrollTo(start, in: app)
    start.tap()
    let explanation = app.alerts["Test cannot start"]
    XCTAssertTrue(explanation.waitForExistence(timeout: 5))
    XCTAssertTrue(
      explanation.staticTexts.containing(
        NSPredicate(
          format: "label CONTAINS[c] 'authorization'"
        )
      ).firstMatch.exists)
    explanation.buttons["OK"].tap()
  }

  func testCanReturnToTopDuringPlaybackAndAfterOpeningDiagnostics() {
    let app = XCUIApplication()
    app.launch()
    let requireAlarm = app.switches["requireAlarm"]
    scrollTo(requireAlarm, in: app)
    if requireAlarm.value as? String == "1" { requireAlarm.tap() }
    let start = app.buttons["startTest"]
    scrollTo(start, in: app)
    start.tap()

    let playing = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label == %@", "Phase, Narrating"),
      object: app.staticTexts["playbackPhase"]
    )
    XCTAssertEqual(XCTWaiter.wait(for: [playing], timeout: 5), .completed)

    let log = app.buttons["audioEventLog"]
    scrollTo(log, in: app)
    log.tap()
    XCTAssertTrue(app.navigationBars["Audio event log"].waitForExistence(timeout: 5))
    app.navigationBars.buttons.firstMatch.tap()

    for _ in 0..<3 {
      for _ in 0..<6 { app.swipeDown() }
      XCTAssertTrue(app.staticTexts["Test session"].isHittable)
      for _ in 0..<5 { app.swipeUp() }
    }
    let stop = app.buttons["Stop"]
    scrollTo(stop, in: app)
    stop.tap()
    let stopped = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label == %@", "Phase, Stopped"),
      object: app.staticTexts["playbackPhase"]
    )
    XCTAssertEqual(XCTWaiter.wait(for: [stopped], timeout: 5), .completed)
  }

  private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
    for _ in 0..<8 {
      if element.isHittable { return }
      app.swipeUp()
    }
    for _ in 0..<8 {
      if element.isHittable { return }
      app.swipeDown()
    }
    XCTAssertTrue(element.isHittable)
  }
}
