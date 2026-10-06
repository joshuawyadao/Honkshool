import AlarmKit
import Foundation
import XCTest

@testable import Honkshool

@MainActor
private final class RestActivityFakeAlarmSystem: AlarmSystem {
  var authorization: AlarmAuthorizationSnapshot = .authorized
  var records: [SystemAlarmRecord] = []
  func requestAuthorization() async throws -> AlarmAuthorizationSnapshot { authorization }
  func alarms() throws -> [SystemAlarmRecord] { records }
  func schedule(id: UUID, at date: Date) async throws {}
  func cancel(id: UUID) throws {}
  func updates() -> AsyncStream<Void> { AsyncStream { $0.finish() } }
}

@MainActor
private final class RestActivityFakeManager: RestActivityManaging {
  var isEnabled = true
  var activities: [RestActivityRecord] = []
  var requestFails = false
  var suspendUpdates = false
  private(set) var updateEntered = false
  private var updateContinuation: CheckedContinuation<Void, Never>?
  private(set) var requested = 0
  private(set) var ended = 0

  func request(
    attributes: RestActivityAttributes, state: RestActivityAttributes.ContentState
  ) throws -> String {
    if requestFails { throw NSError(domain: "test", code: 1) }
    requested += 1
    let id = UUID().uuidString
    activities.append(.init(id: id, attributes: attributes, state: state))
    return id
  }

  func update(id: String, state: RestActivityAttributes.ContentState) async {
    updateEntered = true
    if suspendUpdates {
      await withCheckedContinuation { updateContinuation = $0 }
    }
    guard let index = activities.firstIndex(where: { $0.id == id }) else { return }
    activities[index] = .init(id: id, attributes: activities[index].attributes, state: state)
  }

  func resumeUpdate() {
    updateContinuation?.resume()
    updateContinuation = nil
  }

  func end(id: String) async {
    ended += 1
    activities.removeAll { $0.id == id }
  }
}

@MainActor
final class RestActivityCoordinatorTests: XCTestCase {
  private let start = Date(timeIntervalSince1970: 1_800_000_000)

  private func snapshot(
    phase: NapRunPhase, admitted: Bool = false, receipt: ScheduledNapAlarm? = nil,
    alarmStatus: NapAlarmStatus = .init(), now: Date? = nil,
    passedAdmission: Bool = true
  ) -> RestActivityPolicy.Snapshot? {
    let deadline = start.addingTimeInterval(600)
    return RestActivityPolicy.snapshot(
      .init(
        planID: "plan", start: start, deadline: deadline, phase: phase,
        hasPassedPlaybackAdmission: passedAdmission, wasAdmitted: admitted,
        receipt: receipt, alarmStatus: alarmStatus,
        now: now ?? start.addingTimeInterval(20)))
  }

  func testOnlyStartedPlaybackAdmitsCardAndPauseKeepsFixedDeadline() {
    XCTAssertNil(snapshot(phase: .waiting))
    XCTAssertNil(snapshot(phase: .paused, passedAdmission: false))
    XCTAssertNil(snapshot(phase: .interrupted, passedAdmission: false))
    // A fast Pause/route interruption can arrive before ActivityKit's first request.
    XCTAssertEqual(snapshot(phase: .paused)?.state.playback, .paused)
    XCTAssertEqual(snapshot(phase: .interrupted)?.state.playback, .interrupted)
    XCTAssertNil(snapshot(phase: .resting, passedAdmission: false))
    for phase: NapRunPhase in [.narrating, .ambience, .resting] {
      XCTAssertNotNil(snapshot(phase: phase))
    }
    let paused = snapshot(phase: .paused, admitted: true)
    XCTAssertEqual(paused?.state.playback, .paused)
    XCTAssertEqual(paused?.state.deadline, start.addingTimeInterval(600))
    XCTAssertEqual(paused?.state.countdownStart, start)
    XCTAssertEqual(snapshot(phase: .interrupted, admitted: true)?.state.playback, .interrupted)
    XCTAssertNil(snapshot(phase: .resting, now: start.addingTimeInterval(600)))
  }

  func testStopAndRelaunchRequireExactVerifiedFutureAlarm() {
    let deadline = start.addingTimeInterval(600)
    let matching = ScheduledNapAlarm(planID: "plan", id: UUID(), deadline: deadline)
    let verified = NapAlarmStatus(phase: .scheduled, nextAlertDate: deadline)
    XCTAssertNil(snapshot(phase: .stopped, admitted: true))
    XCTAssertNil(
      snapshot(
        phase: .stopped, admitted: true, receipt: matching,
        alarmStatus: .init(phase: .scheduled, nextAlertDate: deadline.addingTimeInterval(60))))
    XCTAssertEqual(
      snapshot(
        phase: .stopped, admitted: true, receipt: matching,
        alarmStatus: verified)?.state.playback, .stopped)
    XCTAssertEqual(
      snapshot(
        phase: .idle, admitted: true, receipt: matching,
        alarmStatus: verified)?.state.alarm, .scheduled)
    let wrongPlan = ScheduledNapAlarm(planID: "other", id: matching.id, deadline: deadline)
    XCTAssertNil(
      snapshot(
        phase: .idle, admitted: true, receipt: wrongPlan, alarmStatus: verified))
  }

