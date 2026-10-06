import XCTest

final class RestShellUITests: XCTestCase {
  override func setUpWithError() throws { continueAfterFailure = false }

  func testFirstLaunchWelcomeIsShownOnce() {
    var app = launch(reset: true, showWelcome: true)
    let continueButton = app.buttons["dismissQuietWelcome"]
    XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
    attachScreen("Welcome")
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
    attachScreen("Rest")
    app.tabBars.buttons["History"].tap()
    XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
    app.tabBars.buttons["Rest"].tap()
    app.buttons["openSettings"].tap()
    XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    attachScreen("Settings")
    scrollTo(app.buttons["openFeasibilityLab"], in: app)
    app.buttons["openFeasibilityLab"].tap()
    XCTAssertTrue(app.navigationBars["Feasibility Lab"].waitForExistence(timeout: 5))
  }

  func testLabPlaybackStateSurvivesTabChanges() {
    let app = launch(reset: true)
    app.buttons["openSettings"].tap()
    scrollTo(app.buttons["openFeasibilityLab"], in: app)
    app.buttons["openFeasibilityLab"].tap()
    let start = app.buttons["startTest"]
    scrollTo(start, in: app)
    attachScreen("Feasibility Lab")
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
    scrollTo(app.buttons["planNarratedRest"], in: app)
    app.buttons["planNarratedRest"].tap()
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
    app.tabBars.buttons["Rest"].tap()
    app.buttons["openSettings"].tap()
    scrollTo(app.buttons["openRestDefaults"], in: app)
    app.buttons["openRestDefaults"].tap()
    XCTAssertTrue(app.buttons["defaultRestPreset-60"].waitForExistence(timeout: 5))
    scrollTo(app.buttons["defaultRestPreset-60"], in: app)
    XCTAssertTrue(app.buttons["defaultRestPreset-60"].isHittable)
    attachScreen("Rest defaults — accessibility text")
    scrollTo(app.buttons["saveRestDefaults"], in: app)
    app.buttons["saveRestDefaults"].tap()
    app.navigationBars.buttons.firstMatch.tap()
    app.buttons["reviewNapPlan"].tap()
    scrollTo(app.buttons["confirmNapPlan"], in: app)
    app.buttons["confirmNapPlan"].tap()
    XCTAssertTrue(app.buttons["startNapRun"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["startNapRun"].isHittable)
    attachScreen("Ready — accessibility text")
  }

  func testTimerStartsRainDirectlyAndKeepsVerifiedAlarmAfterStop() {
    let app = launch(reset: true)
    let start = app.buttons["startRestTimer"]
    XCTAssertTrue(start.waitForExistence(timeout: 5))
    XCTAssertTrue(start.isHittable)
    XCTAssertFalse(app.buttons["reviewNapPlan"].exists)
    app.buttons["timerPreset-30"].tap()
    scrollTo(app.buttons["timerRain"], in: app)
    app.buttons["timerRain"].tap()
    XCTAssertTrue(app.buttons["timerRain"].isSelected)
    attachScreen("Quick timer — ready")
    start.tap()
    let status = app.staticTexts["napRunStatus"]
    XCTAssertTrue(status.waitForExistence(timeout: 5))
    XCTAssertTrue(status.label.contains("Gentle rain is playing"), status.label)
    attachCountdownDebug("Quick timer after admission", app: app)
    XCTAssertTrue(app.staticTexts["restTimerRunning"].exists)
    let remaining = app.staticTexts["restTimeRemaining"]
    XCTAssertTrue(remaining.exists)
    XCTAssertTrue(remaining.label.contains(":"), remaining.label)
    XCTAssertFalse(app.buttons["confirmNapPlan"].exists)
    XCTAssertFalse(app.staticTexts["napPlanConfirmedStart"].exists)
    let deadline = app.staticTexts["napPlanConfirmedDeadline"].label
    scrollTo(app.staticTexts["napPlanAlarmStatus"], in: app)
    XCTAssertTrue(app.staticTexts["napPlanAlarmStatus"].label.contains("scheduled"))
    attachScreen("Quick timer — rain playing")
    app.tabBars.buttons["History"].tap()
    XCTAssertFalse(app.buttons["historyResume"].exists)
    app.tabBars.buttons["Rest"].tap()
    XCTAssertEqual(app.staticTexts["napPlanConfirmedDeadline"].label, deadline)
    XCTAssertTrue(app.staticTexts["restTimeRemaining"].exists)
    scrollTo(app.buttons["pauseNapRun"], in: app)
    app.buttons["pauseNapRun"].tap()
    XCTAssertTrue(app.staticTexts["restTimerRunning"].exists)
    XCTAssertTrue(
      app.staticTexts["restTimerPlaybackNote"].label.contains("Rest time continues"))
    XCTAssertEqual(app.staticTexts["napPlanConfirmedDeadline"].label, deadline)
    scrollTo(app.buttons["stopNapRun"], in: app)
    XCTAssertEqual(app.buttons["stopNapRun"].label, "Stop rest")
    XCTAssertTrue(app.staticTexts["Stopping rest does not cancel the wake alarm."].exists)
    app.buttons["stopNapRun"].tap()
    XCTAssertFalse(app.staticTexts["restTimerRunning"].exists)
    XCTAssertFalse(app.staticTexts["restTimeRemaining"].exists)
    scrollTo(app.buttons["cancelNapPlanAlarm"], in: app)
    XCTAssertTrue(app.buttons["cancelNapPlanAlarm"].isEnabled)
    app.buttons["cancelNapPlanAlarm"].tap()
    scrollTo(app.buttons["reviewAnotherNapPlan"], in: app)
    app.buttons["reviewAnotherNapPlan"].tap()
    XCTAssertTrue(start.waitForExistence(timeout: 5))
  }

  func testOneMinuteTimerShowsLiveRemainingTimeAfterAdmission() {
    let app = launch(reset: true)
    let more = app.buttons["timerMoreOptions"]
    scrollTo(more, in: app)
    more.tap()
    let minutes = app.pickers["timerCustomDurationMinutes"].pickerWheels.firstMatch
    scrollTo(minutes, in: app)
    minutes.adjust(toPickerWheelValue: "1")
    XCTAssertEqual(minutes.value as? String, "1")
    scrollTo(app.switches["timerWakeAlarm"], in: app)
    app.switches["timerWakeAlarm"].tap()
    XCTAssertFalse(app.staticTexts["restTimerRunning"].exists)
    app.buttons["startRestTimer"].tap()
    XCTAssertTrue(app.staticTexts["napRunStatus"].waitForExistence(timeout: 5))
    attachCountdownDebug("One-minute timer after admission", app: app)
    XCTAssertTrue(app.staticTexts["restTimerRunning"].waitForExistence(timeout: 5))
    let remaining = app.staticTexts["restTimeRemaining"]
    XCTAssertTrue(remaining.exists)
    XCTAssertTrue(remaining.label.contains(":"), remaining.label)
    let initialRemaining = remaining.label
    let ticking = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label != %@", initialRemaining), object: remaining)
    XCTAssertEqual(XCTWaiter.wait(for: [ticking], timeout: 4), .completed)
    XCTAssertTrue(app.staticTexts["napPlanConfirmedDeadline"].exists)
    XCTAssertTrue(app.staticTexts["napPlanAlarmStatus"].label.contains("No wake alarm"))
    attachScreen("One-minute rest countdown")
    scrollTo(app.buttons["stopNapRun"], in: app)
    XCTAssertEqual(app.buttons["stopNapRun"].label, "Stop rest")
    app.buttons["stopNapRun"].tap()
    XCTAssertFalse(remaining.exists)
  }

  func testTimerAlarmDenialKeepsChoicesAndDoesNotStartPlayback() {
    let app = launch(reset: true, alarm: "denied")
    let start = app.buttons["startRestTimer"]
    XCTAssertTrue(start.waitForExistence(timeout: 5))
    start.tap()
    let error = app.staticTexts["timerStartError"]
    XCTAssertTrue(error.waitForExistence(timeout: 5))
    XCTAssertTrue(error.label.contains("Playback hasn’t started"))
    XCTAssertFalse(app.staticTexts["restTimerRunning"].exists)
    XCTAssertFalse(app.staticTexts["restTimeRemaining"].exists)
    XCTAssertFalse(app.buttons["stopNapRun"].exists)
    XCTAssertTrue(app.buttons["openAlarmSettings"].exists)
    scrollTo(app.switches["timerWakeAlarm"], in: app)
    app.switches["timerWakeAlarm"].tap()
    start.tap()
    XCTAssertTrue(app.staticTexts["napRunStatus"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["napRunStatus"].label.contains("silence"))
    scrollTo(app.buttons["stopNapRun"], in: app)
    app.buttons["stopNapRun"].tap()
  }

  func testTimerScheduleFailureRetainsCancellationWithoutClaimingAlarmIsSet() {
    let app = launch(reset: true, alarm: "schedule-failure")
    XCTAssertTrue(app.buttons["startRestTimer"].waitForExistence(timeout: 5))
    app.buttons["startRestTimer"].tap()
    XCTAssertTrue(app.staticTexts["timerStartError"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["timerStartError"].label.contains("Playback hasn’t started"))
    XCTAssertTrue(app.staticTexts["Check your\nwake alarm."].exists)
    XCTAssertFalse(app.buttons["stopNapRun"].exists)
    scrollTo(app.buttons["cancelNapPlanAlarm"], in: app)
    app.buttons["cancelNapPlanAlarm"].tap()
    XCTAssertTrue(app.buttons["startRestTimer"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.staticTexts["timerStartError"].exists)
  }

  func testLeavingTimerDuringPermissionDoesNotStartOnReturn() {
    let app = launch(reset: true, alarm: "delayed-authorization")
    XCTAssertTrue(app.buttons["startRestTimer"].waitForExistence(timeout: 5))
    app.buttons["startRestTimer"].tap()
    XCTAssertTrue(app.staticTexts["timerPreparing"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["startRestTimer"].isEnabled)
    app.tabBars.buttons["History"].tap()
    XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
    app.tabBars.buttons["Rest"].tap()
    let error = app.staticTexts["timerStartError"]
    XCTAssertTrue(error.waitForExistence(timeout: 15))
    XCTAssertTrue(error.label.contains("Rest hasn’t started"))
    XCTAssertFalse(app.buttons["stopNapRun"].exists)
    XCTAssertFalse(app.buttons["cancelNapPlanAlarm"].exists)
    XCTAssertTrue(app.buttons["startRestTimer"].isEnabled)
  }

  func testTimerCustomAndExactTimingStayOnRestScreen() {
    let app = launch(reset: true)
    XCTAssertTrue(app.buttons["startRestTimer"].waitForExistence(timeout: 5))
    let more = app.buttons["timerMoreOptions"]
    scrollTo(more, in: app)
    more.tap()
    let minutes = app.pickers["timerCustomDurationMinutes"].pickerWheels.firstMatch
    scrollTo(minutes, in: app)
    minutes.adjust(toPickerWheelValue: "19")
    XCTAssertEqual(minutes.value as? String, "19")
    attachScreen("Custom timer wheels")
    let hours = app.pickers["timerCustomDurationHours"].pickerWheels.firstMatch
    hours.adjust(toPickerWheelValue: "3")
    XCTAssertEqual(hours.value as? String, "3")
    XCTAssertEqual(minutes.value as? String, "0")
    hours.adjust(toPickerWheelValue: "0")
    XCTAssertEqual(minutes.value as? String, "1")
    scrollTo(app.switches["timerExactTime"], in: app)
    app.switches["timerExactTime"].tap()
    XCTAssertTrue(app.datePickers["timerWakeTime"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.navigationBars["Honkshool"].exists)
    XCTAssertTrue(app.buttons["startRestTimer"].isHittable)
    XCTAssertFalse(app.buttons["confirmNapPlan"].exists)
  }

  func testLargestTextQuickTimerKeepsChoicesAndStartReachable() {
    let app = launch(
      reset: true,
      arguments: [
        "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
      ])
    let start = app.buttons["startRestTimer"]
    XCTAssertTrue(start.waitForExistence(timeout: 5))
    XCTAssertTrue(start.isHittable)
    scrollTo(app.buttons["timerPreset-60"], in: app)
    app.buttons["timerPreset-60"].tap()
    XCTAssertTrue(app.buttons["timerPreset-60"].isSelected)
    attachScreen("AX5 quick timer duration")
    scrollTo(app.buttons["timerRain"], in: app)
    app.buttons["timerRain"].tap()
    XCTAssertTrue(app.buttons["timerRain"].isSelected)
    let alarm = app.switches["timerWakeAlarm"]
    // At accessibility sizes iOS can place the native switch below its label.
    let nativeAlarm = alarm.switches.firstMatch.exists ? alarm.switches.firstMatch : alarm
    scrollTo(nativeAlarm, in: app)
    XCTAssertEqual(alarm.value as? String, "1")
    nativeAlarm.tap()
    XCTAssertEqual(alarm.value as? String, "0")
    attachScreen("AX5 quick timer sound and alarm")
    XCTAssertTrue(start.isHittable)
    start.tap()
    XCTAssertTrue(app.staticTexts["napRunStatus"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["napRunStatus"].label.contains("Gentle rain is playing"))
    attachCountdownDebug("AX5 timer after admission", app: app)
    let remaining = app.staticTexts["restTimeRemaining"]
    XCTAssertTrue(remaining.exists)
    scrollTo(remaining, in: app)
    XCTAssertTrue(remaining.isHittable)
    attachScreen("AX5 active rest countdown")
    scrollTo(app.buttons["stopNapRun"], in: app)
    app.buttons["stopNapRun"].tap()
  }

  private func attachScreen(_ name: String) {
    let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  private func attachCountdownDebug(_ name: String, app: XCUIApplication) {
    attachScreen(name)
    let identifiers = [
      "napRunStatus", "restTimerRunning", "restTimerEnded", "restTimeRemaining",
      "napPlanConfirmedDeadline", "stopNapRun",
    ]
    let summary = identifiers.map { identifier in
      let element = app.descendants(matching: .any)[identifier]
      let label = element.exists ? element.label : "—"
      return "\(identifier): exists=\(element.exists), label=\(label)"
    }
    let matchingTree = app.debugDescription.split(separator: "\n")
      .filter { line in identifiers.contains(where: { line.contains($0) }) }
      .prefix(20)
      .joined(separator: "\n")
    let attachment = XCTAttachment(string: (summary + [matchingTree]).joined(separator: "\n"))
    attachment.name = "\(name) — countdown accessibility"
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  private func launch(
    reset: Bool, showWelcome: Bool = false, arguments: [String] = [], alarm: String = "authorized"
  )
    -> XCUIApplication
  {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing"] + arguments
    app.launchEnvironment = [
      "HONKSHOOL_UI_TEST_ALARM": alarm,
      "HONKSHOOL_UI_TEST_AUDIO": "1",
      "HONKSHOOL_UI_TEST_RESET": reset ? "1" : "0",
      "HONKSHOOL_UI_TEST_SHOW_WELCOME": showWelcome ? "1" : "0",
    ]
    app.launch()
    return app
  }

  private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
    let window = app.windows.firstMatch
    let frame = window.frame
    func visible() -> Bool {
      let center = element.frame.midY
      let footer = ["startRestTimer", "reviewNapPlan", "startNapRun"].map { app.buttons[$0] }
        .filter { $0.exists && $0.isHittable }.map { $0.frame.minY }.min()
      let bottom = min(footer ?? frame.maxY, app.tabBars.firstMatch.frame.minY)
      return element.isHittable && center > frame.minY + 100 && center < bottom - 12
    }
    for direction in [true, false] {
      for _ in 0..<16 {
        if visible() { return }
        let from = window.coordinate(
          withNormalizedOffset: CGVector(dx: 0.5, dy: direction ? 0.65 : 0.3))
        let to = window.coordinate(
          withNormalizedOffset: CGVector(dx: 0.5, dy: direction ? 0.3 : 0.65))
        from.press(forDuration: 0.1, thenDragTo: to, withVelocity: .slow, thenHoldForDuration: 0.2)
      }
    }
    XCTAssertTrue(visible())
  }
}
