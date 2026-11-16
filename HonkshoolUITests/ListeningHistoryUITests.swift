import XCTest

final class ListeningHistoryUITests: XCTestCase {
  override func setUpWithError() throws { continueAfterFailure = false }

  func testSavedCheckpointOpensFreshReviewAndSurvivesRelaunch() {
    let app = launch(reset: true, seed: true)
    openHistory(in: app)
    XCTAssertTrue(app.staticTexts["historyOutcome"].label.contains("Last verified checkpoint"))
    XCTAssertTrue(app.staticTexts["historyPlayedDuration"].label.contains("2m 0s"))
    XCTAssertTrue(app.staticTexts["historyJourneyProgress"].label.contains("0 of 2"))
    XCTAssertTrue(app.staticTexts["historyNextSession"].label.contains("Turning Fuel Into Motion"))
    XCTAssertTrue(app.buttons["historyContinue"].exists)
    let resume = app.buttons["historyResume"]
    scrollTo(resume, in: app)
    resume.tap()
    XCTAssertTrue(app.staticTexts["napPlanResumePosition"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["napPlanResumePosition"].label.contains("2m 0s"))
    XCTAssertFalse(app.buttons["startNapRun"].exists)
    let review = app.buttons["reviewNapPlan"]
    scrollTo(review, in: app)
    review.tap()
    XCTAssertTrue(app.staticTexts["napPlanReviewedResume"].exists)

    app.terminate()
    let reopened = launch(reset: false, seed: false)
    openHistory(in: reopened)
    XCTAssertTrue(reopened.staticTexts["historyOutcome"].waitForExistence(timeout: 5))
    XCTAssertTrue(reopened.buttons["historyResume"].exists)
  }

  func testStartOverClearsSavedPositionBeforeReview() {
    let app = launch(reset: true, seed: true)
    openHistory(in: app)
    let resume = app.buttons["historyResume"]
    scrollTo(resume, in: app)
    resume.tap()
    let startOver = app.buttons["napPlanStartOver"]
    scrollTo(startOver, in: app)
    startOver.tap()
    XCTAssertFalse(app.staticTexts["napPlanResumePosition"].exists)
    let review = app.buttons["reviewNapPlan"]
    scrollTo(review, in: app)
    review.tap()
    XCTAssertFalse(app.staticTexts["napPlanReviewedResume"].exists)
  }

  func testReturnFromHistoryRunUsesLatestCheckpointButOlderRecordRemainsSelectable() {
    let app = launch(reset: true, seed: true, realPlanClock: true)
    openHistory(in: app)
    let original = app.buttons["historyResume"].firstMatch
    scrollTo(original, in: app)
    original.tap()
    let originalPosition = app.staticTexts["napPlanResumePosition"]
    XCTAssertTrue(originalPosition.waitForExistence(timeout: 5))
    XCTAssertTrue(originalPosition.label.contains("2m 0s"))

    let alarm = app.switches["napPlanAlarm"]
    scrollTo(alarm, in: app)
    alarm.tap()
    let review = app.buttons["reviewNapPlan"]
    scrollTo(review, in: app)
    review.tap()
    let confirm = app.buttons["confirmNapPlan"]
    scrollTo(confirm, in: app)
    confirm.tap()
    app.buttons["startNapRun"].tap()
    XCTAssertTrue(app.buttons["pauseNapRun"].waitForExistence(timeout: 75))
    let advanced = expectation(description: "Narration advances beyond the seeded checkpoint")
    DispatchQueue.main.asyncAfter(deadline: .now() + 12) { advanced.fulfill() }
    wait(for: [advanced], timeout: 20)
    let stop = app.buttons["stopNapRun"]
    scrollTo(stop, in: app)
    stop.tap()
    let back = app.buttons["reviewAnotherNapPlan"]
    scrollTo(back, in: app)
    back.tap()

    XCTAssertTrue(app.tabBars.buttons["Rest"].isSelected)
    let currentPosition = app.staticTexts["napPlanResumePosition"]
    XCTAssertTrue(currentPosition.waitForExistence(timeout: 5))
    let currentOffset = checkpoint(in: currentPosition.label)
    XCTAssertNotNil(currentOffset)
    XCTAssertNotEqual(currentOffset, "2m 0s")
    XCTAssertFalse(app.buttons["startNapRun"].exists)
    XCTAssertFalse(app.staticTexts["napRunStatus"].exists)
    attachScreenshot("Rest offers newly saved position", in: app)
    scrollTo(review, in: app)
    review.tap()
    XCTAssertEqual(checkpoint(in: app.staticTexts["napPlanReviewedResume"].label), currentOffset)
    XCTAssertFalse(app.buttons["startNapRun"].exists)

    openHistory(in: app)
    let latest = app.buttons.matching(identifier: "historyResume").element(boundBy: 0)
    let older = app.buttons.matching(identifier: "historyResume").element(boundBy: 1)
    XCTAssertTrue(latest.waitForExistence(timeout: 5))
    XCTAssertTrue(older.exists)
    XCTAssertEqual(checkpoint(in: latest.label), currentOffset)
    XCTAssertTrue(older.label.contains("2m 0s"))
    scrollTo(older, in: app)
    older.tap()
    XCTAssertTrue(app.tabBars.buttons["History"].isSelected)
    XCTAssertTrue(app.staticTexts["napPlanResumePosition"].label.contains("2m 0s"))
    XCTAssertFalse(app.buttons["startNapRun"].exists)
  }

  func testReplayReturnKeepsScheduledAlarmSeparateFromRest() {
    let app = launch(reset: true, seed: true)
    openHistory(in: app)
    let replay = app.buttons["historyReplay"].firstMatch
    scrollTo(replay, in: app)
    replay.tap()
    XCTAssertFalse(app.staticTexts["napPlanResumePosition"].exists)
    let review = app.buttons["reviewNapPlan"]
    scrollTo(review, in: app)
    review.tap()
    let confirm = app.buttons["confirmNapPlan"]
    scrollTo(confirm, in: app)
    confirm.tap()
    app.buttons["startNapRun"].tap()
    XCTAssertTrue(app.buttons["stopNapRun"].waitForExistence(timeout: 5))
    app.buttons["stopNapRun"].tap()
    let back = app.buttons["reviewAnotherNapPlan"]
    scrollTo(back, in: app)
    back.tap()

    XCTAssertTrue(app.tabBars.buttons["Rest"].isSelected)
    XCTAssertTrue(app.buttons["cancelNapPlanAlarm"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["trackedNapPlanAlarmStatus"].exists)
    XCTAssertFalse(app.buttons["reviewNapPlan"].exists)
    XCTAssertFalse(app.buttons["startNapRun"].exists)
    attachScreenshot("Rest retains the separate alarm gate", in: app)
  }

  func testWaitingOnlyReturnPreservesAcknowledgedCheckpoint() {
    let app = launch(reset: true, seed: true)
    let acknowledge = app.buttons["acknowledgeRecoveredRest"]
    XCTAssertTrue(acknowledge.waitForExistence(timeout: 5))
    acknowledge.tap()
    openHistory(in: app)
    let resume = app.buttons["historyResume"].firstMatch
    scrollTo(resume, in: app)
    resume.tap()
    let alarm = app.switches["napPlanAlarm"]
    scrollTo(alarm, in: app)
    alarm.tap()
    let review = app.buttons["reviewNapPlan"]
    scrollTo(review, in: app)
    review.tap()
    let confirm = app.buttons["confirmNapPlan"]
    scrollTo(confirm, in: app)
    confirm.tap()
    app.buttons["startNapRun"].tap()
    let stop = app.buttons["stopNapRun"]
    XCTAssertTrue(stop.waitForExistence(timeout: 5))
    scrollTo(stop, in: app)
    stop.tap()
    let back = app.buttons["reviewAnotherNapPlan"]
    scrollTo(back, in: app)
    back.tap()
    XCTAssertTrue(app.tabBars.buttons["Rest"].isSelected)
    XCTAssertTrue(review.waitForExistence(timeout: 5))
    XCTAssertFalse(acknowledge.exists)
    XCTAssertTrue(app.staticTexts["napPlanResumePosition"].label.contains("2m 0s"))
    XCTAssertFalse(app.buttons["startNapRun"].exists)
    XCTAssertFalse(app.staticTexts["napRunStatus"].exists)
  }

  private func launch(reset: Bool, seed: Bool, realPlanClock: Bool = false) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing"]
    var environment = [
      "HONKSHOOL_UI_TEST_ALARM": "authorized",
      "HONKSHOOL_UI_TEST_AUDIO": "1",
      "HONKSHOOL_UI_TEST_RESET": reset ? "1" : "0",
      "HONKSHOOL_UI_TEST_SEED_HISTORY": seed ? "1" : "0",
    ]
    if !realPlanClock {
      environment["HONKSHOOL_UI_TEST_PLAN_NOW"] = String(
        Date.now.addingTimeInterval(24 * 60 * 60).timeIntervalSince1970)
    }
    app.launchEnvironment = environment
    app.launch()
    return app
  }

  private func openHistory(in app: XCUIApplication) {
    let open = app.tabBars.buttons["History"]
    XCTAssertTrue(open.waitForExistence(timeout: 5))
    open.tap()
    XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
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

  private func checkpoint(in label: String) -> String? {
    guard let range = label.range(of: "[0-9]+m [0-9]+s", options: .regularExpression) else {
      return nil
    }
    return String(label[range])
  }

  private func attachScreenshot(_ name: String, in app: XCUIApplication) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
