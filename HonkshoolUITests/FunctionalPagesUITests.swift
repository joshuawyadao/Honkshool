import XCTest

final class FunctionalPagesUITests: XCTestCase {
  override func setUpWithError() throws { continueAfterFailure = false }

  func testTimeAndSoundDraftsCancelWithoutChangingThePlan() {
    let app = launch()
    app.buttons["napPlanTimeOptions"].tap()
    app.buttons["napPlanPreset-60"].tap()
    app.buttons["cancelNapTime"].tap()
    tap("napPlanSound", in: app)
    app.buttons["Gentle rain"].tap()
    app.buttons["cancelNapSound"].tap()
    tap("reviewNapPlan", in: app)
    XCTAssertEqual(app.staticTexts["napPlanPostNarrationSound"].label, "After narration, Silence")
    XCTAssertTrue(app.descendants(matching: .any)["napPlanRouteItem-0"].exists)
    XCTAssertFalse(app.descendants(matching: .any)["napPlanRouteItem-1"].exists)
    capture("Review — unchanged after cancelled choices")
  }

  func testSessionDetailCanChooseBeginningAndOpenActualNotes() {
    let app = launch(environment: ["HONKSHOOL_UI_TEST_SEED_HISTORY": "1"])
    XCTAssertTrue(app.buttons["acknowledgeRecoveredRest"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.staticTexts["napRunStatus"].exists)
    XCTAssertFalse(app.buttons["reviewNapPlan"].exists)
    capture("Recovered saved place")
    tap("acknowledgeRecoveredRest", in: app)
    app.tabBars.buttons["History"].tap()
    app.tabBars.buttons["Rest"].tap()
    XCTAssertFalse(app.buttons["acknowledgeRecoveredRest"].exists)
    tap("napPlanContent", in: app)
    capture("Choose a session")
    tap("sessionDetails-turning-fuel-into-motion", in: app)
    XCTAssertTrue(app.buttons["sessionUseSavedPlace"].exists)
    capture("Session detail")
    tap("openSessionNotes", in: app)
    XCTAssertTrue(app.navigationBars["Notes and sources"].waitForExistence(timeout: 5))
    capture("Notes and sources")
    app.navigationBars.buttons.firstMatch.tap()
    tap("sessionChooseBeginning", in: app)
    XCTAssertFalse(app.staticTexts["napPlanResumePosition"].exists)
    tap("reviewNapPlan", in: app)
    XCTAssertFalse(app.staticTexts["napPlanReviewedResume"].exists)
    XCTAssertFalse(app.staticTexts["napRunStatus"].exists)
  }

  func testSavedRestDefaultsSurviveRelaunchAndSeedAFreshPlan() {
    var app = launch()
    tap("openSettings", in: app)
    tap("openRestDefaults", in: app)
    app.buttons["30m"].tap()
    tap("defaultRestSound", in: app)
    app.buttons["Gentle rain"].tap()
    let alarm = app.switches["defaultRestAlarm"]
    scrollTo(alarm, in: app)
    alarm.tap()
    capture("Rest defaults")
    tap("saveRestDefaults", in: app)
    app.terminate()
    app = launch(reset: false)
    tap("reviewNapPlan", in: app)
    XCTAssertEqual(
      app.staticTexts["napPlanPostNarrationSound"].label, "After narration, Gentle rain")
    XCTAssertEqual(app.staticTexts["napPlanAlarmChoice"].label, "Wake alarm, Not requested")
    XCTAssertTrue(app.descendants(matching: .any)["napPlanRouteItem-1"].exists)
  }

  func testLibraryNavigatesIntoFreshPlanAndOfflineInventoryIsReal() {
    let app = launch()
    tap("openSettings", in: app)
    capture("Settings")
    tap("openOfflineLibrary", in: app)
    XCTAssertTrue(app.staticTexts["Turning Fuel Into Motion"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Air, Fuel, and Spark"].exists)
    XCTAssertTrue(
      app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Ready offline")).count >= 2
    )
    capture("Offline library")
    app.navigationBars.buttons.firstMatch.tap()
    tap("openJourneyLibrary", in: app)
    capture("Journey library")
    app.buttons["View journey"].tap()
    XCTAssertTrue(app.navigationBars["How a Car Works"].waitForExistence(timeout: 5))
    capture("Journey detail")
    let plan = app.buttons["Plan your next rest"]
    scrollTo(plan, in: app)
    plan.tap()
    XCTAssertTrue(app.buttons["reviewNapPlan"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["startNapRun"].exists)
    XCTAssertFalse(app.staticTexts["napRunStatus"].exists)
  }

  func testVoicePreviewIsExplicitAndStopsWhenLeavingThePage() {
    let app = launch()
    tap("openSettings", in: app)
    tap("openNarrationVoice", in: app)
    XCTAssertFalse(app.buttons["stopVoicePreview"].exists)
    capture("Narration voice")
    tap("previewGeorge", in: app)
    XCTAssertTrue(app.buttons["stopVoicePreview"].waitForExistence(timeout: 5))
    app.navigationBars.buttons.firstMatch.tap()
    tap("openNarrationVoice", in: app)
    XCTAssertTrue(app.buttons["previewGeorge"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["stopVoicePreview"].exists)
    XCTAssertFalse(app.staticTexts["napRunStatus"].exists)
  }

  func testFirstAlarmExplainsAccessBeforeScheduling() {
    let app = launch(environment: ["HONKSHOOL_UI_TEST_ALARM": "not-determined"])
    tap("reviewNapPlan", in: app)
    tap("confirmNapPlan", in: app)
    capture("Ready to start")
    tap("startNapRun", in: app)
    XCTAssertTrue(app.buttons["continueAlarmAccess"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.staticTexts["napRunStatus"].exists)
    capture("Alarm access")
    tap("continueAlarmAccess", in: app)
    XCTAssertTrue(app.staticTexts["napRunStatus"].waitForExistence(timeout: 5))
    capture("Getting comfortable")
    tap("stopNapRun", in: app)
    capture("Stopped with wake alarm")
    tap("reviewAnotherNapPlan", in: app)
    XCTAssertTrue(app.buttons["cancelNapPlanAlarm"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["reviewNapPlan"].exists)
    capture("Existing wake alarm")
    tap("cancelNapPlanAlarm", in: app)
    XCTAssertTrue(app.buttons["reviewNapPlan"].waitForExistence(timeout: 5))
  }

  func testLibraryAndVoicePreviewRespectAnActiveRest() {
    let app = launch()
    tap("reviewNapPlan", in: app)
    tap("confirmNapPlan", in: app)
    tap("startNapRun", in: app)
    XCTAssertTrue(app.staticTexts["napRunStatus"].waitForExistence(timeout: 5))
    tap("openSettings", in: app)
    tap("openNarrationVoice", in: app)
    XCTAssertFalse(app.buttons["previewGeorge"].isEnabled)
    app.navigationBars.buttons.firstMatch.tap()
    tap("openJourneyLibrary", in: app)
    app.buttons["View journey"].tap()
    XCTAssertFalse(app.buttons["Plan your next rest"].isEnabled)
    let details = app.buttons["About Turning Fuel Into Motion"]
    scrollTo(details, in: app)
    details.tap()
    XCTAssertTrue(app.buttons["sessionChooseBeginning"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["sessionChooseBeginning"].isEnabled)
    XCTAssertTrue(app.staticTexts["sessionPlanningBlocked"].exists)
  }

  private func launch(reset: Bool = true, environment: [String: String] = [:]) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing"]
    app.launchEnvironment = [
      "HONKSHOOL_UI_TEST_RESET": reset ? "1" : "0",
      "HONKSHOOL_UI_TEST_AUDIO": "1",
      "HONKSHOOL_UI_TEST_ALARM": "authorized",
      "HONKSHOOL_UI_TEST_PLAN_NOW": String(
        Date.now.addingTimeInterval(86400).timeIntervalSince1970),
    ]
    app.launchEnvironment.merge(environment) { _, new in new }
    app.launch()
    XCTAssertTrue(app.tabBars.buttons["Rest"].waitForExistence(timeout: 5))
    return app
  }

  private func tap(_ id: String, in app: XCUIApplication) {
    let button = app.buttons[id]
    scrollTo(button, in: app)
    button.tap()
  }

  private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
    func reachable() -> Bool {
      guard element.isHittable else { return false }
      let footer = app.buttons["reviewNapPlan"]
      return !footer.isHittable || element.identifier == "reviewNapPlan"
        || element.frame.maxY < footer.frame.minY
    }
    for _ in 0..<10 {
      if reachable() { return }
      app.swipeUp()
    }
    for _ in 0..<10 {
      if reachable() { return }
      app.swipeDown()
    }
    XCTAssertTrue(reachable())
  }

  private func capture(_ name: String) {
    let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
