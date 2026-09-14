import ActivityKit
import AlarmKit
import SwiftUI
import WidgetKit

@main
struct HonkshoolAlarmWidgets: WidgetBundle {
  var body: some Widget {
    HonkshoolAlarmActivity()
  }
}

struct HonkshoolAlarmActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: AlarmAttributes<HonkshoolAlarmMetadata>.self) { context in
      AlarmLockScreenLayout(presentation: AlarmLockScreenPresentation(state: context.state)) {
        Button(intent: CancelHonkshoolAlarmIntent(alarmID: context.state.alarmID.uuidString)) {
          Label("Cancel", systemImage: "xmark.circle")
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .accessibilityLabel("Cancel alarm")
      }
      .activityBackgroundTint(.indigo.opacity(0.15))
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label("Honkshool", systemImage: "alarm")
        }
        DynamicIslandExpandedRegion(.bottom) {
          AlarmCountdownContent(state: context.state)
          Button(intent: CancelHonkshoolAlarmIntent(alarmID: context.state.alarmID.uuidString)) {
            Text("Cancel alarm")
          }
        }
      } compactLeading: {
        Image(systemName: "zzz")
      } compactTrailing: {
        AlarmCountdownTimer(state: context.state)
          .frame(maxWidth: 60)
      } minimal: {
        Image(systemName: "alarm")
      }
    }
  }
}

extension AlarmLockScreenPresentation {
  fileprivate init(state: AlarmPresentationState) {
    switch state.mode {
    case .countdown(let countdown):
      self.init(
        mode: .countdown(startDate: countdown.startDate, fireDate: countdown.fireDate)
      )
    case .paused:
      self.init(mode: .paused)
    case .alert:
      self.init(mode: .alert)
    @unknown default:
      self.init(mode: .fallback)
    }
  }
}

private struct AlarmCountdownContent: View {
  let state: AlarmPresentationState

  var body: some View {
    switch state.mode {
    case .countdown(let countdown):
      Text("Snoozed")
        .font(.headline)
      HStack {
        Text("Next alert")
        Text(countdown.fireDate, style: .time)
      }
      AlarmCountdownTimer(state: state)
        .font(.title.monospacedDigit())
    case .paused:
      Text("Snooze paused")
    case .alert:
      Text("Rest complete")
    @unknown default:
      Text("Check Honkshool for alarm status")
    }
  }
}

private struct AlarmCountdownTimer: View {
  let state: AlarmPresentationState

  var body: some View {
    if case .countdown(let countdown) = state.mode {
      Text(timerInterval: countdown.startDate...countdown.fireDate, countsDown: true)
        .monospacedDigit()
    } else {
      Image(systemName: "alarm")
    }
  }
}
