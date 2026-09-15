import SwiftUI
import XCTest

@MainActor
final class AlarmLockScreenLayoutTests: XCTestCase {
  func testSnoozedLayoutFitsLockScreenHeightAtLargerTextSizes() throws {
    let startDate = Date(timeIntervalSince1970: 1_000)
    let presentation = AlarmLockScreenPresentation(
      mode: .countdown(startDate: startDate, fireDate: startDate.addingTimeInterval(540))
    )

    for localeIdentifier in ["en_US", "en_GB"] {
      for timeZoneOffset in [0, -7 * 3_600, 12 * 3_600] {
        for dynamicTypeSize in [
          DynamicTypeSize.xLarge, .xxLarge, .xxxLarge, .accessibility1,
        ] {
          let height = try renderedHeight(
            for: presentation, dynamicTypeSize: dynamicTypeSize,
            localeIdentifier: localeIdentifier, timeZoneOffset: timeZoneOffset
          )
          XCTAssertLessThanOrEqual(
            height, 160,
            "Snoozed layout measured \(height) points at \(dynamicTypeSize), \(localeIdentifier), UTC offset \(timeZoneOffset)."
          )
        }
      }
    }
  }

  func testOtherAlarmStatesFitLockScreenHeightAtLargerTextSize() throws {
    for (name, mode) in [
      ("paused", AlarmLockScreenPresentation.Mode.paused),
      ("alert", .alert),
      ("fallback", .fallback),
    ] {
      let height = try renderedHeight(
        for: AlarmLockScreenPresentation(mode: mode),
        dynamicTypeSize: .accessibility1
      )
      XCTAssertLessThanOrEqual(
        height,
        160,
        "The \(name) layout measured \(height) points."
      )
    }
  }

  private func renderedHeight(
    for presentation: AlarmLockScreenPresentation,
    dynamicTypeSize: DynamicTypeSize,
    localeIdentifier: String = "en_US",
    timeZoneOffset: Int = 0
  ) throws -> CGFloat {
    let content = AlarmLockScreenLayout(presentation: presentation) {
      Button(action: {}) {
        Label("Cancel", systemImage: "xmark.circle")
      }
      .buttonStyle(.bordered)
      .controlSize(.small)
      .accessibilityLabel("Cancel alarm")
    }
    .environment(\.dynamicTypeSize, dynamicTypeSize)
    .environment(\.locale, Locale(identifier: localeIdentifier))
    .environment(\.timeZone, TimeZone(secondsFromGMT: timeZoneOffset)!)

    let renderer = ImageRenderer(content: content)
    renderer.scale = 1
    renderer.proposedSize = ProposedViewSize(width: 371, height: nil)
    return try XCTUnwrap(renderer.uiImage).size.height
  }
}
