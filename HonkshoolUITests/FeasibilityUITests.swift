import XCTest

final class FeasibilityUITests: XCTestCase {
  private enum AlarmScenario: String {
    case notDetermined = "not-determined"
    case denied
    case authorized
    case scheduleFailure = "schedule-failure"
    case cancelFailure = "cancel-failure"
    case snoozed
    case paused
    case alerting
    case readFailure = "read-failure"
  }

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testAlarmDisabledStartCancelsTrackedSnooze() {
    let app = launch(alarm: .snoozed)
    let toggle = app.switches["requireAlarm"]
    scrollTo(toggle, in: app)
    toggle.tap()
    let start = app.buttons["startTest"]
    scrollTo(start, in: app)
    start.tap()
    assertLabel(app.staticTexts["alarmStatus"], equals: "Alarm status, No alarm")
    assertLabel(app.staticTexts["playbackPhase"], equals: "Phase, Narrating")
    assertLabel(
      app.staticTexts["runMessage"],
      equals: "Alarm explicitly disabled. Lock the screen and observe the test."
    )
  }

  func testAlarmDisabledStartBlocksWhenCancellationFails() {
    let app = launch(alarm: .cancelFailure)
    let toggle = app.switches["requireAlarm"]
    scrollTo(toggle, in: app)
    toggle.tap()
    let start = app.buttons["startTest"]
    scrollTo(start, in: app)
    start.tap()
    assertAlert(in: app, contains: "could not be cancelled")
    assertLabel(app.staticTexts["playbackPhase"], equals: "Phase, Idle")
  }

  func testNotDeterminedStartExplainsBlockAndAuthorizationAllowsStart() {
    let app = launch(alarm: .notDetermined)
    let start = app.buttons["startTest"]
    scrollTo(start, in: app)
    start.tap()
    assertAlert(in: app, contains: "authorization")
    assertLabel(app.staticTexts["playbackPhase"], equals: "Phase, Idle")
    app.alerts.buttons["OK"].tap()

    let authorize = app.buttons["authorizeAlarm"]
    scrollTo(authorize, in: app)
    authorize.tap()
    assertLabel(
      app.staticTexts["alarmAuthorization"], equals: "Authorization, Authorized"
    )
    scrollTo(start, in: app)
    start.tap()
    assertLabel(app.staticTexts["alarmStatus"], equals: "Alarm status, Scheduled")
    assertLabel(app.staticTexts["playbackPhase"], equals: "Phase, Narrating")
  }

  func testDeniedStartExplainsBlockWithoutBeginningAudio() {
    let app = launch(alarm: .denied)
    let start = app.buttons["startTest"]
    scrollTo(start, in: app)
    start.tap()
    assertAlert(in: app, contains: "authorization")
    assertLabel(app.staticTexts["playbackPhase"], equals: "Phase, Idle")
  }

  func testScheduleFailureExplainsBlockWithoutBeginningAudio() {
    let app = launch(alarm: .scheduleFailure)
    let start = app.buttons["startTest"]
    scrollTo(start, in: app)
    start.tap()
    assertAlert(in: app, contains: "successfully scheduled")
    assertLabel(app.staticTexts["playbackPhase"], equals: "Phase, Idle")
  }

