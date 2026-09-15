import SwiftUI

struct AlarmLockScreenPresentation {
  enum Mode {
    case countdown(startDate: Date, fireDate: Date)
    case paused
    case alert
    case fallback
  }

  let mode: Mode
}

struct AlarmLockScreenLayout<CancelControl: View>: View {
  let presentation: AlarmLockScreenPresentation
  private let cancelControl: CancelControl

  init(
    presentation: AlarmLockScreenPresentation,
    @ViewBuilder cancelControl: () -> CancelControl
  ) {
    self.presentation = presentation
    self.cancelControl = cancelControl()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 8) {
        Label("Honkshool", systemImage: "alarm")
          .font(.headline)
        Spacer(minLength: 8)
        cancelControl
      }
      AlarmLockScreenStatus(presentation: presentation)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
  }
}

private struct AlarmLockScreenStatus: View {
  let presentation: AlarmLockScreenPresentation

  var body: some View {
    switch presentation.mode {
    case .countdown(let startDate, let fireDate):
      VStack(alignment: .leading, spacing: 2) {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
          Text("Snoozed")
            .font(.headline)
          Spacer(minLength: 8)
          Text(timerInterval: startDate...fireDate, countsDown: true)
            .font(.title.monospacedDigit())
        }
        Text("Next alert \(fireDate, style: .time)")
      }
    case .paused:
      Text("Snooze paused")
    case .alert:
      Text("Rest complete")
    case .fallback:
      Text("Check Honkshool for alarm status")
    }
  }
}
