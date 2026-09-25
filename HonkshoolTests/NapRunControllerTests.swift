import AVFoundation
import XCTest

@testable import Honkshool

@MainActor
private final class RunTestClock {
  var now = Date(timeIntervalSince1970: 1_800_000_000)
}

@MainActor
private final class RunTestScheduler {
  private final class Job {
    let date: Date
    let action: @MainActor () -> Void
    var cancelled = false

    init(date: Date, action: @escaping @MainActor () -> Void) {
      self.date = date
      self.action = action
    }
  }

  private let clock: RunTestClock
  private var jobs: [Job] = []

  init(clock: RunTestClock) { self.clock = clock }

  func schedule(
    after delay: TimeInterval, action: @escaping @MainActor () -> Void
  ) -> @MainActor () -> Void {
    let job = Job(date: clock.now.addingTimeInterval(delay), action: action)
    jobs.append(job)
    return { job.cancelled = true }
  }

  func advance(to date: Date) {
    clock.now = date
    while let index = jobs.indices.first(where: { !jobs[$0].cancelled && jobs[$0].date <= date }) {
      let job = jobs.remove(at: index)
      job.action()
    }
  }
}

@MainActor
private final class RunFakePlayer: NapRunAudioPlaying {
  var onCompletion: (() -> Void)?
  var onFailure: ((String) -> Void)?
  var currentTime: TimeInterval = 0
  let duration: TimeInterval
  private(set) var playCount = 0
  private(set) var pauseCount = 0
  private(set) var stopCount = 0

  init(duration: TimeInterval = 727.625) { self.duration = duration }
  func prepareToPlay() -> Bool {
    currentTime = 0
    return true
  }
  func seek(to time: TimeInterval) { currentTime = time }
  func play() -> Bool {
    playCount += 1
    return true
  }
  func pause() { pauseCount += 1 }
  func stop() { stopCount += 1 }
  func finish() {
    currentTime = duration
    onCompletion?()
  }
}

@MainActor
final class NapRunControllerTests: XCTestCase {
  private func review(
    catalog: PreparedCatalog, now: Date, duration: TimeInterval = 1_200,
    alarm: Bool = false
  ) throws -> NapPlanReview {
    let journey = try XCTUnwrap(catalog.journeys.first)
    let sessionID = try XCTUnwrap(journey.sessionIDs.first)
    var request = NapRequest(
      window: .duration(duration),
      startingAt: SessionSelection(journeyID: journey.id, sessionID: sessionID))
    request.alarmEnabled = alarm
    var state = NapPlanReviewState()
    try state.review(
      id: UUID().uuidString, request: request, startingAt: now.addingTimeInterval(60), now: now,
      catalog: catalog.planningCatalog)
    try state.confirm(at: now)
    return try XCTUnwrap(state.confirmed)
  }

  private func controller(
    clock: RunTestClock, scheduler: RunTestScheduler, player: RunFakePlayer,
    activation: (() throws -> Void)? = nil,
    observeSystemEvents: Bool = false
  ) -> NapRunController {
    return NapRunController(
      playerFactory: { _ in player }, clock: { clock.now },
      scheduler: { delay, action in scheduler.schedule(after: delay, action: action) },
      activateAudioSession: activation ?? {}, deactivateAudioSession: {},
      observeSystemEvents: observeSystemEvents, manageRemoteCommands: false)
  }

  func testAlarmRequestedAndStaleStartNeverStartAudio() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let player = RunFakePlayer()
    let run = controller(clock: clock, scheduler: scheduler, player: player)
    let alarmReview = try review(catalog: catalog, now: clock.now, alarm: true)
    XCTAssertThrowsError(try run.start(review: alarmReview, catalog: catalog)) {
      XCTAssertEqual($0 as? NapRunError, .alarmUnavailable)
    }
    XCTAssertEqual(run.phase, .idle)
    XCTAssertEqual(player.playCount, 0)

