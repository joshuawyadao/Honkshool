import ActivityKit
import AlarmKit
import Combine
import SwiftUI

struct SystemAlarmRecord: Equatable {
  let id: UUID
  let state: Alarm.State
  let originalDate: Date?
  let countdownFireDate: Date?
}

struct NapAlarmStatus: Equatable {
  enum Phase: String {
    case none = "No alarm"
    case scheduled = "Scheduled"
    case snoozed = "Snoozed"
    case paused = "Snooze paused"
    case alerting = "Ringing"
    case unavailable = "Status unavailable"
  }

  var phase: Phase = .none
  var nextAlertDate: Date?
}

@MainActor
protocol AlarmSystem {
  var authorization: AlarmAuthorizationSnapshot { get }
  func requestAuthorization() async throws -> AlarmAuthorizationSnapshot
  func alarms() throws -> [SystemAlarmRecord]
  func schedule(id: UUID, at date: Date) async throws
  func cancel(id: UUID) throws
  func updates() -> AsyncStream<Void>
}

@MainActor
final class AppleAlarmSystem: AlarmSystem {
  private let manager = AlarmManager.shared

  var authorization: AlarmAuthorizationSnapshot {
    Self.snapshot(manager.authorizationState)
  }

  func requestAuthorization() async throws -> AlarmAuthorizationSnapshot {
    Self.snapshot(try await manager.requestAuthorization())
  }

  func alarms() throws -> [SystemAlarmRecord] {
    let activities = Activity<AlarmAttributes<HonkshoolAlarmMetadata>>.activities
    return try manager.alarms.map { alarm in
      var fireDate: Date?
      // Alarm.schedule remains the original date after snoozing. ActivityKit
      // supplies the actual countdown deadline, including after app relaunch.
      if let activity = activities.first(where: { $0.content.state.alarmID == alarm.id }),
        case .countdown(let countdown) = activity.content.state.mode
      {
        fireDate = countdown.fireDate
      }
      let originalDate: Date?
      if case .fixed(let date) = alarm.schedule {
        originalDate = date
      } else {
        originalDate = nil
      }
      return SystemAlarmRecord(
        id: alarm.id, state: alarm.state,
        originalDate: originalDate, countdownFireDate: fireDate
      )
    }
  }

