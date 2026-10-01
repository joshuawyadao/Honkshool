import UIKit
import XCTest

final class AccessibilityRefreshUITests: XCTestCase {
  override func setUpWithError() throws { continueAfterFailure = false }

  func testLargestTextDurationChoicesAndSoundDescriptions() {
    let app = launch(largestText: true)
    let review = app.buttons["reviewNapPlan"]
    XCTAssertTrue(review.waitForExistence(timeout: 5))
    XCTAssertTrue(review.isHittable)
    assertSingleLinePresets("napPlanPreset", in: app)
    capture("AX5 Rest duration choices")
    app.buttons["napPlanPreset-60"].tap()
    XCTAssertTrue(app.buttons["napPlanPreset-60"].isSelected)
    app.buttons["napPlanPreset-30"].tap()
    XCTAssertTrue(app.buttons["napPlanPreset-30"].isSelected)
    let options = app.buttons["napPlanTimeOptions"]
    scrollTo(options, in: app)
    options.tap()
    assertSingleLinePresets("napTimePreset", in: app)
    capture("AX5 Time duration choices")
    app.buttons["napTimePreset-60"].tap()
    XCTAssertTrue(app.buttons["napTimePreset-60"].isSelected)
    app.buttons["napTimePreset-45"].tap()
    XCTAssertTrue(app.buttons["napTimePreset-45"].isSelected)
    app.buttons["applyNapTime"].tap()
    XCTAssertTrue(app.buttons["napPlanPreset-45"].isSelected)

    scrollTo(app.buttons["napPlanSound"], in: app)
    app.buttons["napPlanSound"].tap()
    let silence = app.buttons["Silence"]
    scrollTo(silence, in: app)
    XCTAssertEqual(silence.label, "Silence. The default. Nothing more to hear.")
    XCTAssertTrue(silence.isSelected)
    let rain = app.buttons["Gentle rain"]
    scrollTo(rain, in: app)
    XCTAssertEqual(rain.label, "Gentle rain. A soft, steady background.")
    rain.tap()
    XCTAssertTrue(rain.isSelected)
    XCTAssertFalse(silence.isSelected)
    capture("AX5 Sound descriptions and selection")
    app.buttons["applyNapSound"].tap()
    XCTAssertTrue(app.buttons["reviewNapPlan"].isHittable)
  }

