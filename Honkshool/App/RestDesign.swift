import SwiftUI

struct RestCard<Content: View>: View {
  private let title: String?
  private let systemImage: String?
  private let content: Content

  init(
    title: String? = nil, systemImage: String? = nil,
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.systemImage = systemImage
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      if let title {
        Group {
          if let systemImage {
            Label(title, systemImage: systemImage)
          } else {
            Text(title)
          }
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(RestStyle.secondary)
      }
      content
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(20)
    .background(RestStyle.surface, in: RoundedRectangle(cornerRadius: RestStyle.cardRadius))
  }
}

struct RestHeading: View {
  let title: String
  let subtitle: String?

  init(_ title: String, subtitle: String? = nil) {
    self.title = title
    self.subtitle = subtitle
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(.system(.largeTitle, design: .rounded).weight(.medium))
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityAddTraits(.isHeader)
      if let subtitle {
        Text(subtitle)
          .foregroundStyle(RestStyle.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

struct GooseMark: View {
  var size: CGFloat = 44

  var body: some View {
    Image("ThoughtGoose")
      .resizable()
      .scaledToFit()
      .frame(width: size, height: size)
      .clipShape(RoundedRectangle(cornerRadius: size * 0.25))
      .accessibilityHidden(true)
  }
}

/// A static thought-bubble signature. Never animate it to invite attention.
struct ThoughtDots: View {
  var body: some View {
    HStack(alignment: .bottom, spacing: 6) {
      Circle().frame(width: 8, height: 8)
      Circle().frame(width: 14, height: 14)
    }
    .foregroundStyle(RestStyle.secondary.opacity(0.6))
    .padding(.vertical, 16)
    .accessibilityHidden(true)
  }
}

struct RestButtonStyle: ButtonStyle {
  var secondary = false
  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.body.weight(.medium))
      .multilineTextAlignment(.center)
      .frame(maxWidth: .infinity, minHeight: 28)
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .foregroundStyle(secondary ? RestStyle.ink : RestStyle.onAccent)
      .background(
        secondary ? RestStyle.well : RestStyle.accent,
        in: RoundedRectangle(cornerRadius: 18)
      )
      .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.45)
  }
}

private struct RestScreen: ViewModifier {
  func body(content: Content) -> some View {
    content
      .foregroundStyle(RestStyle.ink)
      .tint(RestStyle.ink)
      .background(RestStyle.background)
      .toolbarBackground(RestStyle.background, for: .navigationBar)
  }
}

extension View {
  func restScreen() -> some View { modifier(RestScreen()) }
}
