import AlarmKit
import XCTest

@testable import Honkshool

@MainActor
private final class PlanAlarmFakeSystem: AlarmSystem {
  enum Failure: Error { case requested }

  var authorization: AlarmAuthorizationSnapshot = .authorized
  var requestResult: AlarmAuthorizationSnapshot = .authorized
  var records: [SystemAlarmRecord] = []
  var failReads = false
  var failCancellation = false
  var failScheduling = false
  var omitScheduledRecord = false
  var wrongDeadline = false
  var afterSchedule: (() -> Void)?
  var scheduleCount = 0
  var cancelledIDs: [UUID] = []

  func requestAuthorization() async throws -> AlarmAuthorizationSnapshot {
    authorization = requestResult
    return authorization
  }

  func alarms() throws -> [SystemAlarmRecord] {
    if failReads { throw Failure.requested }
    return records
  }

  func schedule(id: UUID, at date: Date) async throws {
    scheduleCount += 1
    if failScheduling { throw Failure.requested }
    if !omitScheduledRecord {
      records = [
        SystemAlarmRecord(
          id: id, state: .scheduled,
          originalDate: wrongDeadline ? date.addingTimeInterval(60) : date,
          countdownFireDate: nil)
      ]
    }
    afterSchedule?()
  }

  func cancel(id: UUID) throws {
    if failCancellation { throw Failure.requested }
    cancelledIDs.append(id)
    records.removeAll { $0.id == id }
  }

  func updates() -> AsyncStream<Void> { AsyncStream { _ in } }
}

@MainActor
final class NapPlanAlarmServiceTests: XCTestCase {
  private let base = Date(timeIntervalSince1970: 1_800_000_000)
  private var suiteName = ""
  private var defaults: UserDefaults!

  override func setUp() {
    suiteName = "NapPlanAlarmServiceTests.\(UUID().uuidString)"
    defaults = UserDefaults(suiteName: suiteName)!
  }

  override func tearDown() {
    defaults.removePersistentDomain(forName: suiteName)
  }

  private func plan(id: String = "first", alarm: Bool = true) throws -> NapPlan {
    let catalog = try PreparedCatalog.load()
    let journey = try XCTUnwrap(catalog.journeys.first)
    let sessionID = try XCTUnwrap(journey.sessionIDs.first)
    var request = NapRequest(
      window: .duration(1_200),
      startingAt: SessionSelection(journeyID: journey.id, sessionID: sessionID))
    request.alarmEnabled = alarm
    return try NapPlanner.makePlan(
      id: id, request: request, startingAt: base.addingTimeInterval(60), now: base,
      catalog: catalog.planningCatalog)
  }

  func testAuthorizationDenialBlocksSchedulingWithoutTrackingAnAlarm() async throws {
    let system = PlanAlarmFakeSystem()
    system.authorization = .notDetermined
    system.requestResult = .denied
    let service = NapPlanAlarmService(system: system, defaults: defaults, now: { self.base })

    let result = await service.schedule(for: try plan())
    XCTAssertNil(result)
    XCTAssertEqual(service.authorization, .denied)
    XCTAssertEqual(system.scheduleCount, 0)
    XCTAssertFalse(service.hasTrackedAlarm)
  }

  func testVerifiedAlarmReceiptPersistsAndRejectsAnotherPlan() async throws {
    let system = PlanAlarmFakeSystem()
    let service = NapPlanAlarmService(system: system, defaults: defaults, now: { self.base })
    let selected = try plan()

    let scheduled = await service.schedule(for: selected)
    let receipt = try XCTUnwrap(scheduled)
    XCTAssertEqual(receipt.planID, selected.id)
    XCTAssertEqual(receipt.deadline, selected.deadline)
    let saved = try XCTUnwrap(defaults.data(forKey: "napPlanAlarmReceipt"))
    XCTAssertEqual(try JSONDecoder().decode(ScheduledNapAlarm.self, from: saved), receipt)
    XCTAssertTrue(service.isScheduled(receipt))
    let second = await service.schedule(for: try plan(id: "second"))
    XCTAssertNil(second)
    XCTAssertEqual(system.scheduleCount, 1)
  }

