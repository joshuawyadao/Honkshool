import SwiftUI
import XCTest

@testable import Honkshool

@MainActor
final class RestCountdownLayoutTests: XCTestCase {
  func testCountdownFitsLockScreenAtLargerTextSizes() throws {
    for size in [
      DynamicTypeSize.xLarge, .xxxLarge, .accessibility1, .accessibility2,
      .accessibility3, .accessibility4, .accessibility5,
    ] {
      for playback in [
        RestActivityAttributes.PlaybackStatus.narrating, .ambience, .resting,
        .paused, .interrupted, .stopped,
      ] {
        for isStale in [false, true] {
          let view = RestCountdownLayout(
            presentation: make(playback, isStale: isStale, alarm: .alerting)
          )
          .environment(\.dynamicTypeSize, size)
          .foregroundStyle(RestStyle.ink)
          .background(RestStyle.background)
          let renderer = ImageRenderer(content: view)
          renderer.scale = 1
          renderer.proposedSize = ProposedViewSize(width: 371, height: nil)
          let image = try XCTUnwrap(renderer.uiImage)
          let pixels = try XCTUnwrap(image.cgImage?.dataProvider?.data) as Data
          XCTAssertGreaterThan(Set(pixels).count, 16, "Reject a blank layout rendering")
          XCTAssertLessThanOrEqual(image.size.width, 371, "Host width at \(size)")
          XCTAssertLessThanOrEqual(image.size.height, 160, "Host height at \(size)")
          if playback == .paused && !isStale {
            let attachment = XCTAttachment(image: image)
            attachment.name = "Rest countdown — \(size)"
            attachment.lifetime = .keepAlways
            add(attachment)
          }
        }
      }
    }
  }

  func testPausedAndStoppedPlaybackKeepAlarmStatusDistinct() {
    XCTAssertEqual(make(.paused).playbackLabel, "Playback was paused")
    XCTAssertEqual(make(.interrupted).playbackLabel, "Playback was interrupted")
    XCTAssertEqual(make(.stopped).playbackLabel, "Playback stopped")
    XCTAssertEqual(make(.stopped).alarmLabel, "Wake alarm was set")
  }

  func testActiveModeLabelsReportStartEventsInsteadOfCurrentPlayback() {
    XCTAssertEqual(make(.narrating).playbackLabel, "Narration started")
    XCTAssertEqual(make(.ambience).playbackLabel, "Rest sound started")
    XCTAssertEqual(make(.resting).playbackLabel, "Quiet rest started")
  }

  func testAlarmLabelsDescribeTheLastReportedState() {
    for (alarm, expected) in [
      (RestActivityAttributes.AlarmStatus.scheduled, "Wake alarm was set"),
      (.snoozed, "Wake alarm was snoozed"),
      (.paused, "Wake alarm was paused"),
      (.alerting, "Wake alarm was alerting"),
    ] {
      let start = Date.now
      let presentation = RestCountdownPresentation(
        state: .init(
          countdownStart: start, deadline: start.addingTimeInterval(600),
          playback: .stopped, alarm: alarm), isStale: false)
      XCTAssertEqual(presentation.alarmLabel, expected, "State snapshot: \(alarm)")
    }
  }

  func testCrossDayEndingFitsWithLocaleAndTimeZoneVariants() throws {
    let start = Date.now.addingTimeInterval(24 * 60 * 60)
    let presentation = RestCountdownPresentation(
      state: .init(
        countdownStart: start, deadline: start.addingTimeInterval(600),
        playback: .stopped, alarm: .scheduled), isStale: false)
    for locale in ["en_US", "en_GB"] {
      for offset in [-7 * 3600, 0, 12 * 3600] {
        let view = RestCountdownLayout(presentation: presentation)
          .environment(\.dynamicTypeSize, .accessibility5)
          .environment(\.locale, Locale(identifier: locale))
          .environment(\.timeZone, TimeZone(secondsFromGMT: offset)!)
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = ProposedViewSize(width: 371, height: nil)
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.uiImage)
        XCTAssertLessThanOrEqual(image.size.width, 371)
        XCTAssertLessThanOrEqual(image.size.height, 160)
      }
    }
  }

  func testStaleCountdownDoesNotClaimAudioStoppedOrAlarmDelivered() {
    let stale = make(.ambience, isStale: true)
    XCTAssertEqual(stale.playbackLabel, "Rest window ended")
    XCTAssertEqual(stale.alarmLabel, "Check wake alarm in app")
  }

  private func make(
    _ playback: RestActivityAttributes.PlaybackStatus, isStale: Bool = false,
    alarm: RestActivityAttributes.AlarmStatus = .scheduled
  ) -> RestCountdownPresentation {
    let start = Date.now
    return RestCountdownPresentation(
      state: .init(
        countdownStart: start, deadline: start.addingTimeInterval(180 * 60),
        playback: playback, alarm: alarm),
      isStale: isStale)
  }
}
