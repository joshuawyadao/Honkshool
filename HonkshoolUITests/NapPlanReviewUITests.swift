import XCTest

final class NapPlanReviewUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testDurationReviewShowsCompleteRouteFallbackAndHonestConfirmation() {
    let app = launchReview()
    let review = app.buttons["reviewNapPlan"]
    scrollTo(review, in: app)
    review.tap()

    let route = app.descendants(matching: .any)["napPlanRouteItem-0"]
    scrollTo(route, in: app)
    XCTAssertTrue(route.label.contains("Turning Fuel Into Motion"))
    XCTAssertFalse(app.descendants(matching: .any)["napPlanRouteItem-1"].exists)
    XCTAssertTrue(app.staticTexts["napPlanDeadline"].label.contains("Fixed wake deadline"))
    XCTAssertEqual(app.staticTexts["napPlanAlarmChoice"].label, "Wake alarm, Requested at deadline")
    XCTAssertEqual(app.staticTexts["napPlanPostNarrationSound"].label, "After narration, Silence")
    XCTAssertTrue(app.staticTexts["napPlanRouteEnd"].label.contains("journey route ends"))

    let deadline = app.staticTexts["napPlanDeadline"].label
    let confirm = app.buttons["confirmNapPlan"]
    scrollTo(confirm, in: app)
    confirm.tap()
    let confirmation = app.staticTexts["napPlanConfirmation"]
    XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
    XCTAssertTrue(confirmation.label.contains("Playback has not started"))
    XCTAssertTrue(confirmation.label.contains("no wake alarm has been scheduled"))
    XCTAssertFalse(app.buttons["reviewNapPlan"].exists)
    XCTAssertTrue(
      app.staticTexts["napPlanConfirmedDeadline"].label.contains(
        deadline.replacingOccurrences(of: "Fixed wake deadline, ", with: "")))
  }

  func testShortWindowReviewsSilenceOnlyAndNoAlarm() {
    let app = launchReview()
    let duration = app.buttons["napPlanDuration"]
    scrollTo(duration, in: app)
    duration.tap()
    app.buttons["5 minutes"].tap()
    let alarm = app.switches["napPlanAlarm"]
    scrollTo(alarm, in: app)
    alarm.tap()
    let review = app.buttons["reviewNapPlan"]
    scrollTo(review, in: app)
    review.tap()

    XCTAssertTrue(app.staticTexts["napPlanNoContent"].exists)
    XCTAssertEqual(app.staticTexts["napPlanAlarmChoice"].label, "Wake alarm, Not requested")
    XCTAssertEqual(app.staticTexts["napPlanPostNarrationSound"].label, "After narration, Silence")
    XCTAssertTrue(app.staticTexts["napPlanRouteEnd"].label.contains("does not fit"))
  }

  func testExactWakeTimeAndAccessibilityLabelsAreAvailable() {
    let app = launchReview()
    let exact = app.switches["napPlanUseExactWakeTime"]
    scrollTo(exact, in: app)
    exact.tap()
    XCTAssertTrue(app.datePickers["napPlanExactWakeTime"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["napPlanDuration"].exists)
    XCTAssertTrue(app.datePickers["napPlanExactWakeTime"].label.contains("Wake time"))
    let review = app.buttons["reviewNapPlan"]
    scrollTo(review, in: app)
    review.tap()
    XCTAssertTrue(app.staticTexts["napPlanDeadline"].exists)
    XCTAssertTrue(app.staticTexts["napPlanAlarmChoice"].exists)
    XCTAssertTrue(app.buttons["confirmNapPlan"].isEnabled)
  }

  func testUnavailableNarrationIsNotOfferedForReview() {
    let app = launchReview(additionalEnvironment: [
      "HONKSHOOL_UI_TEST_PLAN_CONTENT_UNAVAILABLE": "1"
    ])
    XCTAssertTrue(
      app.staticTexts["No prepared sessions are available for planning."]
        .waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["napPlanContent"].exists)
    let review = app.buttons["reviewNapPlan"]
    scrollTo(review, in: app)
    XCTAssertFalse(review.isEnabled)
  }

  private func launchReview(additionalEnvironment: [String: String] = [:]) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing"]
    app.launchEnvironment = [
      "HONKSHOOL_UI_TEST_ALARM": "authorized",
      "HONKSHOOL_UI_TEST_AUDIO": "1",
      "HONKSHOOL_UI_TEST_RESET": "1",
      "HONKSHOOL_UI_TEST_PLAN_NOW": "1800000000",
    ]
    app.launchEnvironment.merge(additionalEnvironment) { _, new in new }
    app.launch()
    let open = app.buttons["openNapPlanReview"]
    XCTAssertTrue(open.waitForExistence(timeout: 5))
    scrollTo(open, in: app)
    open.tap()
    XCTAssertTrue(app.navigationBars["Nap Plan"].waitForExistence(timeout: 5))
    return app
  }

  private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
    for _ in 0..<12 {
      if element.isHittable { return }
      app.swipeUp()
    }
    for _ in 0..<12 {
      if element.isHittable { return }
      app.swipeDown()
    }
    XCTAssertTrue(element.isHittable)
  }
}