  func testWrongDeadlineAndReadFailureRetainIdentityAndBlockPlayback() async throws {
    let system = PlanAlarmFakeSystem()
    system.wrongDeadline = true
    let service = NapPlanAlarmService(system: system, defaults: defaults, now: { self.base })

    let result = await service.schedule(for: try plan())
    XCTAssertNil(result)
    XCTAssertTrue(service.hasTrackedAlarm)
    service.refresh()
    XCTAssertTrue(service.hasTrackedAlarm)
    XCTAssertEqual(service.alarmStatus.phase, .unavailable)
    system.wrongDeadline = false
    system.failReads = true
    service.refresh()
    XCTAssertTrue(service.hasTrackedAlarm)
    XCTAssertEqual(service.alarmStatus.phase, .unavailable)
  }

  func testMissingScheduledRecordDoesNotReturnReceipt() async throws {
    let system = PlanAlarmFakeSystem()
    system.omitScheduledRecord = true
    let service = NapPlanAlarmService(system: system, defaults: defaults, now: { self.base })

    let result = await service.schedule(for: try plan())
    XCTAssertNil(result)
    XCTAssertTrue(service.hasTrackedAlarm)
    service.refresh()
    XCTAssertFalse(service.hasTrackedAlarm)
    XCTAssertEqual(service.alarmStatus.phase, .none)
  }

  func testThrownScheduleRetainsIdentityUntilSystemAbsenceReconciles() async throws {
    let system = PlanAlarmFakeSystem()
    system.failScheduling = true
    let service = NapPlanAlarmService(system: system, defaults: defaults, now: { self.base })

    let result = await service.schedule(for: try plan())
    XCTAssertNil(result)
    XCTAssertTrue(service.hasTrackedAlarm)
    XCTAssertEqual(service.alarmStatus.phase, .unavailable)
    service.refresh()
    XCTAssertFalse(service.hasTrackedAlarm)
  }

  func testUnreadableScheduledAlarmRetainsIdentityAndBlocksReceipt() async throws {
    let system = PlanAlarmFakeSystem()
    system.failReads = true
    let service = NapPlanAlarmService(system: system, defaults: defaults, now: { self.base })

    let result = await service.schedule(for: try plan())
    XCTAssertNil(result)
    XCTAssertTrue(service.hasTrackedAlarm)
    XCTAssertEqual(service.alarmStatus.phase, .unavailable)
    system.failReads = false
    service.refresh()
    XCTAssertEqual(service.alarmStatus.phase, .scheduled)
  }

  func testTimeAdvancingDuringScheduleBlocksStartAndKeepsAlarmForCancellation() async throws {
    let system = PlanAlarmFakeSystem()
    var current = base
    let service = NapPlanAlarmService(system: system, defaults: defaults, now: { current })
    let selected = try plan()
    system.afterSchedule = { current = selected.start.addingTimeInterval(1) }

    let result = await service.schedule(for: selected)
    XCTAssertNil(result)
    XCTAssertTrue(service.hasTrackedAlarm)
    XCTAssertEqual(service.alarmStatus.phase, .unavailable)
    XCTAssertTrue(service.cancel())
  }

  func testRelaunchRestoresExactAlarmAndSnoozeStatus() async throws {
    let system = PlanAlarmFakeSystem()
    let service = NapPlanAlarmService(system: system, defaults: defaults, now: { self.base })
    let scheduled = await service.schedule(for: try plan())
    let receipt = try XCTUnwrap(scheduled)

    let restored = NapPlanAlarmService(system: system, defaults: defaults, now: { self.base })
    XCTAssertTrue(restored.isScheduled(receipt))
    let snoozeDate = receipt.deadline.addingTimeInterval(540)
    system.records = [
      SystemAlarmRecord(
        id: receipt.id, state: .countdown, originalDate: receipt.deadline,
        countdownFireDate: snoozeDate)
    ]
    restored.refresh()
    XCTAssertEqual(restored.alarmStatus.phase, .snoozed)
    XCTAssertEqual(restored.alarmStatus.nextAlertDate, snoozeDate)
    XCTAssertFalse(restored.isScheduled(receipt))
  }

