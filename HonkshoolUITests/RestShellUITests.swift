import XCTest

final class RestShellUITests: XCTestCase {
  override func setUpWithError() throws { continueAfterFailure = false }

  func testFirstLaunchWelcomeIsShownOnce() {
    var app = launch(reset: true, showWelcome: true)
    let continueButton = app.buttons["dismissQuietWelcome"]
    XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
    continueButton.tap()
    XCTAssertTrue(app.tabBars.buttons["Rest"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["dismissQuietWelcome"].exists)

    app.terminate()
    app = launch(reset: false, showWelcome: true)
    XCTAssertTrue(app.tabBars.buttons["Rest"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["dismissQuietWelcome"].exists)
  }

  func testHistoryAndSettingsAreReachableFromRest() {
    let app = launch(reset: true)
    XCTAssertTrue(app.tabBars.buttons["Rest"].waitForExistence(timeout: 5))
    app.tabBars.buttons["History"].tap()
    XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
    app.tabBars.buttons["Rest"].tap()
    app.buttons["openSettings"].tap()
    XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    app.buttons["openFeasibilityLab"].tap()
    XCTAssertTrue(app.navigationBars["Feasibility Lab"].waitForExistence(timeout: 5))
  }

  func testLabPlaybackStateSurvivesTabChanges() {
    let app = launch(reset: true)
    app.buttons["openSettings"].tap()
    app.buttons["openFeasibilityLab"].tap()
    let start = app.buttons["startTest"]
    scrollTo(start, in: app)
    start.tap()
    XCTAssertTrue(app.staticTexts["playbackPhase"].label.contains("Narrating"))

    app.tabBars.buttons["History"].tap()
    XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
    app.tabBars.buttons["Rest"].tap()
    XCTAssertTrue(app.staticTexts["playbackPhase"].label.contains("Narrating"))
    let stop = app.buttons["stopPlayback"]
    scrollTo(stop, in: app)
    stop.tap()
  }

  func testLargeTextRestAndSessionDetailsRemainReachable() {
    let app = launch(
      reset: true,
      arguments: [
        "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL",
      ])
    let review = app.buttons["reviewNapPlan"]
    XCTAssertTrue(review.waitForExistence(timeout: 5))
    XCTAssertTrue(review.isHittable)
    attachScreen("Rest — accessibility text")
    let details = app.buttons["napPlanSessionDetail"]
    scrollTo(details, in: app)
    details.tap()
    XCTAssertTrue(app.buttons["dismissSessionDetail"].waitForExistence(timeout: 5))
    app.buttons["dismissSessionDetail"].tap()
    app.tabBars.buttons["History"].tap()
    XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
    attachScreen("History — accessibility text")
  }

  private func attachScreen(_ name: String) {
    let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  private func launch(reset: Bool, showWelcome: Bool = false, arguments: [String] = [])
    -> XCUIApplication
  {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing"] + arguments
    app.launchEnvironment = [
      "HONKSHOOL_UI_TEST_ALARM": "authorized",
      "HONKSHOOL_UI_TEST_AUDIO": "1",
      "HONKSHOOL_UI_TEST_RESET": reset ? "1" : "0",
      "HONKSHOOL_UI_TEST_SHOW_WELCOME": showWelcome ? "1" : "0",
    ]
    app.launch()
    return app
  }

  private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
    for _ in 0..<12 {
      if element.isHittable { return }
      app.swipeUp()
    }
    XCTAssertTrue(element.isHittable)
  }
}
