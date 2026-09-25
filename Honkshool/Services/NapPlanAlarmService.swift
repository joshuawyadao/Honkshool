import AlarmKit
import Combine
import Foundation

struct ScheduledNapAlarm: Codable, Equatable {
  let planID: String
  let id: UUID
  let deadline: Date
}

/// Owns the system alarm for a confirmed plan. Its persisted identity survives
/// an uncertain AlarmKit result so the person can retry cancellation.
@MainActor
final class NapPlanAlarmService: ObservableObject {
  @Published private(set) var authorization: AlarmAuthorizationSnapshot
  @Published private(set) var alarmStatus = NapAlarmStatus()
  @Published private(set) var statusMessage = "Checking the wake alarm."
  @Published private(set) var isScheduling = false

  private let system: any AlarmSystem
  private let defaults: UserDefaults
  private let now: () -> Date
  private let receiptKey = "napPlanAlarmReceipt"
  private var tracked: ScheduledNapAlarm?

  init(
    system: (any AlarmSystem)? = nil,
    defaults: UserDefaults? = nil,
    now: @escaping () -> Date = { .now }
  ) {
    let system = system ?? Self.defaultSystem()
    let defaults = defaults ?? SpikePreferences.defaults
    self.system = system
    self.defaults = defaults
    self.now = now
    authorization = system.authorization
    if let data = defaults.data(forKey: receiptKey) {
      tracked = try? JSONDecoder().decode(ScheduledNapAlarm.self, from: data)
    }
    refresh()
  }

  private static func defaultSystem() -> any AlarmSystem {
    #if DEBUG
      if let fixture = UITestFixtures.makeAlarmSystem() { return fixture }
    #endif
    return AppleAlarmSystem(source: "nap-plan")
  }

  var hasTrackedAlarm: Bool { tracked != nil || defaults.object(forKey: receiptKey) != nil }
  var canCancelTrackedAlarm: Bool { tracked != nil }
  var needsCountdownReconciliation: Bool {
    hasTrackedAlarm && alarmStatus.phase == .snoozed && alarmStatus.nextAlertDate == nil
  }

