import SwiftUI

/// This countdown describes the fixed rest window. It does not claim that
/// audio is audible or that a system alarm has been delivered. State labels
/// describe the last app update; external changes can precede reconciliation.
struct RestCountdownPresentation {
  let state: RestActivityAttributes.ContentState
  let isStale: Bool

  var playbackLabel: String {
    guard !isStale else { return "Rest window ended" }
    switch state.playback {
    case .narrating: return "Narration started"
    case .ambience: return "Rest sound started"
    case .resting: return "Quiet rest started"
    case .paused: return "Playback was paused"
    case .interrupted: return "Playback was interrupted"
    case .stopped: return "Rest stopped"
    }
  }

  var alarmLabel: String {
    guard !isStale else { return "Check wake alarm in app" }
    switch state.alarm {
    case .none: return "No wake alarm"
    case .scheduled: return "Wake alarm was set"
    case .snoozed: return "Wake alarm was snoozed"
    case .paused: return "Wake alarm was paused"
    case .alerting: return "Wake alarm was alerting"
    case .unknown: return "Wake alarm unverified"
    }
  }
}

struct RestCountdownTimer: View {
  let presentation: RestCountdownPresentation

  var body: some View {
    if presentation.isStale {
      Text("0:00").monospacedDigit()
    } else {
      Text(
        timerInterval: presentation.state.countdownStart...presentation.state.deadline,
        countsDown: true
      )
      .monospacedDigit()
    }
  }
}

/// The compact Island gives its trailing region a much narrower slot than the
/// expanded view. Keep the same native, ticking interval while fitting the
/// longest hour-based countdown on one line at large text settings.
struct RestCompactCountdownTimer: View {
  let presentation: RestCountdownPresentation

  var body: some View {
    RestCountdownTimer(presentation: presentation)
      .font(.system(size: 11, weight: .semibold))
      .monospacedDigit()
      .lineLimit(1)
      .minimumScaleFactor(0.8)
      .frame(width: 52, alignment: .trailing)
      .multilineTextAlignment(.trailing)
  }
}

struct RestCountdownLayout: View {
  @ScaledMetric(relativeTo: .title) private var timerWidth = 140
  let presentation: RestCountdownPresentation

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(alignment: .firstTextBaseline, spacing: 12) {
        Label("Rest", systemImage: "moon")
          .font(.headline)
        Spacer(minLength: 8)
        RestCountdownTimer(presentation: presentation)
          .font(.title.monospacedDigit())
          // WidgetKit archives timers as flexible text; never request intrinsic size.
          .frame(width: min(timerWidth, 190), alignment: .trailing)
          .multilineTextAlignment(.trailing)
      }
      RestCountdownEnding(deadline: presentation.state.deadline)
        .font(.subheadline)
      Text(presentation.playbackLabel)
        .font(.subheadline)
      Text(presentation.alarmLabel)
        .font(.footnote)
    }
    // The Lock Screen host is at most 160pt tall. Keep every status visible;
    // larger settings remain fully supported by the uncapped in-app Rest page.
    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    .padding(.horizontal, 14)
    .padding(.vertical, 6)
  }
}

struct RestCountdownEnding: View {
  @Environment(\.calendar) private var calendar
  @Environment(\.timeZone) private var timeZone
  let deadline: Date

  var body: some View {
    let localCalendar = calendarWithLocalTime
    if localCalendar.isDate(deadline, inSameDayAs: .now) {
      Text("Ends at \(deadline, style: .time)")
    } else {
      Text("Ends \(deadline, format: .dateTime.month(.abbreviated).day().hour().minute())")
    }
  }

  private var calendarWithLocalTime: Calendar {
    var local = calendar
    local.timeZone = timeZone
    return local
  }
}
