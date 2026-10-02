import AVFoundation
import MediaPlayer
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
  var onPlay: (() -> Void)?
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
    onPlay?()
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
private final class RunFakeAmbience: NapAmbiencePlaying {
  var onFailure: ((String) -> Void)?
  var onPlay: (() -> Void)?
  var prepares = true
  var starts = true
  private(set) var prepareCount = 0
  private(set) var playCount = 0
  private(set) var pauseCount = 0
  private(set) var stopCount = 0

  func prepareToPlay() -> Bool {
    prepareCount += 1
    return prepares
  }
  func play() -> Bool {
    playCount += 1
    onPlay?()
    return starts
  }
  func pause() { pauseCount += 1 }
  func stop() { stopCount += 1 }
  func fail() { onFailure?("decode failed") }
}

@MainActor
private final class RunHistoryRecorder: NapHistoryRecording {
  var saved: [(record: PlaybackRecord, isCheckpoint: Bool)] = []
  func save(_ record: PlaybackRecord, isCheckpoint: Bool) {
    saved.append((record, isCheckpoint))
  }
}

@MainActor
final class NapRunControllerTests: XCTestCase {
  private func timer(
    now: Date, duration: TimeInterval = 120, sound: RestSound = .silence,
    alarm: Bool = false
  ) throws -> NapPlan {
    try NapPlanner.makeTimer(
      id: UUID().uuidString, window: .duration(duration), sound: sound,
      alarmEnabled: alarm, now: now,
      availableAmbienceIDs: [PreparedAmbience.gentleRainID])
  }

  private func review(
    catalog: PreparedCatalog, now: Date, duration: TimeInterval = 1_200,
    alarm: Bool = false, selection: SessionSelection? = nil,
    sound: RestSound = .silence, settling: TimeInterval = 0, drift: TimeInterval = 0
  ) throws -> NapPlanReview {
    let journey = try XCTUnwrap(catalog.journeys.first)
    let sessionID = try XCTUnwrap(journey.sessionIDs.first)
    var request = NapRequest(
      window: .duration(duration),
      startingAt: selection ?? SessionSelection(journeyID: journey.id, sessionID: sessionID))
    request.alarmEnabled = alarm
    request.fallback = sound
    request.settlingDuration = settling
    request.driftDuration = drift
    var state = NapPlanReviewState()
    try state.review(
      id: UUID().uuidString, request: request, startingAt: now.addingTimeInterval(60), now: now,
      catalog: catalog.planningCatalog,
      availableAmbienceIDs: [PreparedAmbience.gentleRainID])
    try state.confirm(at: now)
    return try XCTUnwrap(state.confirmed)
  }

  private func controller(
    clock: RunTestClock, scheduler: RunTestScheduler, player: RunFakePlayer,
    activation: (() throws -> Void)? = nil,
    observeSystemEvents: Bool = false,
    history: (any NapHistoryRecording)? = nil,
    ambience: RunFakeAmbience? = nil,
    ambienceFactory: ((URL) throws -> NapAmbiencePlaying)? = nil,
    resolveAmbience: ((String) throws -> URL)? = nil
  ) -> NapRunController {
    return NapRunController(
      playerFactory: { _ in player },
      ambienceFactory: ambienceFactory ?? { _ in ambience ?? RunFakeAmbience() },
      resolveAmbience: resolveAmbience ?? { _ in URL(fileURLWithPath: "/tmp/rain.wav") },
      clock: { clock.now },
      scheduler: { delay, action in scheduler.schedule(after: delay, action: action) },
      activateAudioSession: activation ?? {}, deactivateAudioSession: {},
      observeSystemEvents: observeSystemEvents, manageRemoteCommands: false, history: history)
  }

  private func catalogWithTwoPreparedSessions() throws -> PreparedCatalog {
    let url = try XCTUnwrap(Bundle.main.url(forResource: "PreparedCatalog", withExtension: "json"))
    let original = try Data(contentsOf: url)
    var document = try XCTUnwrap(
      JSONSerialization.jsonObject(with: original) as? [String: Any])
    let bundledSessions = try XCTUnwrap(document["sessions"] as? [[String: Any]])
    let first = try XCTUnwrap(
      bundledSessions.first { $0["id"] as? String == "turning-fuel-into-motion" })
    var sessions = [first]
    var second = first
    second["id"] = "second-prepared-session"
    second["title"] = "Second prepared session"
    sessions.append(second)
    document["sessions"] = sessions
    var journeys = try XCTUnwrap(document["journeys"] as? [[String: Any]])
    var journey = try XCTUnwrap(journeys.first)
    var sessionIDs = ["turning-fuel-into-motion"]
    sessionIDs.append("second-prepared-session")
    journey["sessionIDs"] = sessionIDs
    journeys[0] = journey
    document["journeys"] = journeys
    return try PreparedCatalog(data: JSONSerialization.data(withJSONObject: document))
  }

  func testTimerStartsRainImmediatelyAndStopsAtFixedDeadlineWithoutHistory() throws {
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let rain = RunFakeAmbience()
    let narration = RunFakePlayer()
    let history = RunHistoryRecorder()
    let run = controller(
      clock: clock, scheduler: scheduler, player: narration,
      history: history, ambience: rain)
    let plan = try timer(
      now: clock.now, sound: .ambience(id: PreparedAmbience.gentleRainID))

    try run.startTimer(plan: plan)
    XCTAssertEqual(run.phase, .ambience)
    XCTAssertEqual(rain.playCount, 1)
    XCTAssertEqual(narration.playCount, 0)
    XCTAssertTrue(run.records.isEmpty)
    XCTAssertTrue(history.saved.isEmpty)
    run.scenePhaseChanged(isActive: false)
    XCTAssertEqual(run.phase, .ambience)
    scheduler.advance(to: plan.deadline)
    XCTAssertEqual(run.phase, .finished)
    XCTAssertGreaterThan(rain.stopCount, 0)
    XCTAssertTrue(history.saved.isEmpty)
    XCTAssertEqual(run.presentationPlan?.deadline, plan.deadline)
  }

  func testTimerUsesSilenceImmediatelyAndRejectsDuplicateStart() throws {
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let run = controller(clock: clock, scheduler: scheduler, player: RunFakePlayer())
    let plan = try timer(now: clock.now)

    try run.startTimer(plan: plan)
    XCTAssertEqual(run.phase, .resting)
    XCTAssertFalse(run.statusMessage.contains("Keep Honkshool open"))
    XCTAssertThrowsError(try run.startTimer(plan: plan)) {
      XCTAssertEqual($0 as? NapRunError, .alreadyRunning)
    }
    scheduler.advance(to: plan.deadline)
    XCTAssertEqual(run.phase, .finished)
    XCTAssertTrue(run.records.isEmpty)
  }

