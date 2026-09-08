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
      VStack(alignment: .leading, spacing: 10) {
        Label("Honkshool", systemImage: "alarm")
          .font(.headline)
        AlarmCountdownContent(state: context.state)
        Button(intent: CancelHonkshoolAlarmIntent(alarmID: context.state.alarmID.uuidString)) {
          Label("Cancel alarm", systemImage: "xmark.circle")
        }
        .buttonStyle(.bordered)
      }
      .padding()
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