  func testLargestTextTimingSurvivesReviewConfirmationAndStart() {
    let app = launch(largestText: true)
    XCTAssertTrue(app.buttons["reviewNapPlan"].waitForExistence(timeout: 5))
    app.buttons["reviewNapPlan"].tap()
    let deadline = app.staticTexts["napPlanDeadline"]
    scrollTo(deadline, in: app)
    let originalDeadline = deadline.label
    XCTAssertTrue(originalDeadline.hasPrefix("Fixed wake deadline, "))
    XCTAssertFalse(originalDeadline.contains("\n"), "A date remains one spoken value")
    let plannedStart = app.staticTexts["napPlanPlannedStart"]
    scrollTo(plannedStart, in: app)
    let originalStart = plannedStart.label
    XCTAssertTrue(originalStart.hasPrefix("Planned rest start, "))
    capture("AX5 Review full timing")
    scrollTo(app.staticTexts["napPlanAlarmChoice"], in: app)
    XCTAssertEqual(app.staticTexts["napPlanAlarmChoice"].label, "Wake alarm, Requested at deadline")
    capture("AX5 Review alarm metadata")
    scrollTo(app.buttons["confirmNapPlan"], in: app)
    app.buttons["confirmNapPlan"].tap()
    XCTAssertTrue(app.buttons["startNapRun"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["startNapRun"].isHittable)
    let confirmedDeadline = app.staticTexts["napPlanConfirmedDeadline"]
    scrollTo(confirmedDeadline, in: app)
    XCTAssertEqual(confirmedDeadline.label, originalDeadline)
    let confirmedStart = app.staticTexts["napPlanConfirmedStart"]
    scrollTo(confirmedStart, in: app)
    XCTAssertEqual(confirmedStart.label, originalStart)
    capture("AX5 Ready full timing")
    app.buttons["startNapRun"].tap()
    XCTAssertTrue(app.staticTexts["napRunStatus"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["napPlanConfirmedDeadline"].label, originalDeadline)
    XCTAssertEqual(app.staticTexts["napPlanConfirmedStart"].label, originalStart)
    scrollTo(app.buttons["stopNapRun"], in: app)
    app.buttons["stopNapRun"].tap()
  }

  func testRepeatedActionsIdentifyTheirContentAndHistoryDate() {
    var app = launch(largestText: false)
    XCTAssertTrue(app.buttons["napPlanContent"].waitForExistence(timeout: 5))
    app.buttons["napPlanContent"].tap()
    for (id, title) in [
      ("turning-fuel-into-motion", "Turning Fuel Into Motion"),
      ("air-fuel-and-spark", "Air, Fuel, and Spark"),
    ] {
      let choose = app.buttons["chooseSession-\(id)"]
      scrollTo(choose, in: app)
      XCTAssertEqual(choose.label, "Choose this session: \(title)")
      let detail = app.buttons["sessionDetails-\(id)"]
      scrollTo(detail, in: app)
      XCTAssertEqual(detail.label, "About this session: \(title)")
    }
    capture("Contextual session actions")
    app.terminate()
    app = launch(largestText: false, seedHistory: true)
    XCTAssertTrue(app.tabBars.buttons["History"].waitForExistence(timeout: 5))
    app.tabBars.buttons["History"].tap()
    let next = app.buttons["historyContinue"]
    scrollTo(next, in: app)
    XCTAssertTrue(
      next.label.hasPrefix("Continue listening: Turning Fuel Into Motion, last played "))
    let resume = app.buttons["historyResume"]
    scrollTo(resume, in: app)
    let resumePrefix = "Resume from 2m 0s in Turning Fuel Into Motion, "
    XCTAssertTrue(resume.label.hasPrefix(resumePrefix))
    XCTAssertGreaterThan(resume.label.count, resumePrefix.count + 8)
    let replay = app.buttons["historyReplay"]
    scrollTo(replay, in: app)
    let replayPrefix = "Replay from start: Turning Fuel Into Motion, "
    XCTAssertTrue(replay.label.hasPrefix(replayPrefix))
    XCTAssertEqual(
      String(resume.label.dropFirst(resumePrefix.count)),
      String(replay.label.dropFirst(replayPrefix.count)))
    capture("Contextual history actions")
  }

  private func assertSingleLinePresets(_ prefix: String, in app: XCUIApplication) {
    let lineHeight = UIFont.preferredFont(
      forTextStyle: .body,
      compatibleWith: UITraitCollection(
        preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
    ).lineHeight
    for minutes in [20, 30, 45, 60] {
      let button = app.buttons["\(prefix)-\(minutes)"]
      scrollTo(button, in: app)
      XCTAssertEqual(app.buttons.matching(identifier: "\(prefix)-\(minutes)").count, 1)
      XCTAssertEqual(button.label, "\(minutes) minutes")
      // Two-line digits measured almost twice this height in the original audit.
      XCTAssertLessThan(button.frame.height, lineHeight * 1.5, "Duration digits must stay together")
      XCTAssertGreaterThanOrEqual(button.frame.height, 44)
    }
  }

  private func launch(largestText: Bool, seedHistory: Bool = false) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing"]
    if largestText {
      app.launchArguments += [
        "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
      ]
    }
    app.launchEnvironment = [
      "HONKSHOOL_UI_TEST_RESET": "1", "HONKSHOOL_UI_TEST_AUDIO": "1",
      "HONKSHOOL_UI_TEST_ALARM": "authorized",
      "HONKSHOOL_UI_TEST_SEED_HISTORY": seedHistory ? "1" : "0",
      "HONKSHOOL_UI_TEST_PLAN_NOW": String(
        Date.now.addingTimeInterval(86_400).timeIntervalSince1970),
    ]
    app.launch()
    return app
  }

  private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
    for _ in 0..<16 {
      // Keep the gesture inside content rather than the pinned primary action.
      var bottom = app.frame.height - 140
      for id in ["reviewNapPlan", "startNapRun", "applyNapTime", "applyNapSound"] {
        let button = app.buttons[id]
        if button.exists && button.isHittable { bottom = min(bottom, button.frame.minY - 30) }
      }
      let top: CGFloat = 145
      bottom = max(top + 80, bottom)
      // A sheet control can report hittable while its tap point is below the
      // pinned footer. Its center must reach the usable content viewport.
      let frame = element.exists ? element.frame : nil
      if let frame, element.isHittable, (top...bottom).contains(frame.midY) { return }
      let scrollBack = frame.map { $0.midY < top } ?? false
      let origin = app.coordinate(withNormalizedOffset: .zero)
      origin.withOffset(CGVector(dx: app.frame.width * 0.7, dy: scrollBack ? top : bottom))
        .press(
          forDuration: 0.05,
          thenDragTo: origin.withOffset(
            CGVector(dx: app.frame.width * 0.7, dy: scrollBack ? bottom : top)))
    }
    XCTFail("Element is not reachable: \(element)")
  }

  private func capture(_ name: String) {
    let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
