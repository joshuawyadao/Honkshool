import UIKit
import Vision
import XCTest

/// Exercises WidgetKit hosting rather than rendering the view inside the app.
final class RestLiveActivityUITests: XCTestCase {
  func testSystemHostedSilentRestCountdownIsVisible() throws {
    #if targetEnvironment(simulator)
      guard ProcessInfo.processInfo.environment["HONKSHOOL_HOSTED_ACTIVITY_TEST"] == "1" else {
        throw XCTSkip("Run only on an isolated simulator with the hosted-activity opt-in.")
      }
    #else
      throw XCTSkip("This test never starts a rest on the owner's phone.")
    #endif
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launch()
    if app.buttons["dismissQuietWelcome"].waitForExistence(timeout: 3) {
      app.buttons["dismissQuietWelcome"].tap()
    }
    let start = app.buttons["startRestTimer"]
    XCTAssertTrue(start.waitForExistence(timeout: 5))
    scrollTo(app.buttons["timerSilence"], in: app)
    app.buttons["timerSilence"].tap()
    let alarm = app.switches["timerWakeAlarm"]
    scrollTo(alarm, in: app)
    if alarm.value as? String == "1" {
      let native = alarm.switches.firstMatch.exists ? alarm.switches.firstMatch : alarm
      native.tap()
    }
    XCTAssertEqual(alarm.value as? String, "0")
    addTeardownBlock {
      app.activate()
      let stop = app.buttons["stopNapRun"]
      if stop.waitForExistence(timeout: 2) {
        self.scrollTo(stop, in: app)
        stop.tap()
      }
    }
    start.tap()
    XCTAssertTrue(app.staticTexts["napRunStatus"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["napRunStatus"].label.contains("silence"))
    XCTAssertFalse(app.staticTexts["restActivityAvailability"].exists)

    XCUIDevice.shared.press(.home)
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.01))
      .press(
        forDuration: 0.1,
        thenDragTo: springboard.coordinate(
          withNormalizedOffset: CGVector(dx: 0.2, dy: 0.8)))
    let allow = springboard.buttons.matching(
      NSPredicate(
        format: "label IN %@", ["Allow", "Always Allow"])
    ).firstMatch
    if allow.waitForExistence(timeout: 3) { allow.tap() }
    let restLabel = springboard.staticTexts["Rest"]
    XCTAssertTrue(restLabel.waitForExistence(timeout: 10))
    XCTAssertTrue(springboard.staticTexts["Quiet rest started"].exists)
    XCTAssertTrue(springboard.staticTexts["No wake alarm"].exists)
    let screenshot = springboard.screenshot()
    let shot = XCTAttachment(screenshot: screenshot)
    shot.name = "System-hosted rest countdown"
    shot.lifetime = .keepAlways
    add(shot)
    try assertRenderedCountdown(screenshot.image)
  }

  private func assertRenderedCountdown(_ image: UIImage) throws {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.recognitionLanguages = ["en-US"]
    // Exclude the Lock Screen clock: accessibility can expose text that was
    // archived but failed to paint, so verify the actual hosted pixels too.
    request.regionOfInterest = CGRect(x: 0, y: 0.05, width: 1, height: 0.55)
    try VNImageRequestHandler(cgImage: XCTUnwrap(image.cgImage)).perform([request])
    let lines = request.results?.compactMap { $0.topCandidates(1).first?.string } ?? []
    let text = lines.joined(separator: "\n")
    XCTAssertTrue(text.contains("Quiet rest"), text)
    XCTAssertTrue(text.contains("No wake alarm"), text)
    XCTAssertTrue(
      lines.contains {
        $0.range(of: #"^\d{1,2}:\d{2}(:\d{2})?$"#, options: .regularExpression) != nil
      }, "No visible remaining countdown: \(text)")
  }

  private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
    for _ in 0..<8 {
      if element.isHittable { return }
      app.swipeUp()
    }
  }
}
