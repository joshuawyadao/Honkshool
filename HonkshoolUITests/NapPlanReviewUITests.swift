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
    XCTAssertTrue(app.staticTexts["napPlanPlannedStart"].label.contains("Planned rest start"))
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
    XCTAssertTrue(confirmation.label.contains("approved route and fixed deadline"))
    XCTAssertTrue(app.buttons["startNapRun"].exists)
    XCTAssertTrue(app.staticTexts["napPlanConfirmedStart"].label.contains("Planned rest start"))
    XCTAssertFalse(app.buttons["reviewNapPlan"].exists)
    XCTAssertTrue(
      app.staticTexts["napPlanConfirmedDeadline"].label.contains(
        deadline.replacingOccurrences(of: "Fixed wake deadline, ", with: "")))
  }

  func testAlarmRequestedSchedulesBeforeRunAndSurvivesPlaybackStop() {
    let app = launchReview()
    let review = app.buttons["reviewNapPlan"]
    scrollTo(review, in: app)
    review.tap()
    let confirm = app.buttons["confirmNapPlan"]
    scrollTo(confirm, in: app)
    confirm.tap()

    let start = app.buttons["startNapRun"]
    scrollTo(start, in: app)
    start.tap()
    XCTAssertTrue(app.staticTexts["napRunStatus"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["napRunStatus"].label.contains("Keep Honkshool open"))
    app.navigationBars["Nap Plan"].buttons.element(boundBy: 0).tap()

    let alarmStatus = app.staticTexts["parentNapPlanAlarmStatus"]
    scrollTo(alarmStatus, in: app)
    XCTAssertTrue(alarmStatus.label.contains("scheduled"))
    XCTAssertFalse(app.buttons["parentCancelNapPlanAlarm"].exists)

    let stop = app.buttons["parentStopNapRun"]
    scrollTo(stop, in: app)
    stop.tap()
    XCTAssertTrue(
      app.staticTexts["activeNapRunStatus"].label.contains("wake alarm was not cancelled"))
    let cancel = app.buttons["parentCancelNapPlanAlarm"]
    scrollTo(cancel, in: app)
    cancel.tap()
    XCTAssertFalse(app.buttons["parentCancelNapPlanAlarm"].exists)
  }

  func testAlarmDenialBlocksRequestedRunWithoutAudio() {
    let app = launchReview(additionalEnvironment: [
      "HONKSHOOL_UI_TEST_ALARM": "denied"
    ])
    let review = app.buttons["reviewNapPlan"]
    scrollTo(review, in: app)
    review.tap()
    let confirm = app.buttons["confirmNapPlan"]
    scrollTo(confirm, in: app)
    confirm.tap()
    let start = app.buttons["startNapRun"]
    scrollTo(start, in: app)
    start.tap()
    XCTAssertTrue(app.staticTexts["napRunError"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.staticTexts["napRunStatus"].exists)
    XCTAssertFalse(app.buttons["cancelNapPlanAlarm"].exists)
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

    let confirm = app.buttons["confirmNapPlan"]
    scrollTo(confirm, in: app)
    confirm.tap()
    let start = app.buttons["startNapRun"]
    scrollTo(start, in: app)
    XCTAssertTrue(start.isEnabled)
    start.tap()
    XCTAssertTrue(app.staticTexts["napRunStatus"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["napRunStatus"].label.contains("Keep Honkshool open"))
    app.navigationBars["Nap Plan"].buttons.element(boundBy: 0).tap()
    let parentStatus = app.staticTexts["activeNapRunStatus"]
    scrollTo(parentStatus, in: app)
    XCTAssertTrue(parentStatus.label.contains("Keep Honkshool open"))
    let stop = app.buttons["parentStopNapRun"]
    scrollTo(stop, in: app)
    stop.tap()
    XCTAssertTrue(parentStatus.label.contains("Playback stopped"))
    XCTAssertFalse(app.buttons["parentStopNapRun"].exists)

    let reopen = app.buttons["openNapPlanReview"]
    scrollTo(reopen, in: app)
    reopen.tap()
    let anotherDuration = app.buttons["napPlanDuration"]
    scrollTo(anotherDuration, in: app)
    anotherDuration.tap()
    app.buttons["5 minutes"].tap()
    let anotherAlarm = app.switches["napPlanAlarm"]
    scrollTo(anotherAlarm, in: app)
    anotherAlarm.tap()
    let anotherReview = app.buttons["reviewNapPlan"]
    scrollTo(anotherReview, in: app)
    anotherReview.tap()
    let anotherConfirm = app.buttons["confirmNapPlan"]
    scrollTo(anotherConfirm, in: app)
    anotherConfirm.tap()
    XCTAssertTrue(app.buttons["startNapRun"].waitForExistence(timeout: 5))
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

  func testStaleDurationRefreshesDeadlineBeforeConfirmation() {
    let app = launchReview(additionalEnvironment: [
      "HONKSHOOL_UI_TEST_PLAN_CONFIRM_OFFSET": "180"
    ])
    let review = app.buttons["reviewNapPlan"]
    scrollTo(review, in: app)
    review.tap()
    let firstDeadline = app.staticTexts["napPlanDeadline"].label

    let confirm = app.buttons["confirmNapPlan"]
    scrollTo(confirm, in: app)
    confirm.tap()
    XCTAssertFalse(app.staticTexts["napPlanConfirmation"].exists)
    XCTAssertTrue(app.staticTexts["napPlanError"].label.contains("updated deadline"))
    let refreshedDeadline = app.staticTexts["napPlanDeadline"].label
    XCTAssertNotEqual(refreshedDeadline, firstDeadline)

    scrollTo(confirm, in: app)
    confirm.tap()
    XCTAssertTrue(app.staticTexts["napPlanConfirmation"].waitForExistence(timeout: 5))
    XCTAssertTrue(
      app.staticTexts["napPlanConfirmedDeadline"].label.contains(
        refreshedDeadline.replacingOccurrences(of: "Fixed wake deadline, ", with: "")))
  }

  func testExpiredExactWakeTimeCannotBeConfirmed() {
    let app = launchReview(additionalEnvironment: [
      "HONKSHOOL_UI_TEST_PLAN_CONFIRM_OFFSET": "1800"
    ])
    let exact = app.switches["napPlanUseExactWakeTime"]
    scrollTo(exact, in: app)
    exact.tap()
    let review = app.buttons["reviewNapPlan"]
    scrollTo(review, in: app)
    review.tap()
    let confirm = app.buttons["confirmNapPlan"]
    scrollTo(confirm, in: app)
    confirm.tap()
    XCTAssertFalse(app.staticTexts["napPlanConfirmation"].exists)
    XCTAssertTrue(
      app.staticTexts["napPlanError"].label.contains("Choose a wake time later"))
  }

  private func launchReview(additionalEnvironment: [String: String] = [:]) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing"]
    app.launchEnvironment = [
      "HONKSHOOL_UI_TEST_ALARM": "authorized",
      "HONKSHOOL_UI_TEST_AUDIO": "1",
      "HONKSHOOL_UI_TEST_RESET": "1",
      // The run controller uses wall time; keep each test's fixed review instant in the future.
      "HONKSHOOL_UI_TEST_PLAN_NOW": String(
        Date.now.addingTimeInterval(24 * 60 * 60).timeIntervalSince1970),
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