  func testSnoozeDeadlineArrivingAfterAlarmUpdateIsReconciled() async throws {
    let system = PlanAlarmFakeSystem()
    let service = NapPlanAlarmService(system: system, defaults: defaults, now: { self.base })
    let scheduled = await service.schedule(for: try plan())
    let receipt = try XCTUnwrap(scheduled)
    system.records = [
      SystemAlarmRecord(
        id: receipt.id, state: .countdown, originalDate: receipt.deadline,
        countdownFireDate: nil)
    ]
    service.refresh()
    XCTAssertTrue(service.needsCountdownReconciliation)

    let snoozeDate = receipt.deadline.addingTimeInterval(540)
    await service.reconcileCountdown(wait: { _ in
      system.records = [
        SystemAlarmRecord(
          id: receipt.id, state: .countdown, originalDate: receipt.deadline,
          countdownFireDate: snoozeDate)
      ]
    })
    XCTAssertEqual(service.alarmStatus.nextAlertDate, snoozeDate)
    XCTAssertFalse(service.needsCountdownReconciliation)
  }

  func testUnreadableReceiptBlocksUntilSystemReportsNoAlarms() async throws {
    let system = PlanAlarmFakeSystem()
    system.records = [
      SystemAlarmRecord(
        id: UUID(), state: .scheduled,
        originalDate: base.addingTimeInterval(1_200), countdownFireDate: nil)
    ]
    defaults.set(Data("incomplete".utf8), forKey: "napPlanAlarmReceipt")
    let service = NapPlanAlarmService(system: system, defaults: defaults, now: { self.base })
    XCTAssertTrue(service.hasTrackedAlarm)
    XCTAssertFalse(service.canCancelTrackedAlarm)
    let result = await service.schedule(for: try plan())
    XCTAssertNil(result)
    system.records = []
    service.refresh()
    XCTAssertFalse(service.hasTrackedAlarm)
    XCTAssertNil(defaults.data(forKey: "napPlanAlarmReceipt"))
  }

  func testCancellationFailureKeepsIdentityForRetry() async throws {
    let system = PlanAlarmFakeSystem()
    let service = NapPlanAlarmService(system: system, defaults: defaults, now: { self.base })
    let scheduled = await service.schedule(for: try plan())
    let receipt = try XCTUnwrap(scheduled)
    system.failCancellation = true

    XCTAssertFalse(service.cancel())
    XCTAssertTrue(service.hasTrackedAlarm)
    let saved = try XCTUnwrap(defaults.data(forKey: "napPlanAlarmReceipt"))
    XCTAssertEqual(try JSONDecoder().decode(ScheduledNapAlarm.self, from: saved), receipt)
    system.failCancellation = false
    XCTAssertTrue(service.cancel())
    XCTAssertFalse(service.hasTrackedAlarm)
    XCTAssertEqual(system.cancelledIDs, [receipt.id])
  }
}

