import SwiftUI

/// This countdown describes the fixed rest window. It does not claim that
/// audio is audible or that a system alarm has been delivered.
struct RestCountdownPresentation {
  let state: RestActivityAttributes.ContentState
  let isStale: Bool

  var playbackLabel: String {
    guard !isStale else { return "Rest window ended" }
    switch state.playback {
    case .narrating: return "Narrated rest"
    case .ambience: return "Rest with sound"
    case .resting: return "Quiet rest"
    case .paused: return "Playback paused"
    case .interrupted: return "Playback interrupted"
    case .stopped: return "Playback stopped"
    }
  }

  var alarmLabel: String {
    guard !isStale else { return "Check wake alarm in app" }
    switch state.alarm {
    case .none: return "No wake alarm"
    case .scheduled: return "Wake alarm set"
    case .snoozed: return "Wake alarm snoozed"
    case .paused: return "Wake alarm paused"
    case .alerting: return "Wake alarm alerting"
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

struct RestCountdownLayout: View {
  let presentation: RestCountdownPresentation

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(alignment: .firstTextBaseline, spacing: 12) {
        Label("Rest", systemImage: "moon")
          .font(.headline)
        Spacer(minLength: 8)
        RestCountdownTimer(presentation: presentation)
          .font(.title.monospacedDigit())
          .fixedSize()
      }
      RestCountdownEnding(deadline: presentation.state.deadline)
        .font(.subheadline)
      Text(presentation.playbackLabel)
        .font(.subheadline)
      Text(presentation.alarmLabel)
        .font(.footnote)
    }
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