  func schedule(id: UUID, at date: Date) async throws {
    let alert: AlarmPresentation.Alert
    let snooze = AlarmButton(text: "Snooze", textColor: .white, systemImageName: "zzz")
    if #available(iOS 26.1, *) {
      alert = AlarmPresentation.Alert(
        title: "Honkshool rest complete",
        secondaryButton: snooze, secondaryButtonBehavior: .countdown
      )
    } else {
      alert = AlarmPresentation.Alert(
        title: "Honkshool rest complete",
        stopButton: AlarmButton(text: "Stop", textColor: .white, systemImageName: "stop.fill"),
        secondaryButton: snooze, secondaryButtonBehavior: .countdown
      )
    }
    let presentation = AlarmPresentation(
      alert: alert,
      countdown: AlarmPresentation.Countdown(title: "Honkshool snoozed"),
      paused: AlarmPresentation.Paused(
        title: "Honkshool snooze paused",
        resumeButton: AlarmButton(text: "Resume", textColor: .white, systemImageName: "play.fill")
      )
    )
    let configuration = AlarmManager.AlarmConfiguration(
      countdownDuration: Alarm.CountdownDuration(
        preAlert: nil, postAlert: HonkshoolAlarmMetadata.snoozeSeconds
      ),
      schedule: .fixed(date),
      attributes: AlarmAttributes(
        presentation: presentation,
        metadata: HonkshoolAlarmMetadata(source: "feasibility-spike"),
        tintColor: .indigo
      ),
      sound: .default
    )
    _ = try await manager.schedule(id: id, configuration: configuration)
  }

  func cancel(id: UUID) throws {
    try manager.cancel(id: id)
  }

  func updates() -> AsyncStream<Void> {
    AsyncStream { continuation in
      let task = Task { @MainActor [manager] in
        for await _ in manager.alarmUpdates {
          guard !Task.isCancelled else { break }
          continuation.yield(())
        }
        continuation.finish()
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  private static func snapshot(_ state: AlarmManager.AuthorizationState)
    -> AlarmAuthorizationSnapshot
  {
    switch state {
    case .notDetermined: .notDetermined
    case .denied: .denied
    case .authorized: .authorized
    @unknown default: .notDetermined
    }
  }
}

@MainActor
final class AlarmSpikeService: ObservableObject {
  @Published private(set) var authorization: AlarmAuthorizationSnapshot
  @Published private(set) var alarmStatus = NapAlarmStatus()
  @Published private(set) var statusMessage = "AlarmKit authorization has not been checked yet."
  @Published private(set) var isScheduling = false

  private let system: any AlarmSystem
  private let defaults: UserDefaults
  private let now: () -> Date
  private let storedAlarmIDKey = "feasibilityAlarmID"
  private let storedAlarmDateKey = "feasibilityAlarmDate"
  private var scheduledAlarmID: UUID?

  init(
    system: (any AlarmSystem)? = nil,
    defaults: UserDefaults = .standard,
    now: @escaping () -> Date = { .now }
  ) {
    let system = system ?? AppleAlarmSystem()
    self.system = system
    self.defaults = defaults
    self.now = now
    authorization = system.authorization
    if let rawID = defaults.string(forKey: storedAlarmIDKey) {
      scheduledAlarmID = UUID(uuidString: rawID)
    }
    // Restored dates are never presented as current before system reconciliation.
    refresh()
  }

  var hasTrackedAlarm: Bool { scheduledAlarmID != nil }
  var scheduledDate: Date? { alarmStatus.nextAlertDate }

  var scheduleSnapshot: AlarmScheduleSnapshot {
    guard alarmStatus.phase == .scheduled, let scheduledDate else { return .notScheduled }
    return .scheduled(scheduledDate)
  }

  func observeUpdates() async {
    for await _ in system.updates() {
      guard !Task.isCancelled else { break }
      refresh()
    }
  }

  func refresh() {
    let latestAuthorization = system.authorization
    if authorization != latestAuthorization { authorization = latestAuthorization }
    // A schedule call can emit updates before it returns its new ID.
    guard !isScheduling else { return }
    do {
      let alarms = try system.alarms()
      guard let id = scheduledAlarmID else {
        setStatus(NapAlarmStatus(), message: authorizationMessage)
        return
      }
      guard let alarm = alarms.first(where: { $0.id == id }) else {
        clearStoredAlarm()
        setStatus(NapAlarmStatus(), message: "The Honkshool alarm is no longer active.")
        return
      }

      let status: NapAlarmStatus
      let message: String
      switch alarm.state {
      case .scheduled:
        status = NapAlarmStatus(phase: .scheduled, nextAlertDate: alarm.originalDate)
        message = "System wake alarm scheduled. Snooze lasts nine minutes."
      case .countdown:
        status = NapAlarmStatus(phase: .snoozed, nextAlertDate: alarm.countdownFireDate)
        message =
          alarm.countdownFireDate == nil
          ? "Snoozed. The system countdown is active; its exact next alert time is not available yet."
          : "Snoozed. The next alert time below comes from the system countdown."
      case .paused:
        status = NapAlarmStatus(phase: .paused)
        message = "The snooze countdown is paused. Resume it from the system alarm controls."
      case .alerting:
        status = NapAlarmStatus(phase: .alerting)
        message = "The alarm is ringing. Stop or snooze it using the system controls."
      @unknown default:
        status = NapAlarmStatus(phase: .unavailable)
        message = "The system returned an unfamiliar alarm state. Cancellation is still available."
      }
      setStatus(status, message: message)
    } catch {
      setStatus(
        NapAlarmStatus(phase: .unavailable),
        message:
          "Could not refresh the system alarm. Its last identity is retained so cancellation can be retried."
      )
    }
  }

  func requestAuthorization() async {
    do {
      authorization = try await system.requestAuthorization()
      refresh()
    } catch {
      statusMessage = "AlarmKit authorization failed: \(error.localizedDescription)"
    }
  }

  @discardableResult
  func schedule(at date: Date) async -> Bool {
    guard !isScheduling else { return false }
    authorization = system.authorization
    guard authorization == .authorized else {
      statusMessage = "Authorize AlarmKit before scheduling an alarm."
      return false
    }
    guard date > now() else {
      statusMessage = "Choose a future alarm time."
      return false
    }

    isScheduling = true
    defer { isScheduling = false }
    if hasTrackedAlarm && !cancel() { return false }

    let id = UUID()
    // Persist before awaiting, so a system-scheduled alarm can be reconciled
    // even if this process is terminated as schedule() returns.
    scheduledAlarmID = id
    defaults.set(id.uuidString, forKey: storedAlarmIDKey)
    defaults.set(date.timeIntervalSince1970, forKey: storedAlarmDateKey)
    do {
      try await system.schedule(id: id, at: date)
      setStatus(
        NapAlarmStatus(phase: .scheduled, nextAlertDate: date),
        message: "System alarm scheduled. Snooze lasts nine minutes."
      )
      return true
    } catch {
      // A failed request may have an uncertain system outcome. Keep its ID
      // until a refresh confirms absence or cancellation succeeds.
      setStatus(
        NapAlarmStatus(phase: .unavailable),
        message:
          "Alarm scheduling failed; playback remains blocked. Refresh or cancel before retrying."
      )
      return false
    }
  }

  @discardableResult
  func cancel() -> Bool {
    guard let id = scheduledAlarmID else { return true }
    do {
      try system.cancel(id: id)
      clearStoredAlarm()
      setStatus(NapAlarmStatus(), message: "Honkshool alarm cancelled, including any snooze.")
      return true
    } catch {
      statusMessage = "Alarm cancellation failed. The alarm may still ring; retry cancellation."
      return false
    }
  }

  private var authorizationMessage: String {
    switch authorization {
    case .authorized: "Authorized. No Honkshool alarm is scheduled."
    case .denied: "Alarm access denied. Authorize in Settings or explicitly disable the wake alarm."
    case .notDetermined: "Authorize AlarmKit before starting an alarm-enabled test."
    }
  }

  private func setStatus(_ status: NapAlarmStatus, message: String) {
    if alarmStatus != status { alarmStatus = status }
    if statusMessage != message { statusMessage = message }
  }

  private func clearStoredAlarm() {
    scheduledAlarmID = nil
    defaults.removeObject(forKey: storedAlarmIDKey)
    defaults.removeObject(forKey: storedAlarmDateKey)
  }
}
