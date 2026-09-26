import XCTest

final class ListeningHistoryUITests: XCTestCase {
  override func setUpWithError() throws { continueAfterFailure = false }

  func testSavedCheckpointOpensFreshReviewAndSurvivesRelaunch() {
    let app = launch(reset: true, seed: true)
    openHistory(in: app)
    XCTAssertTrue(app.staticTexts["historyOutcome"].label.contains("Last verified checkpoint"))
    XCTAssertTrue(app.staticTexts["historyPlayedDuration"].label.contains("2m 0s"))
    XCTAssertTrue(app.staticTexts["historyJourneyProgress"].label.contains("0 of 1"))
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

  private func launch(reset: Bool, seed: Bool) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing"]
    app.launchEnvironment = [
      "HONKSHOOL_UI_TEST_ALARM": "authorized",
      "HONKSHOOL_UI_TEST_AUDIO": "1",
      "HONKSHOOL_UI_TEST_RESET": reset ? "1" : "0",
      "HONKSHOOL_UI_TEST_SEED_HISTORY": seed ? "1" : "0",
      "HONKSHOOL_UI_TEST_PLAN_NOW": String(
        Date.now.addingTimeInterval(24 * 60 * 60).timeIntervalSince1970),
    ]
    app.launch()
    return app
  }

  private func openHistory(in app: XCUIApplication) {
    let open = app.buttons["openListeningHistory"]
    XCTAssertTrue(open.waitForExistence(timeout: 5))
    scrollTo(open, in: app)
    open.tap()
    XCTAssertTrue(app.navigationBars["Listening History"].waitForExistence(timeout: 5))
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
