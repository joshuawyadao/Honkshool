import XCTest

@testable import Honkshool

final class SpikeModelsTests: XCTestCase {
  private let now = Date(timeIntervalSince1970: 1_000)

  func testAlarmDisabledRunIsReadyWithoutAuthorizationOrSchedule() {
    let result = FeasibilityRunGate.evaluate(
      alarmEnabled: false,
      authorization: .denied,
      schedule: .notScheduled,
      now: now
    )

    XCTAssertEqual(result, .ready)
  }

  func testAlarmEnabledRunRequiresAuthorization() {
    let result = FeasibilityRunGate.evaluate(
      alarmEnabled: true,
      authorization: .denied,
      schedule: .notScheduled,
      now: now
    )

    XCTAssertEqual(
      result,
      .blocked(
        "Alarm-enabled runs require AlarmKit authorization before playback starts."
      )
    )
  }

  func testAlarmEnabledRunRequiresFutureScheduledAlarm() {
    let result = FeasibilityRunGate.evaluate(
      alarmEnabled: true,
      authorization: .authorized,
      schedule: .scheduled(now),
      now: now
    )

    XCTAssertEqual(
      result,
      .blocked(
        "Alarm-enabled runs require a successfully scheduled future alarm."
      )
    )
  }

  func testAlarmEnabledRunIsReadyAfterSuccessfulSchedule() {
    let result = FeasibilityRunGate.evaluate(
      alarmEnabled: true,
      authorization: .authorized,
      schedule: .scheduled(now.addingTimeInterval(60)),
      now: now
    )

    XCTAssertEqual(result, .ready)
  }

  func testNarrationTransitionUsesSelectedFallback() {
    XCTAssertEqual(
      PlaybackTransitionPolicy.destinationAfterNarration(ambienceEnabled: true),
      .ambience
    )
    XCTAssertEqual(
      PlaybackTransitionPolicy.destinationAfterNarration(ambienceEnabled: false),
      .silence
    )
  }

  func testInterruptionPolicyWaitsForManualResumeAfterSystemInterruption() {
    XCTAssertEqual(
      SpikeInterruptionPolicy.action(for: .began),
      .pause
    )
    XCTAssertEqual(
      SpikeInterruptionPolicy.action(for: .ended(systemSuggestsResume: true)),
      .waitForManualResume
    )
    XCTAssertEqual(
      SpikeInterruptionPolicy.action(for: .outputRouteDisconnected),
      .pause
    )
  }

  func testRestDurationPolicyClampsCustomDurations() {
    XCTAssertEqual(RestDurationPolicy.normalized(minutes: 1), 5)
    XCTAssertEqual(RestDurationPolicy.normalized(minutes: 35), 35)
    XCTAssertEqual(RestDurationPolicy.normalized(minutes: 300), 180)
  }

  func testWakeDateUsesTheWholeRestWindow() {
    let wakeDate = RestDurationPolicy.wakeDate(startingAt: now, minutes: 35)

    XCTAssertEqual(wakeDate.timeIntervalSince(now), 35 * 60)
  }
}