  func reconcileCountdown(
    wait: (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
  ) async {
    var attempts = 0
    while needsCountdownReconciliation && !Task.isCancelled {
      do { try await wait(.seconds(attempts < 5 ? 1 : 30)) } catch { return }
      guard needsCountdownReconciliation && !Task.isCancelled else { return }
      refresh()
      attempts += 1
    }
  }

  func observeUpdates() async {
    for await _ in system.updates() {
      guard !Task.isCancelled else { break }
      refresh()
    }
  }

  /// A receipt is only usable while the exact one-shot alarm remains scheduled
  /// for this plan's immutable deadline.
  func isScheduled(_ receipt: ScheduledNapAlarm) -> Bool {
    refresh()
    guard authorization == .authorized, tracked == receipt,
      alarmStatus.phase == .scheduled,
      alarmStatus.nextAlertDate == receipt.deadline,
      receipt.deadline > now()
    else { return false }
    return true
  }

  func refresh() {
    authorization = system.authorization
    // AlarmKit may emit an update before schedule() returns. That pending ID
    // must not be treated as absent during the scheduling operation.
    guard !isScheduling else { return }
    guard let tracked else {
      if hasTrackedAlarm {
        do {
          if try system.alarms().isEmpty {
            clearTracked()
            setStatus(
              .init(),
              message:
                "Unreadable wake alarm details were cleared after the system reported no active alarms."
            )
          } else {
            setStatus(
              .init(phase: .unavailable),
              message:
                "Saved wake alarm details are unreadable. Clear Honkshool alarms in system controls, then reopen the app."
            )
          }
        } catch {
          setStatus(
            .init(phase: .unavailable),
            message:
              "Could not check alarms with unreadable saved details. Retry when system alarms are available."
          )
        }
      } else {
        setStatus(.init(), message: authorizationMessage)
      }
      return
    }
    do {
      let alarms = try system.alarms()
      guard let alarm = alarms.first(where: { $0.id == tracked.id }) else {
        // During an in-flight schedule we defer refresh above. Once it returns,
        // the system's alarm list is authoritative for this app-owned ID.
        clearTracked()
        setStatus(.init(), message: "The Honkshool wake alarm is no longer active.")
        return
      }
      switch alarm.state {
      case .scheduled:
        guard alarm.originalDate == tracked.deadline else {
          setStatus(
            .init(phase: .unavailable),
            message: "The wake alarm deadline does not match this plan. Cancel it before retrying.")
          return
        }
        setStatus(
          .init(phase: .scheduled, nextAlertDate: alarm.originalDate),
          message: "System wake alarm scheduled. Snooze lasts nine minutes.")
      case .countdown:
        setStatus(
          .init(phase: .snoozed, nextAlertDate: alarm.countdownFireDate),
          message: "Wake alarm snoozed. Its countdown is managed by the system.")
      case .paused:
        setStatus(.init(phase: .paused), message: "Wake alarm snooze paused in system controls.")
      case .alerting:
        setStatus(.init(phase: .alerting), message: "Wake alarm is ringing in system controls.")
      @unknown default:
        setStatus(
          .init(phase: .unavailable),
          message: "System wake alarm state is unavailable. Cancellation remains available.")
      }
    } catch {
      setStatus(
        .init(phase: .unavailable),
        message: "Could not verify the wake alarm. Its identity is retained for cancellation.")
    }
  }

  func schedule(for plan: NapPlan) async -> ScheduledNapAlarm? {
    guard !isScheduling else { return nil }
    guard !hasTrackedAlarm else {
      statusMessage = "Cancel the existing Honkshool wake alarm before scheduling another."
      return nil
    }
    guard let wakeAlarm = plan.wakeAlarm, wakeAlarm == plan.deadline,
      plan.deadline > now(), plan.start >= now()
    else {
      statusMessage = "This plan needs a future wake deadline before an alarm can be scheduled."
      return nil
    }

    isScheduling = true
    defer { isScheduling = false }
    authorization = system.authorization
    if authorization == .notDetermined {
      do {
        authorization = try await system.requestAuthorization()
      } catch {
        statusMessage = "Wake alarm authorization could not be completed."
        return nil
      }
    }
    // Authorization and time can change while the system prompt is open.
    authorization = system.authorization
    guard authorization == .authorized else {
      statusMessage = "Allow Honkshool alarms in Settings before starting this plan."
      return nil
    }
    guard plan.deadline > now(), plan.start >= now() else {
      statusMessage = "The plan's start or wake deadline has passed. Review a new plan."
      return nil
    }

    let receipt = ScheduledNapAlarm(planID: plan.id, id: UUID(), deadline: plan.deadline)
    guard persist(receipt) else {
      statusMessage = "Could not save the wake alarm identity. Playback remains blocked."
      return nil
    }
    do {
      try await system.schedule(id: receipt.id, at: receipt.deadline)
    } catch {
      setStatus(
        .init(phase: .unavailable),
        message:
          "Wake alarm scheduling failed or is uncertain. Playback remains blocked; cancel or refresh before retrying."
      )
      return nil
    }

    // Verify the exact system alarm; a successful call alone is not proof that
    // the intended future deadline is armed when playback begins.
    authorization = system.authorization
    guard authorization == .authorized, plan.deadline > now(), plan.start >= now() else {
      setStatus(
        .init(phase: .unavailable),
        message:
          "The plan or alarm authorization changed while scheduling. Review and cancel before retrying."
      )
      return nil
    }
    do {
      let alarms = try system.alarms()
      guard let alarm = alarms.first(where: { $0.id == receipt.id }),
        alarm.state == .scheduled, alarm.originalDate == receipt.deadline
      else {
        setStatus(
          .init(phase: .unavailable),
          message: "Could not verify the planned wake alarm. Playback remains blocked.")
        return nil
      }
    } catch {
      setStatus(
        .init(phase: .unavailable),
        message: "Could not read the scheduled wake alarm. Its identity is retained.")
      return nil
    }
    setStatus(
      .init(phase: .scheduled, nextAlertDate: receipt.deadline),
      message: "System wake alarm scheduled. Snooze lasts nine minutes.")
    return receipt
  }

  @discardableResult
  func cancel() -> Bool {
    guard !isScheduling else {
      statusMessage =
        "Wake alarm scheduling is still in progress. Retry cancellation when it finishes."
      return false
    }
    guard let tracked else {
      if hasTrackedAlarm {
        statusMessage =
          "Wake alarm identity is unreadable. Clear Honkshool alarms in system controls and reopen the app."
        return false
      }
      return true
    }
    do {
      try system.cancel(id: tracked.id)
      clearTracked()
      setStatus(.init(), message: "Honkshool wake alarm cancelled, including any snooze.")
      return true
    } catch {
      setStatus(
        .init(phase: .unavailable),
        message: "Wake alarm cancellation failed. It may still ring; retry cancellation.")
      return false
    }
  }

  private var authorizationMessage: String {
    switch authorization {
    case .authorized: "Authorized. No Honkshool wake alarm is scheduled."
    case .denied: "Alarm access denied. Allow Honkshool alarms in Settings."
    case .notDetermined: "Alarm access will be requested before an alarm-enabled plan starts."
    }
  }

  private func persist(_ receipt: ScheduledNapAlarm) -> Bool {
    guard let data = try? JSONEncoder().encode(receipt) else { return false }
    defaults.set(data, forKey: receiptKey)
    tracked = receipt
    return true
  }

  private func clearTracked() {
    tracked = nil
    defaults.removeObject(forKey: receiptKey)
  }

  private func setStatus(_ status: NapAlarmStatus, message: String) {
    if alarmStatus != status { alarmStatus = status }
    if statusMessage != message { statusMessage = message }
  }
}
