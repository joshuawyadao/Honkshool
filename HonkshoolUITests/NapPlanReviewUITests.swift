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
      chooseDuration(5, in: app)
      openTimeOptions(in: app)
      let custom = app.steppers["napPlanCustomDuration"]
      scrollTo(custom, in: app)
      for _ in 0..<4 { custom.buttons["napPlanCustomDuration-Decrement"].tap() }
      app.buttons["applyNapTime"].tap()

      let sound = app.buttons["napPlanSound"]
      scrollTo(sound, in: app)
      sound.tap()
      app.buttons["Gentle rain"].tap()
      app.buttons["applyNapSound"].tap()
      let alarm = app.switches["napPlanAlarm"]
      scrollTo(alarm, in: app)
      alarm.tap()
      let status = app.staticTexts["napRunStatus"]
      var originalStart = ""
      var originalDeadline = ""
      for attempt in 0..<2 {
        let review = app.buttons["reviewNapPlan"]
        scrollTo(review, in: app)
        review.tap()
        XCTAssertTrue(app.staticTexts["napPlanNoContent"].exists)
        XCTAssertEqual(app.staticTexts["napPlanAlarmChoice"].label, "Wake alarm, Not requested")
        let confirm = app.buttons["confirmNapPlan"]
        scrollTo(confirm, in: app)
        confirm.tap()
        originalStart = app.staticTexts["napPlanConfirmedStart"].label
        originalDeadline = app.staticTexts["napPlanConfirmedDeadline"].label
        let start = app.buttons["startNapRun"]
        scrollTo(start, in: app)
        start.tap()

        let outcome = XCTNSPredicateExpectation(
          predicate: NSPredicate(
            format: "label CONTAINS %@ OR label CONTAINS %@",
            "Gentle rain is playing", "Review a new Nap Plan"),
          object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [outcome], timeout: 70), .completed)
        if status.label.contains("Gentle rain is playing") { break }
        let failure = status.label
        guard attempt == 0,
          failure == "Audio output disconnected before playback. Review a new Nap Plan."
        else {
          XCTFail("The reviewed rain plan did not start: \(failure)")
          return
        }
        let routeChange = XCTAttachment(string: failure)
        routeChange.name = "Physical audio route change before playback"
        routeChange.lifetime = .keepAlways
        add(routeChange)
        let another = app.buttons["reviewAnotherNapPlan"]
        scrollTo(another, in: app)
        another.tap()
      }
      XCTAssertTrue(status.label.contains("Gentle rain is playing"))
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
      XCTAssertFalse(app.staticTexts["napRunStatus"].exists)
      app.tabBars.buttons["History"].tap()
      XCTAssertTrue(app.staticTexts["Nothing played yet"].waitForExistence(timeout: 5))
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
    XCTAssertTrue(app.staticTexts["napPlanRouteEnd"].label.contains("does not fit"))

    let deadline = app.staticTexts["napPlanDeadline"].label
    let confirm = app.buttons["confirmNapPlan"]
    scrollTo(confirm, in: app)
    confirm.tap()
    let confirmation = app.staticTexts["napPlanConfirmation"]
    XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
    XCTAssertEqual(
      confirmation.label,
      "Start by the planned rest time below. If it passes, we’ll review the timing again.")
    XCTAssertFalse(app.staticTexts["napRunStatus"].exists)
    XCTAssertTrue(app.buttons["startNapRun"].exists)
    XCTAssertTrue(app.staticTexts["napPlanConfirmedStart"].label.contains("Planned rest start"))
    XCTAssertFalse(app.buttons["reviewNapPlan"].exists)
    XCTAssertTrue(
      app.staticTexts["napPlanConfirmedDeadline"].label.contains(
        deadline.replacingOccurrences(of: "Fixed wake deadline, ", with: "")))
  }

  func testChoosingSecondSessionReviewsItFromTheStart() {
    let app = launchReview()
    let content = app.buttons["napPlanContent"]
    scrollTo(content, in: app)
    content.tap()
    let second = app.buttons["chooseSession-air-fuel-and-spark"]
    scrollTo(second, in: app)
    second.tap()
    let review = app.buttons["reviewNapPlan"]
    scrollTo(review, in: app)
    review.tap()
    let firstRoute = app.descendants(matching: .any)["napPlanRouteItem-0"]
    scrollTo(firstRoute, in: app)
    XCTAssertTrue(firstRoute.label.contains("Air, Fuel, and Spark"))
    XCTAssertFalse(app.descendants(matching: .any)["napPlanRouteItem-1"].exists)
    XCTAssertFalse(app.staticTexts["napPlanReviewedResume"].exists)
  }

  func testLongPlanReviewsBothOrderedSessionsAndFixedDeadline() {
    let app = launchReview()
    let duration = app.buttons["napPlanPreset-45"]
    scrollTo(duration, in: app)
    duration.tap()
    let review = app.buttons["reviewNapPlan"]
    scrollTo(review, in: app)
    review.tap()
    let first = app.descendants(matching: .any)["napPlanRouteItem-0"]
    let second = app.descendants(matching: .any)["napPlanRouteItem-1"]
    scrollTo(first, in: app)
    XCTAssertTrue(first.label.contains("Turning Fuel Into Motion"))
    scrollTo(second, in: app)
    XCTAssertTrue(second.label.contains("Air, Fuel, and Spark"))
    XCTAssertFalse(app.descendants(matching: .any)["napPlanRouteItem-2"].exists)
    XCTAssertTrue(app.staticTexts["napPlanRouteEnd"].label.contains("journey route ends"))
    let deadline = app.staticTexts["napPlanDeadline"].label
    let confirm = app.buttons["confirmNapPlan"]
    scrollTo(confirm, in: app)
    confirm.tap()
    XCTAssertTrue(app.staticTexts["napPlanConfirmation"].waitForExistence(timeout: 5))
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
    app.buttons["applyNapSound"].tap()
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

  func testRainOnlyPlanDescribesRestSoundWithoutNarrationPromises() {
    let app = launchReview(additionalEnvironment: ["HONKSHOOL_UI_TEST_ALARM": "not-determined"])
    chooseDuration(5, in: app)
    let sound = app.buttons["napPlanSound"]
    scrollTo(sound, in: app)
    XCTAssertTrue(sound.label.contains("Rest sound"))
    sound.tap()
    XCTAssertTrue(app.navigationBars["Rest sound"].exists)
    XCTAssertTrue(app.staticTexts["Choose what plays during quiet parts of your rest."].exists)
    app.buttons["Gentle rain"].tap()
    app.buttons["applyNapSound"].tap()
    app.buttons["reviewNapPlan"].tap()
    XCTAssertTrue(app.staticTexts["napPlanNoContent"].exists)
    XCTAssertTrue(app.staticTexts["Your rest sound"].exists)
    XCTAssertFalse(app.staticTexts["Your narration route"].exists)
    XCTAssertEqual(app.staticTexts["napPlanPostNarrationSound"].label, "Rest sound, Gentle rain")
    let confirm = app.buttons["confirmNapPlan"]
    scrollTo(confirm, in: app)
    XCTAssertEqual(confirm.label, "Confirm rest plan")
    XCTAssertTrue(
      app.staticTexts["napPlanHistoryExplanation"].label.contains("no narration to save"))
    capture("Rain-only rest review", in: app)
    confirm.tap()
    XCTAssertEqual(app.staticTexts["napPlanConfirmedSound"].label, "Rest sound, Gentle rain")
    app.buttons["startNapRun"].tap()
    XCTAssertEqual(
      app.staticTexts["napPlanAlarmAccessExplanation"].label,
      "We’ll check that it’s set before your rest starts.")
    XCTAssertFalse(app.staticTexts["napRunStatus"].exists)
    capture("Rain-only alarm explanation", in: app)
    let proceed = app.buttons["continueAlarmAccess"]
    scrollTo(proceed, in: app)
    proceed.tap()
    XCTAssertTrue(app.staticTexts["napRunStatus"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["napPlanConfirmedSound"].label, "Rest sound, Gentle rain")
    let stop = app.buttons["stopNapRun"]
    scrollTo(stop, in: app)
    stop.tap()
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
    app.buttons["applyNapSound"].tap()
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

    let alarmStatus = app.staticTexts["napPlanAlarmStatus"]
    scrollTo(alarmStatus, in: app)
    XCTAssertTrue(alarmStatus.label.contains("scheduled"))
    XCTAssertFalse(app.buttons["cancelNapPlanAlarm"].exists)

    let stop = app.buttons["stopNapRun"]
    scrollTo(stop, in: app)
    stop.tap()
    XCTAssertTrue(
      app.staticTexts["napRunStatus"].label.contains("wake alarm was not cancelled"))
    let cancel = app.buttons["cancelNapPlanAlarm"]
    scrollTo(cancel, in: app)
    cancel.tap()
    XCTAssertFalse(app.buttons["cancelNapPlanAlarm"].exists)
  }

  func testAlarmDenialBlocksRequestedRunWithoutAudio() {
    let app = launchReview(additionalEnvironment: [
      "HONKSHOOL_UI_TEST_ALARM": "denied", "HONKSHOOL_UI_TEST_PLAN_NOW": "",
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
    XCTAssertTrue(app.buttons["reviewUpdatedNapTiming"].waitForExistence(timeout: 70))
    XCTAssertTrue(app.staticTexts["napRunError"].exists)
    XCTAssertTrue(app.buttons["openAlarmSettings"].exists)
    XCTAssertFalse(app.buttons["retryNapStart"].exists)
    XCTAssertFalse(app.buttons["startNapRun"].exists)
  }

  func testShortWindowReviewsSilenceOnlyAndNoAlarm() {
    let app = launchReview()
    chooseDuration(5, in: app)
    let alarm = app.switches["napPlanAlarm"]
    scrollTo(alarm, in: app)
    alarm.tap()
    let review = app.buttons["reviewNapPlan"]
    scrollTo(review, in: app)
    review.tap()

    XCTAssertTrue(app.staticTexts["napPlanNoContent"].exists)
    XCTAssertEqual(app.staticTexts["napPlanAlarmChoice"].label, "Wake alarm, Not requested")
    XCTAssertEqual(app.staticTexts["napPlanPostNarrationSound"].label, "Rest sound, Silence")
    XCTAssertTrue(app.staticTexts["napPlanRouteEnd"].label.contains("does not fit"))

    let confirm = app.buttons["confirmNapPlan"]
    scrollTo(confirm, in: app)
    XCTAssertEqual(confirm.label, "Confirm rest plan")
    XCTAssertTrue(
      app.staticTexts["napPlanHistoryExplanation"].label.contains("no narration to save"))
    confirm.tap()
    XCTAssertEqual(app.staticTexts["napPlanConfirmedSound"].label, "Rest sound, Silence")
    let start = app.buttons["startNapRun"]
    scrollTo(start, in: app)
    XCTAssertTrue(start.isEnabled)
    start.tap()
    XCTAssertTrue(app.staticTexts["napRunStatus"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["napRunStatus"].label.contains("Keep Honkshool open"))
    let parentStatus = app.staticTexts["napRunStatus"]
    scrollTo(parentStatus, in: app)
    XCTAssertTrue(parentStatus.label.contains("Keep Honkshool open"))
    let stop = app.buttons["stopNapRun"]
    scrollTo(stop, in: app)
    XCTAssertEqual(stop.label, "End rest")
    XCTAssertFalse(parentStatus.label.localizedCaseInsensitiveContains("playback"))
    capture("Quiet rest waiting", in: app)
    stop.tap()
    XCTAssertTrue(parentStatus.label.contains("Quiet rest ended"))
    capture("Quiet rest ended", in: app)
    XCTAssertFalse(app.buttons["stopNapRun"].exists)

    let reopen = app.buttons["reviewAnotherNapPlan"]
    scrollTo(reopen, in: app)
    reopen.tap()
    chooseDuration(5, in: app)
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
    openTimeOptions(in: app)
    let exact = app.switches["napPlanUseExactWakeTime"]
    scrollTo(exact, in: app)
    exact.tap()
    XCTAssertTrue(app.datePickers["napPlanExactWakeTime"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["napPlanDuration"].exists)
    XCTAssertTrue(app.datePickers["napPlanExactWakeTime"].label.contains("Wake time"))
    app.buttons["applyNapTime"].tap()
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
    openTimeOptions(in: app)
    let exact = app.switches["napPlanUseExactWakeTime"]
    scrollTo(exact, in: app)
    exact.tap()
    app.buttons["applyNapTime"].tap()
    let review = app.buttons["reviewNapPlan"]
    scrollTo(review, in: app)
    review.tap()
    let confirm = app.buttons["confirmNapPlan"]
    scrollTo(confirm, in: app)
    confirm.tap()
    XCTAssertFalse(app.staticTexts["napPlanConfirmation"].exists)
    XCTAssertTrue(
      app.staticTexts["napPlanError"].label.contains("Choose a future wake time"))
  }

  func testExpiredExactWakeRecoveryExposesErrorAndTimeControls() {
    assertExpiredExactWakeRecovery(largestText: false)
  }

  func testExpiredExactWakeRecoveryExposesErrorAndTimeControlsAtLargestText() {
    assertExpiredExactWakeRecovery(largestText: true)
  }

  private func assertExpiredExactWakeRecovery(
    largestText: Bool, file: StaticString = #filePath, line: UInt = #line
  ) {
    // Approval uses an earlier instant; real runtime observes the already-expired wake time.
    let app = launchReview(
      additionalEnvironment: [
        "HONKSHOOL_UI_TEST_PLAN_NOW": String(
          Date.now.addingTimeInterval(-1260).timeIntervalSince1970)
      ], largestText: largestText)
    openTimeOptions(in: app)
    let exact = app.switches["napPlanUseExactWakeTime"]
    scrollTo(exact, in: app)
    exact.tap()
    XCTAssertTrue(
      app.datePickers["napPlanExactWakeTime"].waitForExistence(timeout: 5),
      file: file, line: line)
    app.buttons["applyNapTime"].tap()
    let originalTime = app.staticTexts["napPlanTimeSummary"].label
    reviewAndConfirm(in: app)
    let update = app.buttons["reviewUpdatedNapTiming"]
    scrollTo(update, in: app)
    update.tap()
    let error = app.staticTexts["napPlanError"]
    XCTAssertTrue(error.waitForExistence(timeout: 5), file: file, line: line)
    XCTAssertTrue(error.label.contains("Choose a future wake time"), file: file, line: line)
    XCTAssertTrue(app.navigationBars["Time to rest"].exists, file: file, line: line)
    capture(largestText ? "AX5 exact-time recovery" : "Exact-time recovery", in: app)
    // Do not scroll before these assertions: the recovery must initially expose both
    // the complete error and an editable control above the pinned Apply action.
    let apply = app.buttons["applyNapTime"]
    let wake = app.datePickers["napPlanExactWakeTime"]
    XCTAssertTrue(error.isHittable, file: file, line: line)
    XCTAssertTrue(wake.isHittable, file: file, line: line)
    XCTAssertGreaterThanOrEqual(
      error.frame.minY, app.navigationBars.firstMatch.frame.maxY,
      file: file, line: line)
    XCTAssertLessThan(error.frame.maxY, apply.frame.minY, file: file, line: line)
    XCTAssertLessThan(wake.frame.maxY, apply.frame.minY, file: file, line: line)
    XCTAssertFalse(app.buttons["startNapRun"].exists, file: file, line: line)
    app.buttons["cancelNapTime"].tap()
    XCTAssertEqual(
      app.staticTexts["napPlanTimeSummary"].label, originalTime,
      file: file, line: line)
    XCTAssertTrue(app.staticTexts["napPlanTimeError"].exists, file: file, line: line)
    // Explicitly choosing a duration removes the invalid absolute time and requires review.
    openTimeOptions(in: app)
    scrollTo(exact, in: app)
    exact.tap()
    app.buttons["applyNapTime"].tap()
    XCTAssertFalse(app.staticTexts["napPlanTimeError"].exists, file: file, line: line)
    app.buttons["reviewNapPlan"].tap()
    XCTAssertTrue(
      app.staticTexts["napPlanDeadline"].waitForExistence(timeout: 5),
      file: file, line: line)
    XCTAssertFalse(app.staticTexts["napPlanError"].exists, file: file, line: line)
    XCTAssertFalse(app.buttons["startNapRun"].exists, file: file, line: line)
  }

  func testActiveNapAndWakeAlarmSurviveHistoryTabRoundTrip() {
    let app = launchReview()
    scrollTo(app.buttons["reviewNapPlan"], in: app)
    app.buttons["reviewNapPlan"].tap()
    scrollTo(app.buttons["confirmNapPlan"], in: app)
    app.buttons["confirmNapPlan"].tap()
    scrollTo(app.buttons["startNapRun"], in: app)
    app.buttons["startNapRun"].tap()
    XCTAssertTrue(app.staticTexts["napRunStatus"].waitForExistence(timeout: 5))
    let deadline = app.staticTexts["napPlanConfirmedDeadline"].label
    app.tabBars.buttons["History"].tap()
    XCTAssertFalse(app.buttons["historyContinue"].isEnabled)
    app.tabBars.buttons["Rest"].tap()
    XCTAssertEqual(app.staticTexts["napPlanConfirmedDeadline"].label, deadline)
    XCTAssertTrue(app.staticTexts["napRunStatus"].label.contains("Keep Honkshool open"))
    scrollTo(app.buttons["stopNapRun"], in: app)
    app.buttons["stopNapRun"].tap()
    XCTAssertTrue(app.buttons["cancelNapPlanAlarm"].exists)
  }

  func testSessionDetailsUseBundledMetadataAndDismissWithoutStarting() {
    let app = launchReview()
    let details = app.buttons["napPlanSessionDetail"]
    scrollTo(details, in: app)
    details.tap()
    XCTAssertTrue(app.navigationBars["Session"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Turning Fuel Into Motion"].exists)
    XCTAssertFalse(app.buttons["stopNapRun"].exists)
    app.buttons["dismissSessionDetail"].tap()
    XCTAssertTrue(app.buttons["reviewNapPlan"].waitForExistence(timeout: 5))
  }

  func testConsumedHistoryConfirmationCannotRestartAfterRestResetsRun() {
    let app = launchReview(additionalEnvironment: ["HONKSHOOL_UI_TEST_SEED_HISTORY": "1"])
    app.tabBars.buttons["History"].tap()
    scrollTo(app.buttons["historyResume"], in: app)
    app.buttons["historyResume"].tap()
    scrollTo(app.switches["napPlanAlarm"], in: app)
    app.switches["napPlanAlarm"].tap()
    scrollTo(app.buttons["reviewNapPlan"], in: app)
    app.buttons["reviewNapPlan"].tap()
    scrollTo(app.buttons["confirmNapPlan"], in: app)
    app.buttons["confirmNapPlan"].tap()
    scrollTo(app.buttons["startNapRun"], in: app)
    app.buttons["startNapRun"].tap()
    scrollTo(app.buttons["stopNapRun"], in: app)
    app.buttons["stopNapRun"].tap()
    app.tabBars.buttons["Rest"].tap()
    scrollTo(app.buttons["reviewAnotherNapPlan"], in: app)
    app.buttons["reviewAnotherNapPlan"].tap()
    app.tabBars.buttons["History"].tap()
    XCTAssertTrue(app.buttons["reviewNapPlan"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["startNapRun"].exists)
    XCTAssertFalse(app.staticTexts["napPlanConfirmation"].exists)
  }

  func testReadyExpiresWithoutTapAndRequiresFreshReview() {
    let app = launchReview(additionalEnvironment: ["HONKSHOOL_UI_TEST_PLAN_NOW": ""])
    let alarm = app.switches["napPlanAlarm"]
    scrollTo(alarm, in: app)
    alarm.tap()
    reviewAndConfirm(in: app)
    let deadline = app.staticTexts["napPlanConfirmedDeadline"].label
    XCTAssertTrue(app.buttons["startNapRun"].exists)
    capture("Ready before expiry", in: app)
    XCTAssertTrue(app.buttons["reviewUpdatedNapTiming"].waitForExistence(timeout: 70))
    XCTAssertFalse(app.buttons["startNapRun"].exists)
    XCTAssertFalse(app.staticTexts["napRunStatus"].exists)
    XCTAssertEqual(app.staticTexts["napPlanConfirmedDeadline"].label, deadline)
    capture("Expired ready state", in: app)
    app.buttons["reviewUpdatedNapTiming"].tap()
    XCTAssertFalse(app.buttons["startNapRun"].exists)
    XCTAssertTrue(app.buttons["confirmNapPlan"].exists)
    XCTAssertEqual(app.staticTexts["napPlanAlarmChoice"].label, "Wake alarm, Not requested")
    let confirm = app.buttons["confirmNapPlan"]
    scrollTo(confirm, in: app)
    confirm.tap()
    XCTAssertTrue(app.buttons["startNapRun"].exists)
    XCTAssertNotEqual(app.staticTexts["napPlanConfirmedDeadline"].label, deadline)
  }

  func testAlarmPrimerExpiresWhileBackgroundedAndReturnsToReviewAtLargestText() {
    let app = launchReview(
      additionalEnvironment: [
        "HONKSHOOL_UI_TEST_PLAN_NOW": "", "HONKSHOOL_UI_TEST_ALARM": "not-determined",
      ], largestText: true)
    reviewAndConfirm(in: app)
    app.buttons["startNapRun"].tap()
    XCTAssertTrue(app.buttons["continueAlarmAccess"].waitForExistence(timeout: 5))
    XCUIDevice.shared.press(.home)
    let until = Date.now.addingTimeInterval(65)
    let elapsed = XCTNSPredicateExpectation(
      predicate: NSPredicate { _, _ in Date.now >= until }, object: nil)
    XCTAssertEqual(XCTWaiter.wait(for: [elapsed], timeout: 70), .completed)
    app.activate()
    XCTAssertTrue(app.buttons["reviewUpdatedNapTiming"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["continueAlarmAccess"].exists)
    XCTAssertFalse(app.buttons["startNapRun"].exists)
    XCTAssertFalse(app.staticTexts["napRunStatus"].exists)
    XCTAssertFalse(app.buttons["cancelNapPlanAlarm"].exists)
    capture("Expired primer at largest text", in: app)
    scrollTo(app.buttons["reviewUpdatedNapTiming"], in: app)
    XCTAssertTrue(app.buttons["reviewUpdatedNapTiming"].isHittable)
    capture("Expired timing recovery action at largest text", in: app)
  }

  func testUnverifiedRetainedAlarmDoesNotClaimItIsSet() {
    let app = launchReview()
    reviewAndConfirm(in: app)
    app.buttons["startNapRun"].tap()
    XCTAssertTrue(app.staticTexts["napRunStatus"].waitForExistence(timeout: 5))
    let stop = app.buttons["stopNapRun"]
    scrollTo(stop, in: app)
    stop.tap()
    app.terminate()
    app.launchEnvironment["HONKSHOOL_UI_TEST_RESET"] = "0"
    app.launchEnvironment["HONKSHOOL_UI_TEST_ALARM"] = "read-failure"
    app.launch()
    XCTAssertTrue(app.buttons["cancelNapPlanAlarm"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["We couldn’t check\nyour wake alarm."].exists)
    XCTAssertFalse(app.staticTexts["Your alarm\nis still set."].exists)
    XCTAssertFalse(app.buttons["startNapRun"].exists)
    XCTAssertFalse(app.buttons["reviewNapPlan"].exists)
    capture("Unverified retained alarm", in: app)
    let retry = app.buttons["retryNapPlanAlarmCheck"]
    scrollTo(retry, in: app)
    retry.tap()
    XCTAssertTrue(app.staticTexts["We couldn’t check\nyour wake alarm."].exists)
    XCTAssertTrue(app.buttons["cancelNapPlanAlarm"].exists)
  }

  private func reviewAndConfirm(in app: XCUIApplication) {
    let review = app.buttons["reviewNapPlan"]
    scrollTo(review, in: app)
    review.tap()
    let confirm = app.buttons["confirmNapPlan"]
    scrollTo(confirm, in: app)
    confirm.tap()
  }

  private func capture(_ name: String, in app: XCUIApplication) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  private func launchReview(
    additionalEnvironment: [String: String] = [:], largestText: Bool = false
  ) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing"]
    if largestText {
      app.launchArguments += [
        "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
      ]
    }
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
    XCTAssertTrue(app.navigationBars["Honkshool"].waitForExistence(timeout: 5))
    if additionalEnvironment["HONKSHOOL_UI_TEST_SEED_HISTORY"] == "1" {
      let acknowledge = app.buttons["acknowledgeRecoveredRest"]
      XCTAssertTrue(acknowledge.waitForExistence(timeout: 5))
      acknowledge.tap()
    }
    XCTAssertTrue(app.buttons["reviewNapPlan"].waitForExistence(timeout: 5))
    return app
  }

  private func chooseDuration(_ minutes: Int, in app: XCUIApplication) {
    openTimeOptions(in: app)
    app.buttons["napPlanDuration"].tap()
    app.buttons["\(minutes) minutes"].tap()
    app.buttons["applyNapTime"].tap()
  }

  private func openTimeOptions(in app: XCUIApplication) {
    let options = app.buttons["napPlanTimeOptions"]
    scrollTo(options, in: app)
    options.tap()
  }

  private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
    func visibleBounds() -> (top: CGFloat, bottom: CGFloat) {
      let top =
        app.navigationBars.allElementsBoundByIndex
        .filter(\.isHittable).map { $0.frame.maxY }.max() ?? app.frame.minY
      let bottom =
        ["reviewNapPlan", "applyNapTime", "applyNapSound", "startNapRun"]
        .filter { $0 != element.identifier }.map { app.buttons[$0] }
        .filter { $0.exists && $0.isHittable }.map { $0.frame.minY }.min() ?? app.frame.maxY
      return (top, bottom)
    }
    func isFullyReachable() -> Bool {
      guard element.exists, element.isHittable else { return false }
      let bounds = visibleBounds()
      return element.frame.minY >= bounds.top && element.frame.maxY < bounds.bottom
    }
    // Large text can make a switch hittable while its tap point is under a
    // navigation bar or pinned Apply button. Small drags avoid skipping the
    // usable viewport when a tall row needs to be brought completely into view.
    for _ in 0..<24 {
      if isFullyReachable() { return }
      let above = element.exists && element.frame.minY < visibleBounds().top
      let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
      let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: above ? 0.68 : 0.32))
      start.press(forDuration: 0.01, thenDragTo: end)
    }
    XCTAssertTrue(isFullyReachable(), "Element is not fully reachable: \(element.identifier)")
  }
}