    let noAlarmReview = try review(catalog: catalog, now: clock.now)
    clock.now = noAlarmReview.plan.start.addingTimeInterval(0.1)
    XCTAssertThrowsError(try run.start(review: noAlarmReview, catalog: catalog)) {
      XCTAssertEqual($0 as? NapRunError, .staleStart)
    }
    XCTAssertEqual(player.playCount, 0)
  }

  func testApprovedStartNaturalCompletionAndSilentRestKeepDeadline() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let player = RunFakePlayer()
    let run = controller(clock: clock, scheduler: scheduler, player: player)
    let approved = try review(catalog: catalog, now: clock.now)

    try run.start(review: approved, catalog: catalog)
    XCTAssertEqual(run.phase, .waiting)
    XCTAssertEqual(player.playCount, 0)
    scheduler.advance(to: approved.plan.start)
    XCTAssertEqual(run.phase, .narrating)
    XCTAssertEqual(player.playCount, 1)

    clock.now = approved.plan.start.addingTimeInterval(player.duration)
    player.finish()
    XCTAssertEqual(run.records.count, 1)
    XCTAssertTrue(try XCTUnwrap(run.records.first).isCompleted)
    XCTAssertEqual(run.phase, .resting)
    XCTAssertEqual(approved.plan.deadline, approved.plan.start.addingTimeInterval(1_200))

    scheduler.advance(to: approved.plan.deadline)
    XCTAssertEqual(run.phase, .finished)
    XCTAssertEqual(run.records.count, 1)
  }

  func testPauseTimeIsExcludedAndStopRetainsAudioCheckpoint() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let player = RunFakePlayer()
    let run = controller(clock: clock, scheduler: scheduler, player: player)
    let approved = try review(catalog: catalog, now: clock.now)
    try run.start(review: approved, catalog: catalog)
    scheduler.advance(to: approved.plan.start)

    clock.now = approved.plan.start.addingTimeInterval(100)
    player.currentTime = 100
    run.pause()
    XCTAssertEqual(run.phase, .paused)
    clock.now = clock.now.addingTimeInterval(30)
    run.resume()
    XCTAssertEqual(run.phase, .narrating)
    clock.now = clock.now.addingTimeInterval(50)
    player.currentTime = 150
    run.stop()

    let record = try XCTUnwrap(run.records.first)
    XCTAssertFalse(record.isCompleted)
    XCTAssertEqual(record.playedDuration, 150)
    XCTAssertEqual(record.resumePoint?.audioOffset, 150)
    XCTAssertNil(record.resumePoint?.utf16Offset)
    XCTAssertEqual(run.phase, .stopped)
    XCTAssertEqual(player.pauseCount, 1)
    XCTAssertEqual(player.playCount, 2)
  }

  func testExactDeadlineKeepsPartialAndLateCutoffDoesNotInventEvidence() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let player = RunFakePlayer()
    let run = controller(clock: clock, scheduler: scheduler, player: player)
    let approved = try review(catalog: catalog, now: clock.now)
    try run.start(review: approved, catalog: catalog)
    scheduler.advance(to: approved.plan.start)
    player.currentTime = 600
    scheduler.advance(to: approved.plan.deadline)
    XCTAssertEqual(run.phase, .finished)
    XCTAssertEqual(run.records.first?.resumePoint?.audioOffset, 600)
    XCTAssertEqual(run.records.first?.endedAt, approved.plan.deadline)
    XCTAssertEqual(
      run.records.first?.outcome,
      .partial(reason: .deadlineReached, resumePoint: try XCTUnwrap(run.records.first?.resumePoint))
    )

    run.resetPresentation()
    clock.now = clock.now.addingTimeInterval(10)
    let later = try review(catalog: catalog, now: clock.now)
    try run.start(review: later, catalog: catalog)
    scheduler.advance(to: later.plan.start)
    player.currentTime = 500
    scheduler.advance(to: later.plan.deadline.addingTimeInterval(-10))
    XCTAssertEqual(run.latestVerifiedCheckpoint?.resumePoint.audioOffset, 500)
    scheduler.advance(to: later.plan.deadline.addingTimeInterval(2))
    XCTAssertEqual(run.phase, .finished)
    XCTAssertEqual(run.records.count, 1)
    XCTAssertEqual(run.records.first?.endedAt, later.plan.deadline.addingTimeInterval(2))
    XCTAssertEqual(
      run.records.first?.checkpointCapturedAt, later.plan.deadline.addingTimeInterval(-10))
    XCTAssertEqual(run.records.first?.resumePoint?.audioOffset, 500)
    XCTAssertEqual(
      run.records.first?.outcome,
      .partial(reason: .deadlineMissed, resumePoint: try XCTUnwrap(run.records.first?.resumePoint))
    )
    XCTAssertEqual(run.latestVerifiedCheckpoint?.resumePoint.audioOffset, 500)
    XCTAssertTrue(run.statusMessage.contains("recorded for resumption"))
  }

  func testStoppedRunIgnoresStaleCompletion() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let player = RunFakePlayer()
    let run = controller(clock: clock, scheduler: scheduler, player: player)
    let approved = try review(catalog: catalog, now: clock.now)
    try run.start(review: approved, catalog: catalog)
    scheduler.advance(to: approved.plan.start)
    let oldCompletion = player.onCompletion
    clock.now = approved.plan.start.addingTimeInterval(10)
    player.currentTime = 10
    run.stop()
    oldCompletion?()
    XCTAssertEqual(run.records.count, 1)
    XCTAssertFalse(try XCTUnwrap(run.records.first).isCompleted)
  }

  func testOverdueStopRetainsVerifiedCheckpointAndActualStopTime() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let player = RunFakePlayer()
    let run = controller(clock: clock, scheduler: scheduler, player: player)
    let approved = try review(catalog: catalog, now: clock.now)
    try run.start(review: approved, catalog: catalog)
    scheduler.advance(to: approved.plan.start)
    player.currentTime = 500
    scheduler.advance(to: approved.plan.deadline.addingTimeInterval(-10))
    clock.now = approved.plan.deadline.addingTimeInterval(2)

    run.stop()

    let record = try XCTUnwrap(run.records.first)
    XCTAssertEqual(run.phase, .finished)
    XCTAssertEqual(record.endedAt, clock.now)
    XCTAssertEqual(record.checkpointCapturedAt, approved.plan.deadline.addingTimeInterval(-10))
    XCTAssertEqual(record.resumePoint?.audioOffset, 500)
    XCTAssertEqual(
      record.outcome,
      .partial(reason: .deadlineMissed, resumePoint: try XCTUnwrap(record.resumePoint)))
  }

  func testAudioActivationFailureNeverClaimsPlayback() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let player = RunFakePlayer()
    let run = controller(clock: clock, scheduler: scheduler, player: player) {
      throw NapRunError.contentUnavailable
    }
    let approved = try review(catalog: catalog, now: clock.now)
    try run.start(review: approved, catalog: catalog)
    scheduler.advance(to: approved.plan.start)
    XCTAssertEqual(run.phase, .failed)
    XCTAssertEqual(player.playCount, 0)
    XCTAssertTrue(run.records.isEmpty)
  }

  func testLeavingForegroundBeforeNarrationRequiresFreshReview() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let player = RunFakePlayer()
    let run = controller(clock: clock, scheduler: scheduler, player: player)
    let approved = try review(catalog: catalog, now: clock.now)
    try run.start(review: approved, catalog: catalog)
    run.scenePhaseChanged(isActive: false)
    XCTAssertEqual(run.phase, .failed)
    XCTAssertTrue(run.statusMessage.contains("left the foreground"))
    scheduler.advance(to: approved.plan.start)
    XCTAssertEqual(player.playCount, 0)
  }

  func testInterruptionDuringPendingStartRequiresFreshReview() async throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let player = RunFakePlayer()
    let run = controller(
      clock: clock, scheduler: scheduler, player: player, observeSystemEvents: true)
    let approved = try review(catalog: catalog, now: clock.now)
    try run.start(review: approved, catalog: catalog)

    NotificationCenter.default.post(
      name: AVAudioSession.interruptionNotification, object: nil,
      userInfo: [
        AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue
      ])
    try await Task.sleep(for: .milliseconds(50))
    XCTAssertEqual(run.phase, .failed)
    XCTAssertEqual(player.playCount, 0)
    scheduler.advance(to: approved.plan.start)
    XCTAssertEqual(player.playCount, 0)
  }
}
