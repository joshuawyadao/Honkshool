import AlarmKit
import Combine
import SwiftUI

struct HonkshoolAlarmMetadata: AlarmMetadata {
  let source: String
}

@MainActor
final class AlarmSpikeService: ObservableObject {
  @Published private(set) var authorization: AlarmAuthorizationSnapshot
  @Published private(set) var scheduledDate: Date?
  @Published private(set) var statusMessage: String

  private let manager = AlarmManager.shared
  private let defaults = UserDefaults.standard
  private let storedAlarmIDKey = "feasibilityAlarmID"
  private let storedAlarmDateKey = "feasibilityAlarmDate"
  private var scheduledAlarmID: UUID?

  init() {
    authorization = Self.snapshot(for: AlarmManager.shared.authorizationState)
    statusMessage = "AlarmKit authorization has not been checked yet."

    if let rawID = defaults.string(forKey: storedAlarmIDKey),
      let id = UUID(uuidString: rawID)
    {
      scheduledAlarmID = id
      let timeInterval = defaults.double(forKey: storedAlarmDateKey)
      if timeInterval > 0 {
        scheduledDate = Date(timeIntervalSince1970: timeInterval)
      }
    }
  }

  var scheduleSnapshot: AlarmScheduleSnapshot {
    guard let scheduledDate else { return .notScheduled }
    return .scheduled(scheduledDate)
  }

  func refresh() {
    authorization = Self.snapshot(for: manager.authorizationState)

    do {
      let alarms = try manager.alarms
      let previouslyTrackedAnAlarm = scheduledAlarmID != nil
      guard
        let scheduledAlarmID,
        let alarm = alarms.first(where: { $0.id == scheduledAlarmID })
      else {
        clearStoredAlarm()
        if previouslyTrackedAnAlarm {
          statusMessage =
            "The previously tracked alarm is no longer active; it may have fired or been stopped."
        } else if authorization == .authorized {
          statusMessage = "Authorized. No Honkshool test alarm is scheduled."
        }
        return
      }

      if case .fixed(let date) = alarm.schedule {
        scheduledDate = date
        statusMessage = "A Honkshool test alarm is scheduled."
      }
    } catch {
      statusMessage = "Could not read scheduled alarms: \(error.localizedDescription)"
    }
  }

  func requestAuthorization() async {
    do {
      let result = try await manager.requestAuthorization()
      authorization = Self.snapshot(for: result)
      statusMessage =
        switch authorization {
        case .authorized: "AlarmKit authorization granted."
        case .denied: "AlarmKit authorization denied. Alarm-enabled runs are blocked."
        case .notDetermined: "AlarmKit authorization remains undecided."
        }
    } catch {
      statusMessage = "AlarmKit authorization failed: \(error.localizedDescription)"
    }
  }

  @discardableResult
  func schedule(at date: Date) async -> Bool {
    authorization = Self.snapshot(for: manager.authorizationState)

    guard authorization == .authorized else {
      statusMessage = "Authorize AlarmKit before scheduling an alarm."
      scheduledDate = nil
      return false
    }

    guard date > .now else {
      statusMessage = "Choose a future alarm time."
      scheduledDate = nil
      return false
    }

    cancelExistingAlarmIfNeeded()

    let id = UUID()
    let alert: AlarmPresentation.Alert
    if #available(iOS 26.1, *) {
      alert = AlarmPresentation.Alert(
        title: "Honkshool rest complete",
        secondaryButton: AlarmButton(
          text: "Snooze",
          textColor: .white,
          systemImageName: "zzz"
        ),
        secondaryButtonBehavior: .countdown
      )
    } else {
      alert = AlarmPresentation.Alert(
        title: "Honkshool rest complete",
        stopButton: AlarmButton(
          text: "Stop",
          textColor: .white,
          systemImageName: "stop.fill"
        ),
        secondaryButton: AlarmButton(
          text: "Snooze",
          textColor: .white,
          systemImageName: "zzz"
        ),
        secondaryButtonBehavior: .countdown
      )
    }
    let presentation = AlarmPresentation(alert: alert)
    let attributes = AlarmAttributes(
      presentation: presentation,
      metadata: HonkshoolAlarmMetadata(source: "feasibility-spike"),
      tintColor: .indigo
    )
    let configuration = AlarmManager.AlarmConfiguration(
      countdownDuration: Alarm.CountdownDuration(
        preAlert: nil,
        postAlert: 9 * 60
      ),
      schedule: .fixed(date),
      attributes: attributes,
      sound: .default
    )

    do {
      _ = try await manager.schedule(id: id, configuration: configuration)
      scheduledAlarmID = id
      scheduledDate = date
      defaults.set(id.uuidString, forKey: storedAlarmIDKey)
      defaults.set(date.timeIntervalSince1970, forKey: storedAlarmDateKey)
      statusMessage =
        "System alarm scheduled for \(date.formatted(date: .omitted, time: .shortened))."
      return true
    } catch {
      clearStoredAlarm()
      statusMessage =
        "Alarm scheduling failed; playback remains blocked: \(error.localizedDescription)"
      return false
    }
  }

  func cancel() {
    guard let scheduledAlarmID else {
      scheduledDate = nil
      statusMessage = "No Honkshool test alarm is scheduled."
      return
    }

    do {
      try manager.cancel(id: scheduledAlarmID)
      statusMessage = "Honkshool test alarm cancelled."
    } catch {
      statusMessage = "Alarm cancellation reported: \(error.localizedDescription)"
    }

    clearStoredAlarm()
  }

  private func cancelExistingAlarmIfNeeded() {
    guard let scheduledAlarmID else { return }
    try? manager.cancel(id: scheduledAlarmID)
    clearStoredAlarm()
  }

  private func clearStoredAlarm() {
    scheduledAlarmID = nil
    scheduledDate = nil
    defaults.removeObject(forKey: storedAlarmIDKey)
    defaults.removeObject(forKey: storedAlarmDateKey)
  }

  private static func snapshot(
    for state: AlarmManager.AuthorizationState
  ) -> AlarmAuthorizationSnapshot {
    switch state {
    case .notDetermined: .notDetermined
    case .denied: .denied
    case .authorized: .authorized
    @unknown default: .notDetermined
    }
  }
}
