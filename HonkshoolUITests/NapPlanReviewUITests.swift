import XCTest

final class NapPlanReviewUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testPhysicalRainControlsBackgroundDeadlineAndEmptyHistoryOnRelaunch() throws {
    guard ProcessInfo.processInfo.environment["HONKSHOOL_REAL_RAIN_TEST"] == "1" else {
      throw XCTSkip("Opt in on a connected physical iPhone for real rain playback.")
    }
    #if targetEnvironment(simulator)
      throw XCTSkip("A simulator cannot establish physical background playback.")
    #else
      // Keep the normal one-minute review lead and real run clock. Only the
      // existing UI-test storage is isolated; the Nap Plan uses real audio.
      let app = launchReview(additionalEnvironment: [
        "HONKSHOOL_UI_TEST_PLAN_NOW": "",
        "HONKSHOOL_UI_TEST_AUDIO": "0",
      ])
      defer { app.terminate() }
      let duration = app.buttons["napPlanDuration"]
      scrollTo(duration, in: app)
      duration.tap()
      app.buttons["5 minutes"].tap()
      let custom = app.steppers["napPlanCustomDuration"]
      scrollTo(custom, in: app)
      for _ in 0..<4 { custom.buttons["napPlanCustomDuration-Decrement"].tap() }

      let sound = app.buttons["napPlanSound"]
      scrollTo(sound, in: app)
      sound.tap()
      app.buttons["Gentle rain"].tap()
      let alarm = app.switches["napPlanAlarm"]
      scrollTo(alarm, in: app)
      alarm.tap()
      let review = app.buttons["reviewNapPlan"]
      scrollTo(review, in: app)
      review.tap()
      XCTAssertTrue(app.staticTexts["napPlanNoContent"].exists)
      XCTAssertEqual(app.staticTexts["napPlanAlarmChoice"].label, "Wake alarm, Not requested")
      let confirm = app.buttons["confirmNapPlan"]
      scrollTo(confirm, in: app)
      confirm.tap()
      let originalStart = app.staticTexts["napPlanConfirmedStart"].label
      let originalDeadline = app.staticTexts["napPlanConfirmedDeadline"].label
      let start = app.buttons["startNapRun"]
      scrollTo(start, in: app)
      start.tap()

      let status = app.staticTexts["napRunStatus"]
      let playing = XCTNSPredicateExpectation(
        predicate: NSPredicate(format: "label CONTAINS %@", "Gentle rain is playing"),
        object: status)
      XCTAssertEqual(XCTWaiter.wait(for: [playing], timeout: 70), .completed)
      let startObservation = XCTAttachment(
        string: "\(originalStart); UI observed rain at \(Date.now.ISO8601Format()).")
      startObservation.name = "Physical UI rain start"
      startObservation.lifetime = .keepAlways
      add(startObservation)
      let pause = app.buttons["pauseNapRun"]
      scrollTo(pause, in: app)
      pause.tap()
      XCTAssertTrue(status.label.contains("Paused"))
      let resume = app.buttons["resumeNapRun"]
      scrollTo(resume, in: app)
      resume.tap()
      XCTAssertTrue(status.label.contains("Gentle rain resumed"))

      XCUIDevice.shared.press(.home)
      XCTAssertTrue(app.wait(for: .runningBackground, timeout: 5))
      // This spans a complete bundled loop while the real app is backgrounded.
      Thread.sleep(forTimeInterval: 12)
      XCTAssertEqual(app.state, .runningBackground)
      app.activate()
      XCTAssertTrue(status.label.contains("Gentle rain resumed"))
      XCTAssertEqual(app.staticTexts["napPlanConfirmedDeadline"].label, originalDeadline)
      scrollTo(pause, in: app)
      pause.tap()
      scrollTo(resume, in: app)
      resume.tap()

      let finished = XCTNSPredicateExpectation(
        predicate: NSPredicate(
          format: "label CONTAINS[c] %@ AND label CONTAINS %@", "stopped", "deadline"),
        object: status)
      XCTAssertEqual(XCTWaiter.wait(for: [finished], timeout: 65), .completed)
      XCTAssertFalse(app.buttons["pauseNapRun"].exists)
      XCTAssertFalse(app.buttons["resumeNapRun"].exists)
      XCTAssertEqual(app.staticTexts["napPlanConfirmedDeadline"].label, originalDeadline)

      app.terminate()
      app.launchEnvironment["HONKSHOOL_UI_TEST_RESET"] = "0"
      app.launch()
      XCTAssertFalse(app.staticTexts["activeNapRunStatus"].exists)
      let history = app.buttons["openListeningHistory"]
      scrollTo(history, in: app)
      history.tap()
      XCTAssertTrue(app.staticTexts["No listening history yet"].waitForExistence(timeout: 5))
    #endif
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

  func testGentleRainChoiceIsReviewedConfirmedAndCanBeStoppedWhileWaiting() {
    let app = launchReview()
    let sound = app.buttons["napPlanSound"]
    scrollTo(sound, in: app)
    sound.tap()
    app.buttons["Gentle rain"].tap()
    XCTAssertTrue(app.staticTexts["napPlanSoundFallbackDisclosure"].exists)

    let review = app.buttons["reviewNapPlan"]
    scrollTo(review, in: app)
    review.tap()
    XCTAssertEqual(
      app.staticTexts["napPlanPostNarrationSound"].label, "After narration, Gentle rain")
    XCTAssertTrue(app.staticTexts["napPlanReviewedSoundFallback"].exists)

    let confirm = app.buttons["confirmNapPlan"]
    scrollTo(confirm, in: app)
    confirm.tap()
    XCTAssertEqual(app.staticTexts["napPlanConfirmedSound"].label, "After narration, Gentle rain")
    let start = app.buttons["startNapRun"]
    scrollTo(start, in: app)
    start.tap()
    XCTAssertTrue(app.staticTexts["napRunStatus"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["napRunStatus"].label.contains("Keep Honkshool open"))
    let stop = app.buttons["stopNapRun"]
    scrollTo(stop, in: app)
    stop.tap()
    XCTAssertFalse(app.buttons["stopNapRun"].exists)
  }

  func testUnavailableGentleRainIsHiddenAndSilenceRemainsSelectable() {
    let app = launchReview(additionalEnvironment: [
      "HONKSHOOL_UI_TEST_PLAN_RAIN_UNAVAILABLE": "1"
    ])
    XCTAssertTrue(app.staticTexts["napPlanSoundUnavailable"].waitForExistence(timeout: 5))
    let sound = app.buttons["napPlanSound"]
    scrollTo(sound, in: app)
    sound.tap()
    XCTAssertFalse(app.buttons["Gentle rain"].exists)
    XCTAssertTrue(app.buttons["Silence"].exists)
    app.buttons["Silence"].tap()
    let review = app.buttons["reviewNapPlan"]
    scrollTo(review, in: app)
    review.tap()
    XCTAssertEqual(app.staticTexts["napPlanPostNarrationSound"].label, "After narration, Silence")
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