  func testTimerStartWindowAndAlarmReceiptAreStrict() throws {
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let run = controller(clock: clock, scheduler: scheduler, player: RunFakePlayer())
    let plan = try timer(now: clock.now, alarm: true)
    let wrong = ScheduledNapAlarm(
      planID: "different", id: UUID(), deadline: try XCTUnwrap(plan.wakeAlarm))
    XCTAssertThrowsError(try run.startTimer(plan: plan, scheduledAlarm: wrong)) {
      XCTAssertEqual($0 as? NapRunError, .alarmUnavailable)
    }
    XCTAssertThrowsError(try run.startTimer(plan: plan)) {
      XCTAssertEqual($0 as? NapRunError, .alarmUnavailable)
    }
    let receipt = ScheduledNapAlarm(
      planID: plan.id, id: UUID(), deadline: try XCTUnwrap(plan.wakeAlarm))
    clock.now = plan.start.addingTimeInterval(5)
    try run.startTimer(plan: plan, scheduledAlarm: receipt)
    XCTAssertEqual(run.phase, .resting)
    XCTAssertEqual(run.presentationPlan?.deadline, plan.deadline)
    run.stop()
    XCTAssertTrue(run.statusMessage.contains("wake alarm was not cancelled"))

    let late = try timer(now: clock.now)
    clock.now = late.start.addingTimeInterval(5.001)
    XCTAssertThrowsError(try run.startTimer(plan: late)) {
      XCTAssertEqual($0 as? NapRunError, .staleStart)
    }
  }

  func testTimerRainPreparationCrossingStartWindowDoesNotPlay() throws {
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let rain = RunFakeAmbience()
    let history = RunHistoryRecorder()
    let plan = try timer(
      now: clock.now, sound: .ambience(id: PreparedAmbience.gentleRainID))
    let run = NapRunController(
      playerFactory: { _ in RunFakePlayer() },
      ambienceFactory: { _ in
        clock.now = plan.start.addingTimeInterval(5.001)
        return rain
      },
      resolveAmbience: { _ in URL(fileURLWithPath: "/tmp/rain.wav") },
      clock: { clock.now },
      scheduler: { delay, action in scheduler.schedule(after: delay, action: action) },
      activateAudioSession: {}, deactivateAudioSession: {},
      observeSystemEvents: false, manageRemoteCommands: false, history: history)

    try run.startTimer(plan: plan)
    XCTAssertEqual(run.phase, .failed)
    XCTAssertEqual(rain.playCount, 0)
    XCTAssertTrue(run.records.isEmpty)
    XCTAssertTrue(history.saved.isEmpty)
  }

  func testTimerCannotStartInBackgroundOrFromNarratedPlan() throws {
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let narration = RunFakePlayer()
    let rain = RunFakeAmbience()
    let run = controller(
      clock: clock, scheduler: scheduler, player: narration, ambience: rain)
    let plan = try timer(
      now: clock.now, sound: .ambience(id: PreparedAmbience.gentleRainID))
    run.scenePhaseChanged(isActive: false)
    XCTAssertThrowsError(try run.startTimer(plan: plan)) {
      XCTAssertEqual($0 as? NapRunError, .audioUnavailable)
    }
    XCTAssertEqual(rain.playCount, 0)
    run.scenePhaseChanged(isActive: true)
    let catalog = try PreparedCatalog.load()
    let narrated = try review(catalog: catalog, now: clock.now)
    XCTAssertThrowsError(try run.startTimer(plan: narrated.plan)) {
      XCTAssertEqual($0 as? NapRunError, .invalidTimerPlan)
    }
    XCTAssertEqual(narration.playCount, 0)
  }

  func testTimerRainPlayCrossingDeadlineStopsWithoutHistory() throws {
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let rain = RunFakeAmbience()
    let history = RunHistoryRecorder()
    let run = controller(
      clock: clock, scheduler: scheduler, player: RunFakePlayer(),
      history: history, ambience: rain)
    let plan = try timer(
      now: clock.now, sound: .ambience(id: PreparedAmbience.gentleRainID))
    rain.onPlay = { clock.now = plan.deadline }

    try run.startTimer(plan: plan)
    XCTAssertEqual(run.phase, .finished)
    XCTAssertGreaterThan(rain.stopCount, 0)
    XCTAssertTrue(run.records.isEmpty)
    XCTAssertTrue(history.saved.isEmpty)
  }

