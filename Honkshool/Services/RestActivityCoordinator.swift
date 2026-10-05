import ActivityKit
import Combine
import Foundation

@MainActor
protocol RestActivityManaging {
  var isEnabled: Bool { get }
  var activities: [RestActivityRecord] { get }
  func request(
    attributes: RestActivityAttributes, state: RestActivityAttributes.ContentState
  ) throws -> String
  func update(id: String, state: RestActivityAttributes.ContentState) async
  func end(id: String) async
}

struct RestActivityRecord: Equatable {
  let id: String
  let attributes: RestActivityAttributes
  let state: RestActivityAttributes.ContentState
}

@MainActor
private struct SystemRestActivityManager: RestActivityManaging {
  var isEnabled: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

  var activities: [RestActivityRecord] {
    Activity<RestActivityAttributes>.activities.map {
      RestActivityRecord(id: $0.id, attributes: $0.attributes, state: $0.content.state)
    }
  }

  func request(
    attributes: RestActivityAttributes, state: RestActivityAttributes.ContentState
  ) throws -> String {
    let content = ActivityContent(state: state, staleDate: attributes.deadline)
    return try Activity<RestActivityAttributes>.request(
      attributes: attributes, content: content, pushType: nil
    ).id
  }

  func update(id: String, state: RestActivityAttributes.ContentState) async {
    guard let activity = Activity<RestActivityAttributes>.activities.first(where: { $0.id == id })
    else { return }
    await activity.update(ActivityContent(state: state, staleDate: activity.attributes.deadline))
  }

  func end(id: String) async {
    guard let activity = Activity<RestActivityAttributes>.activities.first(where: { $0.id == id })
    else { return }
    await activity.end(nil, dismissalPolicy: .immediate)
  }
}

/// The decision is independent of ActivityKit and never derives alarm proof from
/// the plan's wake-alarm preference alone.
enum RestActivityPolicy {
  struct Input {
    let planID: String
    let start: Date
    let deadline: Date
    let phase: NapRunPhase
    let hasPassedPlaybackAdmission: Bool
    let wasAdmitted: Bool
    let receipt: ScheduledNapAlarm?
    let alarmStatus: NapAlarmStatus
    let now: Date
  }

  struct Snapshot: Equatable {
    let attributes: RestActivityAttributes
    let state: RestActivityAttributes.ContentState
  }

  static func snapshot(_ input: Input) -> Snapshot? {
    guard input.deadline > input.now else { return nil }
    let verifiedAlarm =
      input.receipt?.planID == input.planID
      && input.receipt?.deadline == input.deadline
      && input.alarmStatus.phase == .scheduled
      && input.alarmStatus.nextAlertDate == input.deadline

    let playback: RestActivityAttributes.PlaybackStatus
    switch input.phase {
    case .narrating: playback = .narrating
    case .ambience: playback = .ambience
    case .resting where input.hasPassedPlaybackAdmission: playback = .resting
    case .paused where input.wasAdmitted || input.hasPassedPlaybackAdmission: playback = .paused
    case .interrupted where input.wasAdmitted || input.hasPassedPlaybackAdmission:
      playback = .interrupted
    case .stopped where input.wasAdmitted && verifiedAlarm: playback = .stopped
    case .idle where input.wasAdmitted && verifiedAlarm: playback = .stopped
    default: return nil
    }

    let alarm: RestActivityAttributes.AlarmStatus
    if verifiedAlarm {
      alarm = .scheduled
    } else if input.receipt?.planID == input.planID
      && input.receipt?.deadline == input.deadline
    {
      switch input.alarmStatus.phase {
      case .none: alarm = .none
      case .scheduled, .unavailable: alarm = .unknown
      case .snoozed: alarm = .snoozed
      case .paused: alarm = .paused
      case .alerting: alarm = .alerting
      }
    } else {
      alarm = .none
    }
    let attributes = RestActivityAttributes(
      planID: input.planID, start: input.start, deadline: input.deadline)
    let state = RestActivityAttributes.ContentState(
      countdownStart: input.start, deadline: input.deadline, playback: playback, alarm: alarm)
    return Snapshot(attributes: attributes, state: state)
  }
}

