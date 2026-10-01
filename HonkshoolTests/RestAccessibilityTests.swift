import SwiftUI
import UIKit
import XCTest

@testable import Honkshool

final class RestAccessibilityTests: XCTestCase {
  @MainActor
  func testErrorTextContrastOnEveryRestSurfaceAndAppearance() throws {
    let surfaces: [(String, Color)] = [
      ("background", RestStyle.background), ("card", RestStyle.surface),
      ("well", RestStyle.well), ("quiet notice", RestStyle.quiet),
    ]
    var measurements: [String] = []
    for appearance in [UIUserInterfaceStyle.light, .dark] {
      for contrast in [UIAccessibilityContrast.normal, .high] {
        let traits = UITraitCollection {
          $0.userInterfaceStyle = appearance
          $0.accessibilityContrast = contrast
        }
        let foreground = try luminance(UIColor(RestStyle.error).resolvedColor(with: traits))
        for (name, color) in surfaces {
          let background = try luminance(UIColor(color).resolvedColor(with: traits))
          let ratio = (max(foreground, background) + 0.05) / (min(foreground, background) + 0.05)
          let context = "\(appearance.rawValue)/\(contrast.rawValue) \(name)"
          measurements.append("\(context): \(ratio)")
          XCTAssertGreaterThanOrEqual(ratio, 4.5, "Small error text: \(context)")
        }
      }
    }
    let attachment = XCTAttachment(string: measurements.joined(separator: "\n"))
    attachment.name = "Resolved semantic error contrast"
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  @MainActor
  func testHistoryOpenErrorRendersInBothAppearances() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let blockedDirectory = directory.appendingPathComponent("unavailable")
    try Data().write(to: blockedDirectory)
    let store = ListeningHistoryStore(
      storeURL: blockedDirectory.appendingPathComponent("history.sqlite"))
    XCTAssertTrue(
      try XCTUnwrap(store.errorMessage).hasPrefix("Listening history could not be opened:"))

    for appearance in [ColorScheme.light, .dark] {
      let content = ListeningHistoryView(
        store: store, canStart: false, isNarrationAvailable: { _ in false },
        reviewDestination: { _ in fatalError("Error-state rendering must not open a plan") }
      )
      .environment(\.colorScheme, appearance)
      .environment(\.dynamicTypeSize, .large)
      .frame(width: 375, height: 667)
      let scene = try XCTUnwrap(
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
      let previousWindow = scene.windows.first { $0.isKeyWindow }
      let window = UIWindow(windowScene: scene)
      window.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
      window.overrideUserInterfaceStyle = appearance == .dark ? .dark : .light
      let controller = UIHostingController(rootView: content)
      window.rootViewController = controller
      window.makeKeyAndVisible()
      defer {
        window.isHidden = true
        previousWindow?.makeKeyAndVisible()
      }
      // ScrollView content needs a hosted window and a rendered run-loop pass.
      try await Task.sleep(for: .milliseconds(200))
      controller.view.layoutIfNeeded()
      let rendered = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
        XCTAssertTrue(window.drawHierarchy(in: window.bounds, afterScreenUpdates: true))
      }
      let pixels = try XCTUnwrap(rendered.cgImage?.dataProvider?.data) as Data
      XCTAssertGreaterThan(Set(pixels).count, 16, "Reject an empty background-only rendering")
      XCTAssertEqual(rendered.size.width, 375)
      let attachment = XCTAttachment(image: rendered)
      attachment.name = "History storage error — \(appearance)"
      attachment.lifetime = .keepAlways
      add(attachment)
    }
  }

  @MainActor
  private func luminance(_ color: UIColor) throws -> CGFloat {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    XCTAssertTrue(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
    XCTAssertEqual(alpha, 1, "Contrast calculation requires opaque semantic colors")
    func linear(_ value: CGFloat) -> CGFloat {
      value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
  }
}