  func testCanceledAndUncertainAlarmNeverClaimScheduled() {
    let deadline = start.addingTimeInterval(600)
    let receipt = ScheduledNapAlarm(planID: "plan", id: UUID(), deadline: deadline)
    XCTAssertEqual(
      snapshot(phase: .resting, receipt: receipt)?.state.alarm,
      RestActivityAttributes.AlarmStatus.none)
    XCTAssertEqual(
      snapshot(
        phase: .resting, receipt: receipt,
        alarmStatus: .init(phase: .unavailable))?.state.alarm, .unknown)
    XCTAssertEqual(
      snapshot(
        phase: .resting, receipt: receipt,
        alarmStatus: .init(phase: .snoozed, nextAlertDate: deadline.addingTimeInterval(540)))?
        .state.alarm, .snoozed)
  }

  private func makeRun(now: @escaping @MainActor () -> Date) -> NapRunController {
    NapRunController(
      clock: now,
      scheduler: { _, _ in {} },
      activateAudioSession: {}, deactivateAudioSession: {},
      observeSystemEvents: false, manageRemoteCommands: false)
  }

  private func makeAlarm(
    receipt: ScheduledNapAlarm? = nil, now: @escaping () -> Date
  ) throws -> NapPlanAlarmService {
    let system = RestActivityFakeAlarmSystem()
    let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
    if let receipt {
      defaults.set(try JSONEncoder().encode(receipt), forKey: "napPlanAlarmReceipt")
      system.records = [
        SystemAlarmRecord(
          id: receipt.id, state: .scheduled,
          originalDate: receipt.deadline, countdownFireDate: nil)
      ]
    }
    return NapPlanAlarmService(system: system, defaults: defaults, now: now)
  }

  func testCoordinatorEndsAlarmFreeCardAfterStop() async throws {
    let date = start
    let run = makeRun(now: { date })
    let alarm = try makeAlarm(now: { date })
    let manager = RestActivityFakeManager()
    let coordinator = RestActivityCoordinator(
      run: run, alarm: alarm, manager: manager, now: { date })
    let plan = try NapPlanner.makeTimer(
      id: "plan", window: .duration(600), sound: .silence, alarmEnabled: false,
      now: date, availableAmbienceIDs: [])
    try run.startTimer(plan: plan)
    await coordinator.waitForPendingWork()
    XCTAssertEqual(manager.requested, 1)
    XCTAssertEqual(manager.activities.first?.state.playback, .resting)
    XCTAssertTrue(run.hasPassedPlaybackAdmission)
    run.stop()
    await coordinator.waitForPendingWork()
    XCTAssertTrue(manager.activities.isEmpty)
    XCTAssertEqual(manager.ended, 1)
  }

  func testDisabledAndFailedRequestsAreNonfatal() async throws {
    let date = start
    let run = makeRun(now: { date })
    let alarm = try makeAlarm(now: { date })
    let manager = RestActivityFakeManager()
    manager.isEnabled = false
    let coordinator = RestActivityCoordinator(
      run: run, alarm: alarm, manager: manager, now: { date })
    let plan = try NapPlanner.makeTimer(
      id: "plan", window: .duration(600), sound: .silence, alarmEnabled: false,
      now: date, availableAmbienceIDs: [])
    try run.startTimer(plan: plan)
    await coordinator.waitForPendingWork()
    XCTAssertNotNil(coordinator.availabilityMessage)
    XCTAssertTrue(manager.activities.isEmpty)
    manager.isEnabled = true
    manager.requestFails = true
    coordinator.reconcile()
    await coordinator.waitForPendingWork()
    XCTAssertNotNil(coordinator.availabilityMessage)
    XCTAssertEqual(run.phase, .resting)
  }

  func testDelayedUpdateCannotRestoreCardAfterStop() async throws {
    let date = start
    let run = makeRun(now: { date })
    let alarm = try makeAlarm(now: { date })
    let manager = RestActivityFakeManager()
    let plan = try NapPlanner.makeTimer(
      id: "plan", window: .duration(600), sound: .silence, alarmEnabled: false,
      now: date, availableAmbienceIDs: [])
    try run.startTimer(plan: plan)
    let attributes = RestActivityAttributes(planID: plan.id, start: date, deadline: plan.deadline)
    manager.activities = [
      .init(
        id: "existing", attributes: attributes,
        state: .init(
          countdownStart: date, deadline: plan.deadline, playback: .paused, alarm: .none))
    ]
    manager.suspendUpdates = true
    let coordinator = RestActivityCoordinator(
      run: run, alarm: alarm, manager: manager, now: { date })
    for _ in 0..<100 where !manager.updateEntered { await Task.yield() }
    XCTAssertTrue(manager.updateEntered)
    run.stop()
    manager.resumeUpdate()
    await coordinator.waitForPendingWork()
    XCTAssertTrue(manager.activities.isEmpty)
    XCTAssertEqual(manager.ended, 1)
  }