  func testPresentationSnapshotSurvivesStopAndResetDoesNotRestartPlayback() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let player = RunFakePlayer()
    let run = controller(clock: clock, scheduler: scheduler, player: player)
    let approved = try review(catalog: catalog, now: clock.now)
    XCTAssertNil(run.presentationPlan)
    try run.start(review: approved, catalog: catalog)
    XCTAssertEqual(run.presentationPlan, approved.plan)
    scheduler.advance(to: approved.plan.start)
    XCTAssertEqual(run.currentNarrationTitle, approved.plan.route.first?.session.title)
    run.stop()
    XCTAssertEqual(run.presentationPlan?.deadline, approved.plan.deadline)
    XCTAssertNil(run.currentNarrationTitle)
    let playCount = player.playCount
    run.resetPresentation()
    XCTAssertNil(run.presentationPlan)
    XCTAssertEqual(run.phase, .idle)
    XCTAssertEqual(player.playCount, playCount)
  }

  func testPauseAndBackgroundSaveVerifiedCheckpointsWithoutEndingRun() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let player = RunFakePlayer()
    let history = RunHistoryRecorder()
    let run = controller(clock: clock, scheduler: scheduler, player: player, history: history)
    let approved = try review(catalog: catalog, now: clock.now)
    try run.start(review: approved, catalog: catalog)
    XCTAssertTrue(history.saved.isEmpty)
    scheduler.advance(to: approved.plan.start)
    player.currentTime = 12
    clock.now = approved.plan.start.addingTimeInterval(12)
    run.pause()
    let paused = try XCTUnwrap(history.saved.last)
    XCTAssertTrue(paused.isCheckpoint)
    XCTAssertEqual(paused.record.resumePoint?.audioOffset, 12)
    XCTAssertEqual(paused.record.endedAt, clock.now)
    XCTAssertEqual(
      paused.record.resumePoint?.audioAssetSHA256,
      catalog.sessions[paused.record.plannedSession.session.id]?.narrationAsset?.sha256)
    XCTAssertTrue(run.records.isEmpty)
    XCTAssertEqual(run.phase, .paused)
    clock.now = clock.now.addingTimeInterval(30)
    run.scenePhaseChanged(isActive: false)
    XCTAssertEqual(history.saved.last?.record.playedDuration, 12)
    XCTAssertTrue(run.hasActiveRun)
    run.stop()
    XCTAssertFalse(try XCTUnwrap(history.saved.last).isCheckpoint)
    XCTAssertEqual(history.saved.last?.record.id, paused.record.id)
  }

  func testLateCutoffPersistsActualStopAndEarlierVerifiedPosition() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let player = RunFakePlayer()
    let history = RunHistoryRecorder()
    let run = controller(clock: clock, scheduler: scheduler, player: player, history: history)
    let approved = try review(catalog: catalog, now: clock.now)
    try run.start(review: approved, catalog: catalog)
    scheduler.advance(to: approved.plan.start)
    player.currentTime = 300
    scheduler.advance(to: approved.plan.start.addingTimeInterval(300))
    let checkpoint = try XCTUnwrap(history.saved.last?.record)
    player.currentTime = 500
    scheduler.advance(to: approved.plan.deadline.addingTimeInterval(4))
    let saved = try XCTUnwrap(history.saved.last)
    XCTAssertFalse(saved.isCheckpoint)
    XCTAssertEqual(saved.record.endedAt, approved.plan.deadline.addingTimeInterval(4))
    XCTAssertEqual(saved.record.checkpointCapturedAt, checkpoint.endedAt)
    XCTAssertEqual(saved.record.resumePoint?.audioOffset, 300)
    XCTAssertFalse(saved.record.isCompleted)
  }

  func testStoppedAttemptReopensAndResumesAsNewCompletedAttempt() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("History.store")
    let store = ListeningHistoryStore(storeURL: url)
    let catalog = try PreparedCatalog.load()
    let journey = try XCTUnwrap(catalog.journeys.first)
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let player = RunFakePlayer()
    let run = controller(clock: clock, scheduler: scheduler, player: player, history: store)
    let approved = try review(catalog: catalog, now: clock.now)
    try run.start(review: approved, catalog: catalog)
    scheduler.advance(to: approved.plan.start)
    player.currentTime = 120
    clock.now = approved.plan.start.addingTimeInterval(120)
    run.stop()
    XCTAssertNil(store.errorMessage)

    let reopened = ListeningHistoryStore(storeURL: url)
    XCTAssertNil(reopened.errorMessage)
    let attempt = try XCTUnwrap(reopened.entries.first)
    let selection = try XCTUnwrap(reopened.history.resumeSelection(for: attempt.id))
    XCTAssertEqual(selection.resumePoint?.audioOffset, 120)
    XCTAssertEqual(reopened.history.nextSessionID(in: journey), selection.sessionID)
    let resumedPlayer = RunFakePlayer()
    let resumed = controller(
      clock: clock, scheduler: scheduler, player: resumedPlayer, history: reopened)
    XCTAssertEqual(resumed.phase, .idle)
    let next = try review(catalog: catalog, now: clock.now, selection: selection)
    try resumed.start(review: next, catalog: catalog)
    scheduler.advance(to: next.plan.start)
    XCTAssertEqual(resumedPlayer.currentTime, 120)
    clock.now = next.plan.start.addingTimeInterval(resumedPlayer.duration - 120)
    resumedPlayer.finish()
    XCTAssertNil(reopened.errorMessage)
    XCTAssertEqual(reopened.entries.count, 2)
    XCTAssertEqual(reopened.entries.filter { $0.record.isCompleted }.count, 1)
    XCTAssertEqual(reopened.entries.first(where: { $0.id == attempt.id }), attempt)
    XCTAssertEqual(reopened.history.nextSessionID(in: journey), "air-fuel-and-spark")
    resumed.stop()
  }

  func testNaturalCompletionAfterPlayerRewindsReplacesPersistedCheckpoint() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("History.store")
    let store = ListeningHistoryStore(storeURL: url)
    let catalog = try PreparedCatalog.load()
    let journey = try XCTUnwrap(catalog.journeys.first)
    let prepared = try XCTUnwrap(catalog.sessions[journey.sessionIDs[0]])
    let asset = try XCTUnwrap(prepared.narrationAsset)
    let offset: TimeInterval = 700
    let point = try ResumePoint(
      session: prepared.session, audioOffset: offset,
      estimatedRemainingDuration: asset.duration - offset, audioAssetSHA256: asset.sha256)
    let selection = SessionSelection(
      journeyID: journey.id, sessionID: prepared.session.id, resumePoint: point)
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let player = RunFakePlayer()
    let run = controller(clock: clock, scheduler: scheduler, player: player, history: store)
    defer { run.stop() }
    let approved = try review(
      catalog: catalog, now: clock.now,
      duration: prepared.session.estimatedDuration - offset, selection: selection)
    XCTAssertEqual(approved.plan.route.map(\.session.id), [prepared.session.id])
    try run.start(review: approved, catalog: catalog)
    scheduler.advance(to: approved.plan.start)
    player.currentTime = offset + 10
    clock.now = approved.plan.start.addingTimeInterval(10)
    run.pause()
    let checkpoint = try XCTUnwrap(store.entries.first)
    XCTAssertTrue(checkpoint.isCheckpoint)
    XCTAssertEqual(checkpoint.record.playedDuration, 10)
    run.resume()

    clock.now = approved.plan.start.addingTimeInterval(player.duration - offset)
    // AVAudioPlayer can rewind before delivering its successful end callback.
    player.currentTime = 0
    player.onCompletion?()
    XCTAssertEqual(run.phase, .resting)
    XCTAssertEqual(try XCTUnwrap(run.records.first).playedDuration, player.duration - offset)
    let reopened = ListeningHistoryStore(storeURL: url)
    XCTAssertNil(reopened.errorMessage)
    XCTAssertEqual(reopened.entries.count, 1)
    let completed = try XCTUnwrap(reopened.entries.first)
    XCTAssertEqual(completed.id, checkpoint.id)
    XCTAssertFalse(completed.isCheckpoint)
    XCTAssertTrue(completed.record.isCompleted)
    XCTAssertEqual(completed.record.playedDuration, player.duration - offset)
  }

  func testHistoryWriteFailureDoesNotInterruptPlaybackAndFinalOutcomeCanRetry() throws {
    let store = ListeningHistoryStore(inMemoryOnly: true)
    store.beforeSave = { throw CocoaError(.fileWriteOutOfSpace) }
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let player = RunFakePlayer()
    let run = controller(clock: clock, scheduler: scheduler, player: player, history: store)
    let approved = try review(catalog: catalog, now: clock.now)
    try run.start(review: approved, catalog: catalog)
    scheduler.advance(to: approved.plan.start)
    XCTAssertEqual(run.phase, .narrating)
    XCTAssertNotNil(store.errorMessage)
    XCTAssertTrue(store.entries.isEmpty)
    player.currentTime = 35
    clock.now = approved.plan.start.addingTimeInterval(35)
    run.stop()
    XCTAssertEqual(run.phase, .stopped)
    store.beforeSave = nil
    store.retrySave()
    XCTAssertNil(store.errorMessage)
    XCTAssertEqual(store.entries.count, 1)
    XCTAssertEqual(store.entries.first?.record.resumePoint?.audioOffset, 35)
    XCTAssertEqual(store.entries.first?.isCheckpoint, false)
  }

  func testAlarmRequestedAndStaleStartNeverStartAudio() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let player = RunFakePlayer()
    let run = controller(clock: clock, scheduler: scheduler, player: player)
    let alarmReview = try review(catalog: catalog, now: clock.now, alarm: true)
    XCTAssertNoThrow(try run.preflight(review: alarmReview, catalog: catalog))
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

  func testOnlyExactScheduledAlarmCanStartAndStopKeepsWakePromise() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let player = RunFakePlayer()
    let run = controller(clock: clock, scheduler: scheduler, player: player)
    let approved = try review(catalog: catalog, now: clock.now, alarm: true)
    let deadline = try XCTUnwrap(approved.plan.wakeAlarm)

    let wrongPlan = ScheduledNapAlarm(
      planID: "other-plan", id: UUID(), deadline: deadline)
    XCTAssertThrowsError(
      try run.start(review: approved, catalog: catalog, scheduledAlarm: wrongPlan)
    ) { XCTAssertEqual($0 as? NapRunError, .alarmUnavailable) }
    let wrongDate = ScheduledNapAlarm(
      planID: approved.plan.id, id: UUID(), deadline: deadline.addingTimeInterval(60))
    XCTAssertThrowsError(
      try run.start(review: approved, catalog: catalog, scheduledAlarm: wrongDate)
    ) { XCTAssertEqual($0 as? NapRunError, .alarmUnavailable) }
    XCTAssertEqual(run.phase, .idle)
    XCTAssertEqual(player.playCount, 0)

    let exact = ScheduledNapAlarm(
      planID: approved.plan.id, id: UUID(), deadline: deadline)
    try run.start(review: approved, catalog: catalog, scheduledAlarm: exact)
    XCTAssertEqual(run.phase, .waiting)
    run.stop()
    XCTAssertEqual(run.phase, .stopped)
    XCTAssertTrue(run.statusMessage.contains("wake alarm was not cancelled"))
    XCTAssertEqual(player.playCount, 0)
  }

  func testStartWindowExpiringDuringAssetPreflightDoesNotBeginAudio() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let player = RunFakePlayer()
    let approved = try review(catalog: catalog, now: clock.now, alarm: true)
    let deadline = try XCTUnwrap(approved.plan.wakeAlarm)
    let receipt = ScheduledNapAlarm(
      planID: approved.plan.id, id: UUID(), deadline: deadline)
    var clockReads = 0
    let run = NapRunController(
      playerFactory: { _ in player },
      clock: {
        clockReads += 1
        return clockReads == 1 ? clock.now : approved.plan.start.addingTimeInterval(0.1)
      },
      scheduler: { delay, action in scheduler.schedule(after: delay, action: action) },
      activateAudioSession: {}, deactivateAudioSession: {},
      observeSystemEvents: false, manageRemoteCommands: false)

    XCTAssertThrowsError(
      try run.start(review: approved, catalog: catalog, scheduledAlarm: receipt)
    ) { XCTAssertEqual($0 as? NapRunError, .staleStart) }
    XCTAssertEqual(run.phase, .idle)
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

  func testCompletedNarrationTransitionsToRainWithoutChangingHistory() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let narration = RunFakePlayer()
    let rain = RunFakeAmbience()
    let history = RunHistoryRecorder()
    let run = controller(
      clock: clock, scheduler: scheduler, player: narration, history: history,
      ambience: rain)
    let approved = try review(
      catalog: catalog, now: clock.now,
      sound: .ambience(id: PreparedAmbience.gentleRainID), drift: 120)

    try run.start(review: approved, catalog: catalog)
    scheduler.advance(to: approved.plan.start)
    XCTAssertEqual(run.phase, .narrating)
    narration.currentTime = narration.duration
    clock.now = approved.plan.start.addingTimeInterval(narration.duration)
    narration.finish()

    XCTAssertEqual(run.phase, .ambience)
    XCTAssertEqual(rain.playCount, 1)
    XCTAssertEqual(run.records.count, 1)
    XCTAssertTrue(try XCTUnwrap(run.records.first).isCompleted)
    XCTAssertEqual(history.saved.filter { !$0.isCheckpoint }.count, 1)
    XCTAssertEqual(
      history.saved.filter { !$0.isCheckpoint }.first?.record.id,
      run.records.first?.id)
    XCTAssertEqual(
      MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyTitle] as? String,
      "Gentle rain")
    XCTAssertEqual(
      MPNowPlayingInfoCenter.default().nowPlayingInfo?[
        MPNowPlayingInfoPropertyPlaybackRate] as? NSNumber, NSNumber(value: 1))

    scheduler.advance(to: approved.plan.deadline)
    XCTAssertEqual(run.phase, .finished)
    XCTAssertGreaterThan(rain.stopCount, 0)
    XCTAssertEqual(run.records.count, 1)
    XCTAssertEqual(history.saved.filter { !$0.isCheckpoint }.count, 1)
  }

  func testSettlingRainPauseRequiresExplicitResumeAndNeverMovesNarrationOrDeadline() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let narration = RunFakePlayer()
    let rain = RunFakeAmbience()
    let history = RunHistoryRecorder()
    let run = controller(
      clock: clock, scheduler: scheduler, player: narration, history: history,
      ambience: rain)
    let approved = try review(
      catalog: catalog, now: clock.now,
      sound: .ambience(id: PreparedAmbience.gentleRainID), settling: 30)
    XCTAssertEqual(approved.plan.narrationStart, approved.plan.start.addingTimeInterval(30))

    try run.start(review: approved, catalog: catalog)
    scheduler.advance(to: approved.plan.start)
    XCTAssertEqual(run.phase, .ambience)
    XCTAssertTrue(run.canPause)
    XCTAssertTrue(history.saved.isEmpty)
    scheduler.advance(to: approved.plan.start.addingTimeInterval(5))
    run.pause()
    XCTAssertEqual(run.phase, .paused)
    XCTAssertEqual(rain.pauseCount, 1)
    XCTAssertEqual(narration.playCount, 0)
    XCTAssertTrue(history.saved.isEmpty)
    scheduler.advance(to: approved.plan.narrationStart.addingTimeInterval(1))
    XCTAssertEqual(run.phase, .paused)
    XCTAssertEqual(narration.playCount, 0)

    run.resume()
    XCTAssertEqual(run.phase, .narrating)
    XCTAssertEqual(narration.playCount, 1)
    XCTAssertEqual(rain.playCount, 1)
    XCTAssertTrue(run.statusMessage.contains("Playing"))
    XCTAssertEqual(approved.plan.deadline, approved.plan.start.addingTimeInterval(1_200))
    run.stop()
  }

  func testRainOnlyInterruptionAndOutputLossPauseUntilExplicitResume() async throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let narration = RunFakePlayer()
    let rain = RunFakeAmbience()
    let history = RunHistoryRecorder()
    let run = controller(
      clock: clock, scheduler: scheduler, player: narration,
      observeSystemEvents: true, history: history, ambience: rain)
    let approved = try review(
      catalog: catalog, now: clock.now, duration: 100,
      sound: .ambience(id: PreparedAmbience.gentleRainID))
    XCTAssertTrue(approved.plan.route.isEmpty)
    try run.start(review: approved, catalog: catalog)
    scheduler.advance(to: approved.plan.start)
    XCTAssertEqual(run.phase, .ambience)
    XCTAssertEqual(narration.playCount, 0)

    NotificationCenter.default.post(
      name: AVAudioSession.interruptionNotification, object: nil,
      userInfo: [
        AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue
      ])
    try await Task.sleep(for: .milliseconds(50))
    XCTAssertEqual(run.phase, .interrupted)
    XCTAssertFalse(run.canResume)
    XCTAssertEqual(rain.pauseCount, 1)
    NotificationCenter.default.post(
      name: AVAudioSession.interruptionNotification, object: nil,
      userInfo: [
        AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue
      ])
    try await Task.sleep(for: .milliseconds(50))
    XCTAssertTrue(run.canResume)
    XCTAssertEqual(rain.playCount, 1)
    run.resume()
    XCTAssertEqual(run.phase, .ambience)
    XCTAssertEqual(rain.playCount, 2)

    NotificationCenter.default.post(
      name: AVAudioSession.routeChangeNotification, object: nil,
      userInfo: [
        AVAudioSessionRouteChangeReasonKey:
          AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue
      ])
    try await Task.sleep(for: .milliseconds(50))
    XCTAssertEqual(run.phase, .interrupted)
    XCTAssertEqual(rain.pauseCount, 2)
    XCTAssertEqual(rain.playCount, 2)
    run.resume()
    XCTAssertEqual(run.phase, .ambience)
    XCTAssertEqual(rain.playCount, 3)
    XCTAssertTrue(history.saved.isEmpty)
    run.stop()
    XCTAssertTrue(run.records.isEmpty)
  }

  func testRainStopsAtExactAndLateDeadlineWithoutCreatingNarrationEvidence() throws {
    for lateness: TimeInterval in [0, 3] {
      let catalog = try PreparedCatalog.load()
      let clock = RunTestClock()
      let scheduler = RunTestScheduler(clock: clock)
      let rain = RunFakeAmbience()
      let history = RunHistoryRecorder()
      let run = controller(
        clock: clock, scheduler: scheduler, player: RunFakePlayer(), history: history,
        ambience: rain)
      let approved = try review(
        catalog: catalog, now: clock.now, duration: 100,
        sound: .ambience(id: PreparedAmbience.gentleRainID))
      try run.start(review: approved, catalog: catalog)
      scheduler.advance(to: approved.plan.start)
      XCTAssertEqual(run.phase, .ambience)

      scheduler.advance(to: approved.plan.deadline.addingTimeInterval(lateness))
      XCTAssertEqual(run.phase, .finished)
      if lateness > 0 {
        XCTAssertTrue(run.statusMessage.contains("after the fixed deadline"))
      }
      XCTAssertEqual(rain.playCount, 1)
      XCTAssertGreaterThan(rain.stopCount, 0)
      XCTAssertTrue(run.records.isEmpty)
      XCTAssertTrue(history.saved.isEmpty)
      XCTAssertNil(MPNowPlayingInfoCenter.default().nowPlayingInfo)
    }
  }

  func testOldRainFailureAfterStopCannotChangeFinishedRun() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let rain = RunFakeAmbience()
    let run = controller(
      clock: clock, scheduler: scheduler, player: RunFakePlayer(), ambience: rain)
    let approved = try review(
      catalog: catalog, now: clock.now, duration: 100,
      sound: .ambience(id: PreparedAmbience.gentleRainID))
    try run.start(review: approved, catalog: catalog)
    scheduler.advance(to: approved.plan.start)
    let oldFailure = rain.onFailure
    run.stop()
    XCTAssertEqual(run.phase, .stopped)
    oldFailure?("late decode error")
    XCTAssertEqual(run.phase, .stopped)
    XCTAssertTrue(run.records.isEmpty)
  }

  func testUnavailableOrFailedRainFallsBackToSilenceAndKeepsWakeReceipt() throws {
    enum RainSetupFailure: Error { case unavailable }
    for scenario in 0..<4 {
      let catalog = try PreparedCatalog.load()
      let clock = RunTestClock()
      let scheduler = RunTestScheduler(clock: clock)
      let rain = RunFakeAmbience()
      if scenario == 2 { rain.prepares = false }
      if scenario == 3 { rain.starts = false }
      let history = RunHistoryRecorder()
      let run = controller(
        clock: clock, scheduler: scheduler, player: RunFakePlayer(), history: history,
        ambience: rain,
        ambienceFactory: scenario == 1 ? { _ in throw RainSetupFailure.unavailable } : nil,
        resolveAmbience: scenario == 0 ? { _ in throw RainSetupFailure.unavailable } : nil)
      let approved = try review(
        catalog: catalog, now: clock.now, duration: 100, alarm: true,
        sound: .ambience(id: PreparedAmbience.gentleRainID))
      let alarm = ScheduledNapAlarm(
        planID: approved.plan.id, id: UUID(),
        deadline: try XCTUnwrap(approved.plan.wakeAlarm))

      try run.start(review: approved, catalog: catalog, scheduledAlarm: alarm)
      scheduler.advance(to: approved.plan.start)
      XCTAssertEqual(run.phase, .resting, "scenario \(scenario)")
      XCTAssertTrue(run.statusMessage.contains("silence"), "scenario \(scenario)")
      XCTAssertTrue(run.records.isEmpty)
      XCTAssertTrue(history.saved.isEmpty)
      run.stop()
      XCTAssertTrue(run.statusMessage.contains("wake alarm was not cancelled"))
    }
  }

  func testSetupOrResumeActivationAtDeadlineCannotRestartRain() throws {
    let catalog = try PreparedCatalog.load()
    for lateOnActivation in [1, 2] {
      let clock = RunTestClock()
      let scheduler = RunTestScheduler(clock: clock)
      let rain = RunFakeAmbience()
      var activations = 0
      var deadline: Date?
      let run = controller(
        clock: clock, scheduler: scheduler, player: RunFakePlayer(),
        activation: {
          activations += 1
          if activations == lateOnActivation { clock.now = try XCTUnwrap(deadline) }
        },
        ambience: rain)
      let approved = try review(
        catalog: catalog, now: clock.now, duration: 100,
        sound: .ambience(id: PreparedAmbience.gentleRainID))
      deadline = approved.plan.deadline
      try run.start(review: approved, catalog: catalog)
      scheduler.advance(to: approved.plan.start)
      if lateOnActivation == 2 {
        XCTAssertEqual(run.phase, .ambience)
        run.pause()
        run.resume()
      }
      XCTAssertEqual(run.phase, .finished)
      XCTAssertEqual(rain.playCount, lateOnActivation == 1 ? 0 : 1)
      XCTAssertTrue(run.records.isEmpty)
    }
  }

  func testRainPlayCrossingDeadlineImmediatelyStopsAtStartAndResume() throws {
    for playThatCrosses in [1, 2] {
      let catalog = try PreparedCatalog.load()
      let clock = RunTestClock()
      let scheduler = RunTestScheduler(clock: clock)
      let rain = RunFakeAmbience()
      let history = RunHistoryRecorder()
      let run = controller(
        clock: clock, scheduler: scheduler, player: RunFakePlayer(), history: history,
        ambience: rain)
      let approved = try review(
        catalog: catalog, now: clock.now, duration: 100,
        sound: .ambience(id: PreparedAmbience.gentleRainID))
      rain.onPlay = {
        if rain.playCount == playThatCrosses { clock.now = approved.plan.deadline }
      }
      try run.start(review: approved, catalog: catalog)
      scheduler.advance(to: approved.plan.start)
      if playThatCrosses == 2 {
        XCTAssertEqual(run.phase, .ambience)
        scheduler.advance(to: approved.plan.start.addingTimeInterval(10))
        run.pause()
        run.resume()
      }
      XCTAssertEqual(run.phase, .finished)
      XCTAssertEqual(rain.playCount, playThatCrosses)
      XCTAssertGreaterThan(rain.stopCount, 0)
      XCTAssertTrue(run.records.isEmpty)
      XCTAssertTrue(history.saved.isEmpty)
    }
  }

  func testNarrationResumePlayCrossingDeadlineImmediatelyStopsAndKeepsPartial() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let narration = RunFakePlayer()
    let history = RunHistoryRecorder()
    let run = controller(
      clock: clock, scheduler: scheduler, player: narration, history: history)
    let approved = try review(catalog: catalog, now: clock.now)
    narration.onPlay = {
      if narration.playCount == 2 { clock.now = approved.plan.deadline }
    }
    try run.start(review: approved, catalog: catalog)
    scheduler.advance(to: approved.plan.start)
    narration.currentTime = 10
    scheduler.advance(to: approved.plan.start.addingTimeInterval(10))
    run.pause()
    run.resume()

    XCTAssertEqual(run.phase, .finished)
    XCTAssertEqual(narration.playCount, 2)
    XCTAssertEqual(run.records.first?.resumePoint?.audioOffset, 10)
    XCTAssertFalse(try XCTUnwrap(run.records.first).isCompleted)
    XCTAssertEqual(history.saved.filter { !$0.isCheckpoint }.count, 1)
  }

  func testDelayedCompletionWhilePausedResumesNextApprovedNarration() throws {
    let catalog = try catalogWithTwoPreparedSessions()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let first = RunFakePlayer()
    let second = RunFakePlayer()
    let rain = RunFakeAmbience()
    let history = RunHistoryRecorder()
    var created = 0
    let run = NapRunController(
      playerFactory: { _ in
        defer { created += 1 }
        return created == 0 ? first : second
      },
      ambienceFactory: { _ in rain },
      resolveAmbience: { _ in URL(fileURLWithPath: "/tmp/rain.wav") },
      clock: { clock.now },
      scheduler: { delay, action in scheduler.schedule(after: delay, action: action) },
      activateAudioSession: {}, deactivateAudioSession: {},
      observeSystemEvents: false, manageRemoteCommands: false, history: history)
    let approved = try review(
      catalog: catalog, now: clock.now, duration: 1_800,
      sound: .ambience(id: PreparedAmbience.gentleRainID))
    XCTAssertEqual(approved.plan.route.count, 2)
    try run.start(review: approved, catalog: catalog)
    scheduler.advance(to: approved.plan.start)
    first.currentTime = first.duration
    clock.now = approved.plan.start.addingTimeInterval(first.duration)
    run.pause()
    let delayedCompletion = first.onCompletion
    delayedCompletion?()

    XCTAssertEqual(run.phase, .paused)
    XCTAssertEqual(run.records.count, 1)
    XCTAssertTrue(try XCTUnwrap(run.records.first).isCompleted)
    XCTAssertEqual(created, 1)
    XCTAssertEqual(rain.playCount, 0)
    run.resume()
    XCTAssertEqual(run.phase, .narrating)
    XCTAssertEqual(created, 2)
    XCTAssertEqual(second.playCount, 1)
    XCTAssertEqual(rain.playCount, 0)
    XCTAssertEqual(history.saved.filter { !$0.isCheckpoint }.count, 1)
    run.stop()
  }

  func testBundledTwoSessionRouteHandoffSecondResumeRainAndFixedDeadline() throws {
    let catalog = try PreparedCatalog.load()
    let journey = try XCTUnwrap(catalog.journeys.first { $0.id == "how-a-car-works" })
    XCTAssertEqual(journey.sessionIDs, ["turning-fuel-into-motion", "air-fuel-and-spark"])
    let first = try XCTUnwrap(catalog.sessions[journey.sessionIDs[0]])
    let second = try XCTUnwrap(catalog.sessions[journey.sessionIDs[1]])
    let firstAsset = try XCTUnwrap(first.narrationAsset)
    let secondAsset = try XCTUnwrap(second.narrationAsset)
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("History.store")
    let store = ListeningHistoryStore(storeURL: url)
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let firstPlayer = RunFakePlayer(duration: firstAsset.duration)
    let secondPlayer = RunFakePlayer(duration: secondAsset.duration)
    let rain = RunFakeAmbience()
    let run = NapRunController(
      playerFactory: { url in
        switch url.deletingPathExtension().lastPathComponent {
        case firstAsset.resource: return firstPlayer
        case secondAsset.resource: return secondPlayer
        default: throw NapDomainError.invalidStartingPoint
        }
      },
      ambienceFactory: { _ in rain },
      resolveAmbience: { _ in URL(fileURLWithPath: "/tmp/rain.wav") },
      clock: { clock.now },
      scheduler: { delay, action in scheduler.schedule(after: delay, action: action) },
      activateAudioSession: {}, deactivateAudioSession: {},
      observeSystemEvents: false, manageRemoteCommands: false, history: store)
    let approved = try review(
      catalog: catalog, now: clock.now,
      duration: first.session.estimatedDuration + second.session.estimatedDuration + 120,
      sound: .ambience(id: PreparedAmbience.gentleRainID))
    XCTAssertEqual(approved.plan.route.map(\.session.id), journey.sessionIDs)
    let fixedDeadline = approved.plan.deadline
    try run.start(review: approved, catalog: catalog)
    scheduler.advance(to: approved.plan.start)
    XCTAssertEqual(run.phase, .narrating)
    clock.now = approved.plan.start.addingTimeInterval(firstPlayer.duration)
    firstPlayer.finish()
    XCTAssertEqual(run.records.map(\.plannedSession.session.id), [first.session.id])
    XCTAssertTrue(try XCTUnwrap(run.records.first).isCompleted)
    XCTAssertEqual(store.history.nextSessionID(in: journey), second.session.id)
    XCTAssertEqual(run.phase, .narrating)
    XCTAssertEqual(secondPlayer.playCount, 1)
    secondPlayer.currentTime = 90
    clock.now = clock.now.addingTimeInterval(90)
    run.stop()
    XCTAssertEqual(store.history.completedSessionIDs(in: journey.id), [first.session.id])

    let reopened = ListeningHistoryStore(storeURL: url)
    XCTAssertNil(reopened.errorMessage)
    let partial = try XCTUnwrap(
      reopened.entries.first { $0.record.plannedSession.session.id == second.session.id })
    XCTAssertEqual(partial.record.resumePoint?.audioOffset, 90)
    let selection = try XCTUnwrap(
      ListeningHistoryNavigation.next(
        in: catalog, history: reopened.history, isNarrationAvailable: { _ in true }))
    XCTAssertEqual(selection.sessionID, second.session.id)
    XCTAssertEqual(selection.resumePoint, partial.record.resumePoint)
    let resumedPlayer = RunFakePlayer(duration: secondAsset.duration)
    let resumedRain = RunFakeAmbience()
    let resumed = controller(
      clock: clock, scheduler: scheduler, player: resumedPlayer,
      history: reopened, ambience: resumedRain)
    let next = try review(
      catalog: catalog, now: clock.now,
      duration: second.session.estimatedDuration + 120, selection: selection,
      sound: .ambience(id: PreparedAmbience.gentleRainID))
    try resumed.start(review: next, catalog: catalog)
    scheduler.advance(to: next.plan.start)
    XCTAssertEqual(resumedPlayer.currentTime, 90)
    clock.now = next.plan.start.addingTimeInterval(secondAsset.duration - 90)
    resumedPlayer.finish()
    XCTAssertEqual(resumed.phase, .ambience)
    XCTAssertGreaterThan(resumedRain.playCount, 0)
    XCTAssertEqual(
      next.plan.deadline,
      next.plan.start.addingTimeInterval(second.session.estimatedDuration + 120))
    XCTAssertEqual(approved.plan.deadline, fixedDeadline)
    XCTAssertNil(reopened.history.nextSessionID(in: journey))
    XCTAssertEqual(reopened.history.completedSessionIDs(in: journey.id), Set(journey.sessionIDs))
    XCTAssertEqual(reopened.entries.count, 3)
    XCTAssertEqual(reopened.entries.first(where: { $0.id == partial.id }), partial)
    scheduler.advance(to: next.plan.deadline)
    XCTAssertEqual(resumed.phase, .finished)
  }

  func testRainFailureWhilePausedKeepsExplicitResumeBeforeSilentRest() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let rain = RunFakeAmbience()
    let history = RunHistoryRecorder()
    let run = controller(
      clock: clock, scheduler: scheduler, player: RunFakePlayer(), history: history,
      ambience: rain)
    let approved = try review(
      catalog: catalog, now: clock.now, duration: 100,
      sound: .ambience(id: PreparedAmbience.gentleRainID))
    try run.start(review: approved, catalog: catalog)
    scheduler.advance(to: approved.plan.start)
    run.pause()
    rain.fail()

    XCTAssertEqual(run.phase, .paused)
    XCTAssertTrue(run.canResume)
    XCTAssertEqual(rain.playCount, 1)
    XCTAssertTrue(run.statusMessage.contains("Resume explicitly"))
    run.resume()
    XCTAssertEqual(run.phase, .resting)
    XCTAssertTrue(run.statusMessage.contains("silence"))
    XCTAssertEqual(rain.playCount, 1)
    XCTAssertTrue(history.saved.isEmpty)
    run.stop()
  }

  func testSettlingRainSurvivesBackgroundAndTransitionsToNarrationOnSchedule() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let narration = RunFakePlayer()
    let rain = RunFakeAmbience()
    let history = RunHistoryRecorder()
    let run = controller(
      clock: clock, scheduler: scheduler, player: narration, history: history,
      ambience: rain)
    let approved = try review(
      catalog: catalog, now: clock.now,
      sound: .ambience(id: PreparedAmbience.gentleRainID), settling: 30)
    try run.start(review: approved, catalog: catalog)
    scheduler.advance(to: approved.plan.start)

    run.scenePhaseChanged(isActive: false)
    XCTAssertEqual(run.phase, .ambience)
    XCTAssertEqual(rain.pauseCount, 0)
    XCTAssertTrue(history.saved.isEmpty)
    scheduler.advance(to: approved.plan.narrationStart)
    XCTAssertEqual(run.phase, .narrating)
    XCTAssertEqual(narration.playCount, 1)
    XCTAssertGreaterThan(rain.stopCount, 0)
    XCTAssertEqual(history.saved.count, 1)
    let checkpoint = try XCTUnwrap(history.saved.first)
    XCTAssertTrue(checkpoint.isCheckpoint)
    XCTAssertEqual(checkpoint.record.plannedSession, approved.plan.route.first)
    XCTAssertEqual(checkpoint.record.startedAt, approved.plan.narrationStart)
    XCTAssertEqual(checkpoint.record.playedDuration, 0)
    XCTAssertEqual(checkpoint.record.resumePoint?.audioOffset, 0)
    XCTAssertFalse(checkpoint.record.isCompleted)
    run.stop()
  }

  func testOldRainFailureAfterSettlingTransitionCannotKillNarration() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let narration = RunFakePlayer()
    let rain = RunFakeAmbience()
    let run = controller(
      clock: clock, scheduler: scheduler, player: narration, ambience: rain)
    let approved = try review(
      catalog: catalog, now: clock.now,
      sound: .ambience(id: PreparedAmbience.gentleRainID), settling: 30)
    try run.start(review: approved, catalog: catalog)
    scheduler.advance(to: approved.plan.start)
    let oldFailure = rain.onFailure
    scheduler.advance(to: approved.plan.narrationStart)
    XCTAssertEqual(run.phase, .narrating)

    oldFailure?("old decode failure")
    XCTAssertEqual(run.phase, .narrating)
    XCTAssertEqual(narration.playCount, 1)
    XCTAssertTrue(run.records.isEmpty)
    run.stop()
  }

  func testOldNarrationFailureAfterCompletionCannotKillRain() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let narration = RunFakePlayer()
    let rain = RunFakeAmbience()
    let history = RunHistoryRecorder()
    let run = controller(
      clock: clock, scheduler: scheduler, player: narration, history: history,
      ambience: rain)
    let approved = try review(
      catalog: catalog, now: clock.now,
      sound: .ambience(id: PreparedAmbience.gentleRainID))
    try run.start(review: approved, catalog: catalog)
    scheduler.advance(to: approved.plan.start)
    let oldFailure = narration.onFailure
    narration.currentTime = narration.duration
    clock.now = approved.plan.start.addingTimeInterval(narration.duration)
    narration.finish()
    XCTAssertEqual(run.phase, .ambience)

    oldFailure?("old decode failure")
    XCTAssertEqual(run.phase, .ambience)
    XCTAssertEqual(rain.playCount, 1)
    XCTAssertEqual(run.records.count, 1)
    XCTAssertEqual(history.saved.filter { !$0.isCheckpoint }.count, 1)
    run.stop()
  }

  func testPausedSettlingFailureAfterNarrationStartStillRequiresResume() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let narration = RunFakePlayer()
    let rain = RunFakeAmbience()
    let history = RunHistoryRecorder()
    let run = controller(
      clock: clock, scheduler: scheduler, player: narration, history: history,
      ambience: rain)
    let approved = try review(
      catalog: catalog, now: clock.now,
      sound: .ambience(id: PreparedAmbience.gentleRainID), settling: 30)
    try run.start(review: approved, catalog: catalog)
    scheduler.advance(to: approved.plan.start)
    run.pause()
    rain.fail()
    scheduler.advance(to: approved.plan.narrationStart.addingTimeInterval(1))

    XCTAssertEqual(run.phase, .paused)
    XCTAssertEqual(narration.playCount, 0)
    XCTAssertTrue(history.saved.isEmpty)
    run.resume()
    XCTAssertEqual(run.phase, .narrating)
    XCTAssertEqual(narration.playCount, 1)
    XCTAssertEqual(rain.playCount, 1)
    run.stop()
  }

  func testSettlingRainFailureAfterBackgroundRequiresFreshReview() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let narration = RunFakePlayer()
    let rain = RunFakeAmbience()
    let history = RunHistoryRecorder()
    let run = controller(
      clock: clock, scheduler: scheduler, player: narration, history: history,
      ambience: rain)
    let approved = try review(
      catalog: catalog, now: clock.now,
      sound: .ambience(id: PreparedAmbience.gentleRainID), settling: 30)
    try run.start(review: approved, catalog: catalog)
    scheduler.advance(to: approved.plan.start)
    XCTAssertEqual(run.phase, .ambience)

    run.scenePhaseChanged(isActive: false)
    rain.fail()
    XCTAssertEqual(run.phase, .failed)
    XCTAssertFalse(run.hasActiveRun)
    scheduler.advance(to: approved.plan.narrationStart)
    XCTAssertEqual(narration.playCount, 0)
    XCTAssertTrue(run.records.isEmpty)
    XCTAssertTrue(history.saved.isEmpty)
  }

  func testBackgroundAfterSettlingRainFallsBackToSilenceRequiresFreshReview() throws {
    let catalog = try PreparedCatalog.load()
    let clock = RunTestClock()
    let scheduler = RunTestScheduler(clock: clock)
    let narration = RunFakePlayer()
    let rain = RunFakeAmbience()
    let history = RunHistoryRecorder()
    let run = controller(
      clock: clock, scheduler: scheduler, player: narration, history: history,
      ambience: rain)
    let approved = try review(
      catalog: catalog, now: clock.now,
      sound: .ambience(id: PreparedAmbience.gentleRainID), settling: 30)
    try run.start(review: approved, catalog: catalog)
    scheduler.advance(to: approved.plan.start)
    rain.fail()
    XCTAssertEqual(run.phase, .resting)
    XCTAssertTrue(run.statusMessage.contains("silence"))

    run.scenePhaseChanged(isActive: false)
    XCTAssertEqual(run.phase, .failed)
    XCTAssertFalse(run.hasActiveRun)
    scheduler.advance(to: approved.plan.narrationStart)
    XCTAssertEqual(narration.playCount, 0)
    XCTAssertTrue(run.records.isEmpty)
    XCTAssertTrue(history.saved.isEmpty)
  }
}
