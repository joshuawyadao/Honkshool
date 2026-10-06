import XCTest

final class FunctionalPagesUITests: XCTestCase {
  override func setUpWithError() throws { continueAfterFailure = false }

  func testTimeAndSoundDraftsCancelWithoutChangingThePlan() {
    let app = launch()
    openNarratedPlan(in: app)
    XCTAssertTrue(app.switches["napPlanAlarm"].isHittable)
    XCTAssertLessThan(
      app.switches["napPlanAlarm"].frame.maxY, app.buttons["reviewNapPlan"].frame.minY)
    capture("Narrated rest choices")
    app.buttons["napPlanTimeOptions"].tap()
    app.buttons["napTimePreset-60"].tap()
    capture("Time to rest")
    app.buttons["cancelNapTime"].tap()
    tap("napPlanSound", in: app)
    app.buttons["Gentle rain"].tap()
    capture("After narration")
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
    openNarratedPlan(in: app)
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
    app.buttons["defaultRestPreset-30"].tap()
    tap("defaultRestSound", in: app)
    app.buttons["Gentle rain"].tap()
    let alarm = app.switches["defaultRestAlarm"]
    let nativeAlarm = alarm.switches.firstMatch.exists ? alarm.switches.firstMatch : alarm
    scrollTo(nativeAlarm, in: app)
    XCTAssertEqual(alarm.value as? String, "1")
    nativeAlarm.tap()
    XCTAssertEqual(alarm.value as? String, "0")
    capture("Rest defaults")
    tap("saveRestDefaults", in: app)
    app.terminate()
    app = launch(reset: false)
    let rain = app.buttons["timerRain"]
    scrollTo(rain, in: app)
    XCTAssertTrue(rain.isSelected, "Saved Rest sound also seeds the quick timer")
    openNarratedPlan(in: app)
    tap("reviewNapPlan", in: app)
    XCTAssertEqual(
      app.staticTexts["napPlanPostNarrationSound"].label, "After narration, Gentle rain")
    XCTAssertEqual(app.staticTexts["napPlanAlarmChoice"].label, "Wake alarm, Not requested")
    XCTAssertTrue(app.descendants(matching: .any)["napPlanRouteItem-1"].exists)
  }

  func testCustomRestDefaultWheelPersistsOneMinute() {
    var app = launch()
    tap("openSettings", in: app)
    tap("openRestDefaults", in: app)
    let minutes = app.pickers["defaultRestDurationMinutes"].pickerWheels.firstMatch
    scrollTo(minutes, in: app)
    minutes.adjust(toPickerWheelValue: "1")
    XCTAssertEqual(
      app.pickers["defaultRestDurationHours"].pickerWheels.firstMatch.value as? String, "0")
    XCTAssertEqual(minutes.value as? String, "1")
    tap("saveRestDefaults", in: app)
    app.terminate()

    app = launch(reset: false)
    tap("openSettings", in: app)
    tap("openRestDefaults", in: app)
    XCTAssertEqual(
      app.pickers["defaultRestDurationHours"].pickerWheels.firstMatch.value as? String, "0")
    XCTAssertEqual(
      app.pickers["defaultRestDurationMinutes"].pickerWheels.firstMatch.value as? String, "1")
  }

  func testSettingsSoundSummaryMatchesAvailablePlanDefault() {
    var app = launch()
    tap("openSettings", in: app)
    tap("openRestDefaults", in: app)
    tap("defaultRestSound", in: app)
    app.buttons["Gentle rain"].tap()
    tap("saveRestDefaults", in: app)
    XCTAssertEqual(app.staticTexts["settingsRestSound"].label, "Rest sound, Gentle rain")
    app.terminate()

    app = launch(reset: false, environment: ["HONKSHOOL_UI_TEST_PLAN_RAIN_UNAVAILABLE": "1"])
    tap("openSettings", in: app)
    XCTAssertEqual(app.staticTexts["settingsRestSound"].label, "Rest sound, Silence")
    app.navigationBars.buttons.firstMatch.tap()
    openNarratedPlan(in: app)
    tap("reviewNapPlan", in: app)
    XCTAssertEqual(app.staticTexts["napPlanPostNarrationSound"].label, "After narration, Silence")
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
    tap("recheckBundledAudio", in: app)
    let recheck = app.buttons["recheckBundledAudio"]
    let recheckFinished = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "isEnabled == true"), object: recheck)
    XCTAssertEqual(XCTWaiter.wait(for: [recheckFinished], timeout: 5), .completed)
    XCTAssertTrue(app.staticTexts["Turning Fuel Into Motion"].waitForExistence(timeout: 5))
    XCTAssertTrue(
      app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Ready offline")).count >= 2
    )
    app.navigationBars.buttons.firstMatch.tap()
    tap("openOfflineLibrary", in: app)
    XCTAssertTrue(app.staticTexts["Turning Fuel Into Motion"].waitForExistence(timeout: 5))
    app.navigationBars.buttons.firstMatch.tap()
    tap("openJourneyLibrary", in: app)
    capture("Journey library")
    XCTAssertEqual(
      app.buttons["viewJourney-how-a-car-works"].label, "View journey: How a Car Works")
    app.buttons["viewJourney-how-a-car-works"].tap()
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
    openNarratedPlan(in: app)
    tap("reviewNapPlan", in: app)
    tap("confirmNapPlan", in: app)
    XCTAssertTrue(app.buttons["startNapRun"].isHittable)
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
    XCTAssertTrue(app.buttons["startRestTimer"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["reviewNapPlan"].exists)
    openNarratedPlan(in: app)
    XCTAssertTrue(app.buttons["reviewNapPlan"].waitForExistence(timeout: 5))
  }

  func testLibraryAndVoicePreviewRespectAnActiveRest() {
    let app = launch()
    openNarratedPlan(in: app)
    tap("reviewNapPlan", in: app)
    tap("confirmNapPlan", in: app)
    tap("startNapRun", in: app)
    XCTAssertTrue(app.staticTexts["napRunStatus"].waitForExistence(timeout: 5))
    tap("openSettings", in: app)
    tap("openNarrationVoice", in: app)
    XCTAssertFalse(app.buttons["previewGeorge"].isEnabled)
    app.navigationBars.buttons.firstMatch.tap()
    tap("openJourneyLibrary", in: app)
    app.buttons["viewJourney-how-a-car-works"].tap()
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

  private func openNarratedPlan(in app: XCUIApplication) {
    tap("planNarratedRest", in: app)
    XCTAssertTrue(app.buttons["reviewNapPlan"].waitForExistence(timeout: 5))
  }

  private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
    func reachable() -> Bool {
      guard element.isHittable else { return false }
      let review = app.buttons["reviewNapPlan"]
      let timerStart = app.buttons["startRestTimer"]
      let footer = review.exists && review.isHittable ? review : timerStart
      return !footer.isHittable || element.identifier == footer.identifier
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