  func testRelaunchRetainsOneMatchingFutureAlarmAndDowngradesPlayback() async throws {
    let date = start
    let deadline = date.addingTimeInterval(600)
    let receipt = ScheduledNapAlarm(planID: "plan", id: UUID(), deadline: deadline)
    let alarm = try makeAlarm(receipt: receipt, now: { date })
    let run = makeRun(now: { date })
    let manager = RestActivityFakeManager()
    let matching = RestActivityAttributes(planID: "plan", start: date, deadline: deadline)
    let orphan = RestActivityAttributes(planID: "orphan", start: date, deadline: deadline)
    let running = RestActivityAttributes.ContentState(
      countdownStart: date, deadline: deadline, playback: .ambience, alarm: .scheduled)
    manager.activities = [
      .init(id: "kept", attributes: matching, state: running),
      .init(id: "duplicate", attributes: matching, state: running),
      .init(id: "orphan", attributes: orphan, state: running),
    ]

    let coordinator = RestActivityCoordinator(
      run: run, alarm: alarm, manager: manager, now: { date })
    await coordinator.waitForPendingWork()

    XCTAssertEqual(manager.activities.map(\.id), ["kept"])
    XCTAssertEqual(manager.activities.first?.state.playback, .stopped)
    XCTAssertEqual(manager.activities.first?.state.alarm, .scheduled)
    XCTAssertEqual(manager.activities.first?.state.deadline, deadline)
    XCTAssertEqual(manager.ended, 2)
    XCTAssertEqual(manager.requested, 0)
  }

  func testRelaunchEndsOrphanAndExpiredCards() async throws {
    let date = start
    let deadline = date.addingTimeInterval(600)
    let receipt = ScheduledNapAlarm(planID: "plan", id: UUID(), deadline: deadline)
    let alarm = try makeAlarm(receipt: receipt, now: { deadline })
    let run = makeRun(now: { deadline })
    let manager = RestActivityFakeManager()
    let attributes = RestActivityAttributes(planID: "plan", start: date, deadline: deadline)
    let state = RestActivityAttributes.ContentState(
      countdownStart: date, deadline: deadline, playback: .narrating, alarm: .scheduled)
    manager.activities = [.init(id: "expired", attributes: attributes, state: state)]
    let coordinator = RestActivityCoordinator(
      run: run, alarm: alarm, manager: manager, now: { deadline })
    await coordinator.waitForPendingWork()
    XCTAssertTrue(manager.activities.isEmpty)
    XCTAssertEqual(manager.ended, 1)

    let noAlarm = try makeAlarm(now: { date })
    let orphanManager = RestActivityFakeManager()
    orphanManager.activities = [.init(id: "orphan", attributes: attributes, state: state)]
    let orphanCoordinator = RestActivityCoordinator(
      run: makeRun(now: { date }), alarm: noAlarm,
      manager: orphanManager, now: { date })
    await orphanCoordinator.waitForPendingWork()
    XCTAssertTrue(orphanManager.activities.isEmpty)
    XCTAssertEqual(orphanManager.ended, 1)
  }

  func testFixturesLeaveOwnersExistingActivityUntouched() async throws {
    let date = start
    let run = makeRun(now: { date })
    let alarm = try makeAlarm(now: { date })
    let manager = RestActivityFakeManager()
    let deadline = date.addingTimeInterval(600)
    let original = RestActivityRecord(
      id: "owners-card",
      attributes: .init(planID: "owners-plan", start: date, deadline: deadline),
      state: .init(countdownStart: date, deadline: deadline, playback: .ambience, alarm: .scheduled)
    )
    manager.activities = [original]
    let coordinator = RestActivityCoordinator(
      run: run, alarm: alarm, manager: manager, now: { date }, isFixture: true)
    let plan = try NapPlanner.makeTimer(
      id: "fixture", window: .duration(600), sound: .silence, alarmEnabled: false,
      now: date, availableAmbienceIDs: [])
    try run.startTimer(plan: plan)
    await coordinator.waitForPendingWork()
    run.stop()
    await coordinator.waitForPendingWork()
    XCTAssertEqual(manager.activities, [original])
    XCTAssertEqual(manager.requested, 0)
    XCTAssertEqual(manager.ended, 0)
    XCTAssertFalse(manager.updateEntered)
  }
}