  func testAlarmEnabledPlaybackScrollsAndStopDoesNotCancelAlarm() {
    let app = launch(alarm: .authorized)
    startRun(in: app)
    assertLabel(app.staticTexts["alarmStatus"], equals: "Alarm status, Scheduled")

    let log = app.buttons["audioEventLog"]
    scrollTo(log, in: app)
    log.tap()
    XCTAssertTrue(app.navigationBars["Audio event log"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.staticTexts["No audio events yet"].exists)
    app.navigationBars.buttons.firstMatch.tap()

    for _ in 0..<3 {
      for _ in 0..<6 { app.swipeDown() }
      XCTAssertTrue(app.staticTexts["Test session"].isHittable)
      for _ in 0..<5 { app.swipeUp() }
    }

    let stop = app.buttons["stopPlayback"]
    scrollTo(stop, in: app)
    stop.tap()
    assertLabel(app.staticTexts["playbackPhase"], equals: "Phase, Stopped")
    assertLabel(app.staticTexts["alarmStatus"], equals: "Alarm status, Scheduled")
  }

  func testInAppPauseResumeAndStopControlsDrivePlaybackState() {
    let app = launch(alarm: .authorized)
    startRun(in: app)

    let pause = app.buttons["pausePlayback"]
    scrollTo(pause, in: app)
    XCTAssertTrue(pause.isEnabled)
    pause.tap()
    assertLabel(app.staticTexts["playbackPhase"], equals: "Phase, Paused")
    let resume = app.buttons["resumePlayback"]
    XCTAssertTrue(resume.isEnabled)
    resume.tap()
    assertLabel(app.staticTexts["playbackPhase"], equals: "Phase, Narrating")
    app.buttons["stopPlayback"].tap()
    assertLabel(app.staticTexts["playbackPhase"], equals: "Phase, Stopped")
  }

  func testShortAlarmCanBeScheduledAndCancelledWithoutPlayback() {
    let app = launch(alarm: .authorized)
    let shortAlarm = app.buttons["shortAlarmTest"]
    scrollTo(shortAlarm, in: app)
    shortAlarm.tap()
    assertLabel(app.staticTexts["alarmStatus"], equals: "Alarm status, Scheduled")
    let cancel = app.buttons["cancelAlarm"]
    XCTAssertTrue(cancel.isEnabled)
    cancel.tap()
    assertLabel(app.staticTexts["alarmStatus"], equals: "Alarm status, No alarm")
  }

  func testSnoozeShowsSystemDeadlineCountdownAndCanBeCancelled() {
    let app = launch(alarm: .snoozed)
    let status = app.staticTexts["alarmStatus"]
    scrollTo(status, in: app)
    assertLabel(status, equals: "Alarm status, Snoozed")
    XCTAssertTrue(app.staticTexts["nextAlertTime"].exists)
    XCTAssertTrue(app.staticTexts["snoozeRemaining"].exists)
    let cancel = app.buttons["cancelAlarm"]
    XCTAssertTrue(cancel.isEnabled)
    cancel.tap()
    assertLabel(app.staticTexts["alarmStatus"], equals: "Alarm status, No alarm")
  }

  func testPausedAlertingAndUnavailableAlarmStatesRemainCancellable() {
    for fixture in [
      (AlarmScenario.paused, "Alarm status, Snooze paused"),
      (AlarmScenario.alerting, "Alarm status, Ringing"),
      (AlarmScenario.readFailure, "Alarm status, Status unavailable"),
    ] {
      let app = launch(alarm: fixture.0)
      let status = app.staticTexts["alarmStatus"]
      scrollTo(status, in: app)
      assertLabel(status, equals: fixture.1)
      XCTAssertTrue(app.buttons["cancelAlarm"].isEnabled)
      app.terminate()
    }
  }

  func testCustomDurationPersistsAndExactWakePickerIsAvailable() {
    var app = launch(alarm: .authorized)
    let stepper = app.steppers["Custom: 35 minutes"]
    scrollTo(stepper, in: app)
    app.buttons["Increment"].tap()
    let updatedStepper = app.steppers["Custom: 40 minutes"]
    XCTAssertTrue(updatedStepper.waitForExistence(timeout: 5))
    XCTAssertEqual(updatedStepper.value as? String, "40")
    app.buttons["saveDefaultDuration"].tap()
    assertLabel(
      app.staticTexts["runMessage"], equals: "Saved a reusable 40-minute default."
    )
    app.terminate()

    app = launch(alarm: .authorized, reset: false)
    XCTAssertTrue(app.buttons["Saved, 40 min"].waitForExistence(timeout: 5))
    let exact = app.switches["useExactWakeTime"]
    scrollTo(exact, in: app)
    exact.tap()
    XCTAssertTrue(app.datePickers["exactWakeTime"].waitForExistence(timeout: 5))
  }

  private func launch(alarm: AlarmScenario, reset: Bool = true) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing"]
    app.launchEnvironment = [
      "HONKSHOOL_UI_TEST_ALARM": alarm.rawValue,
      "HONKSHOOL_UI_TEST_AUDIO": "1",
      "HONKSHOOL_UI_TEST_RESET": reset ? "1" : "0",
    ]
    app.launch()
    return app
  }

  private func startRun(in app: XCUIApplication) {
    let start = app.buttons["startTest"]
    scrollTo(start, in: app)
    start.tap()
    assertLabel(app.staticTexts["playbackPhase"], equals: "Phase, Narrating")
    assertLabel(
      app.staticTexts["runMessage"],
      equals: "Alarm scheduled before playback. Lock the screen and observe the test."
    )
  }

  private func assertAlert(in app: XCUIApplication, contains text: String) {
    let alert = app.alerts["Test cannot start"]
    XCTAssertTrue(alert.waitForExistence(timeout: 5))
    XCTAssertTrue(
      alert.staticTexts.containing(
        NSPredicate(format: "label CONTAINS[c] %@", text)
      ).firstMatch.exists
    )
  }

  private func assertLabel(_ element: XCUIElement, equals label: String) {
    let expectation = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label == %@", label), object: element
    )
    XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
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