/// Serializes ActivityKit mutations; each queued pass reads current app state
/// after its predecessor finishes, so older async updates cannot win over Stop.
@MainActor
final class RestActivityCoordinator: ObservableObject {
  @Published private(set) var availabilityMessage: String?

  private let run: NapRunController
  private let alarm: NapPlanAlarmService
  private let manager: any RestActivityManaging
  private let now: () -> Date
  private var subscriptions = Set<AnyCancellable>()
  private var pending: Task<Void, Never>?
  private var generation = 0

  convenience init(run: NapRunController, alarm: NapPlanAlarmService) {
    self.init(run: run, alarm: alarm, manager: SystemRestActivityManager(), now: { .now })
  }

  init(
    run: NapRunController, alarm: NapPlanAlarmService,
    manager: any RestActivityManaging, now: @escaping () -> Date
  ) {
    self.run = run
    self.alarm = alarm
    self.manager = manager
    self.now = now
    run.$phase.combineLatest(run.$presentationPlan)
      .sink { [weak self] _, _ in self?.reconcile() }
      .store(in: &subscriptions)
    alarm.$alarmStatus.sink { [weak self] _ in self?.reconcile() }
      .store(in: &subscriptions)
    reconcile()
  }

  func reconcile() {
    generation += 1
    let requestedGeneration = generation
    let predecessor = pending
    pending = Task { [weak self] in
      await predecessor?.value
      guard let self, self.generation == requestedGeneration else { return }
      await self.applyCurrentState(generation: requestedGeneration)
    }
  }

  func waitForPendingWork() async { await pending?.value }

  private func applyCurrentState(generation requestedGeneration: Int) async {
    let current = manager.activities
    let date = now()
    let plan = run.presentationPlan
    let receipt = alarm.trackedReceipt
    let retained = current.first { activity in
      if let plan {
        return activity.attributes.planID == plan.id
          && activity.attributes.start == plan.start
          && activity.attributes.deadline == plan.deadline
      }
      return receipt?.planID == activity.attributes.planID
        && receipt?.deadline == activity.attributes.deadline
    }
    let source =
      plan.map {
        (
          $0.id, $0.start, $0.deadline, run.phase, run.hasPassedPlaybackAdmission,
          retained != nil
        )
      }
      ?? retained.map {
        (
          $0.attributes.planID, $0.attributes.start, $0.attributes.deadline, NapRunPhase.idle,
          false, true
        )
      }
    let desired = source.flatMap { source in
      let (planID, start, deadline, phase, passedAdmission, admitted) = source
      return RestActivityPolicy.snapshot(
        .init(
          planID: planID, start: start, deadline: deadline, phase: phase,
          hasPassedPlaybackAdmission: passedAdmission, wasAdmitted: admitted,
          receipt: alarm.trackedReceipt,
          alarmStatus: alarm.alarmStatus, now: date))
    }

    for activity in current
    where activity.id != retained?.id
      || desired?.attributes != activity.attributes
    {
      await manager.end(id: activity.id)
    }
    guard generation == requestedGeneration else { return }
    guard let desired else {
      availabilityMessage = nil
      return
    }
    if let retained, retained.attributes == desired.attributes {
      if retained.state != desired.state {
        await manager.update(id: retained.id, state: desired.state)
      }
      availabilityMessage = nil
      return
    }
    guard manager.isEnabled else {
      availabilityMessage = "Lock Screen countdown is unavailable. Rest continues in the app."
      return
    }
    guard desired.attributes.deadline.timeIntervalSince(date) <= 8 * 60 * 60 else {
      availabilityMessage = "This rest is too long for a Lock Screen countdown."
      return
    }
    #if DEBUG
      guard !UITestFixtures.isEnabled else {
        availabilityMessage = nil
        return
      }
    #endif
    do {
      _ = try manager.request(attributes: desired.attributes, state: desired.state)
      availabilityMessage = nil
    } catch {
      availabilityMessage = "Lock Screen countdown could not start. Rest continues in the app."
    }
  }
}