@MainActor
final class RealNapPlanAlarmDeviceTests: XCTestCase {
  func testConfirmedPlanSchedulesRealAlarmAndStopsPreparedNarration() async throws {
    guard ProcessInfo.processInfo.environment["HONKSHOOL_REAL_NAP_PLAN_ALARM_TEST"] == "1"
    else {
      throw XCTSkip("Opt in on a physical iPhone with an authorized Honkshool alarm.")
    }
    #if targetEnvironment(simulator)
      throw XCTSkip("A simulator cannot establish physical alarm delivery.")
    #else
      let system = AppleAlarmSystem(source: "nap-plan-device-test")
      guard system.authorization == .authorized else {
        throw XCTSkip("Authorize Honkshool alarms before the physical-device test.")
      }
      let catalog = try PreparedCatalog.load()
      let journey = try XCTUnwrap(catalog.journeys.first)
      let sessionID = try XCTUnwrap(journey.sessionIDs.first)
      let prepared = try XCTUnwrap(catalog.sessions[sessionID])
      // Use a short test-only estimate so the full prepared file exercises the
      // production cutoff without waiting through a normal length Nap Plan.
      let shortSession = try Session(
        id: prepared.session.id, revision: prepared.session.revision,
        title: prepared.session.title, estimatedDuration: 60)
      let planningCatalog = try NapCatalog(journeys: catalog.journeys, sessions: [shortSession])
      var request = NapRequest(
        window: .duration(90),
        startingAt: SessionSelection(journeyID: journey.id, sessionID: sessionID))
      request.alarmEnabled = true
      let reviewedAt = Date.now
      var reviewState = NapPlanReviewState()
      try reviewState.review(
        id: UUID().uuidString, request: request,
        startingAt: reviewedAt.addingTimeInterval(20), now: reviewedAt,
        catalog: planningCatalog)
      try reviewState.confirm(at: Date.now)
      let review = try XCTUnwrap(reviewState.confirmed)

      let suiteName = "RealNapPlanAlarmDeviceTests.\(UUID().uuidString)"
      let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
      defer { defaults.removePersistentDomain(forName: suiteName) }
      let alarm = NapPlanAlarmService(system: system, defaults: defaults)
      let run = NapRunController()
      defer {
        run.stop()
        let saved = defaults.data(forKey: "napPlanAlarmReceipt")
        let alarmID = saved.flatMap {
          try? JSONDecoder().decode(ScheduledNapAlarm.self, from: $0).id
        }
        if !alarm.cancel(), let alarmID {
          try? AlarmManager.shared.stop(id: alarmID)
          if (try? system.alarms().contains(where: { $0.id == alarmID })) ?? true {
            XCTFail("The device-test alarm could not be cleaned up.")
          }
        }
      }
      try run.preflight(review: review, catalog: catalog)
      let scheduled = await alarm.schedule(for: review.plan)
      let receipt = try XCTUnwrap(scheduled, alarm.statusMessage)
      XCTAssertTrue(alarm.isScheduled(receipt))
      try run.start(review: review, catalog: catalog, scheduledAlarm: receipt)

      var narrated = false
      var alertObservedAt: Date?
      var stopObservedAt: Date?
      while Date.now < review.plan.deadline.addingTimeInterval(7) {
        let observedAt = Date.now
        narrated = narrated || run.phase == .narrating
        if stopObservedAt == nil && run.phase == .finished { stopObservedAt = observedAt }
        if alertObservedAt == nil,
          let systemAlarm = try? system.alarms().first(where: { $0.id == receipt.id }),
          systemAlarm.state == .alerting
        {
          alertObservedAt = observedAt
        }
        if alertObservedAt != nil && stopObservedAt != nil { break }
        try await Task.sleep(for: .milliseconds(200))
      }

      XCTAssertTrue(narrated, "The prepared narration never started.")
      let alert = try XCTUnwrap(alertObservedAt, "The production alarm never alerted.")
      let stopped = try XCTUnwrap(stopObservedAt, "The production run missed its audio cutoff.")
      XCTAssertLessThanOrEqual(abs(alert.timeIntervalSince(review.plan.deadline)), 5)
      XCTAssertLessThanOrEqual(abs(stopped.timeIntervalSince(review.plan.deadline)), 3)
      XCTAssertEqual(run.phase, .finished)
      XCTAssertFalse(try XCTUnwrap(run.records.first).isCompleted)
    #endif
  }
}
