import SwiftUI

/// Quiet curiosity is the default across current and future screens.
/// See docs/Design-Language.md before introducing visual exceptions.
enum RestStyle {
  static let background = adaptive(0xF6F2EA, 0x091A35)
  static let surface = adaptive(0xFFFDFA, 0x142944)
  static let well = adaptive(0xEAE5DC, 0x203752)
  static let ink = adaptive(0x172B49, 0xF5F0E7)
  static let secondary = adaptive(0x53637A, 0xB4C1D4)
  static let quiet = adaptive(0xE3EAF0, 0x203B58)
  static let accent = Color(red: 225 / 255, green: 176 / 255, blue: 102 / 255)
  static let onAccent = Color(red: 21 / 255, green: 40 / 255, blue: 68 / 255)
  // Small error text must remain readable on every rest surface in both appearances.
  static let error = adaptive(0xA53C34, 0xF2AAA0)
  static let pageInset: CGFloat = 20
  static let cardRadius: CGFloat = 24

  private static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
    Color(
      uiColor: UIColor { traits in
        let value = traits.userInterfaceStyle == .dark ? dark : light
        return UIColor(
          red: CGFloat((value >> 16) & 255) / 255,
          green: CGFloat((value >> 8) & 255) / 255,
          blue: CGFloat(value & 255) / 255, alpha: 1)
      })
  }
}
