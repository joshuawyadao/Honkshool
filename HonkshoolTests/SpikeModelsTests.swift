import AVFoundation
import AlarmKit
import Combine
import MediaPlayer
import XCTest

@testable import Honkshool

final class SpikeModelsTests: XCTestCase {
  private let now = Date(timeIntervalSince1970: 1_000)

  @MainActor
  func testUITestPreferencesDoNotOverwriteRealAlarmOrDuration() {
    let keys = ["feasibilityAlarmID", "feasibilityAlarmDate", "preferredRestMinutes"]
    let standard = SpikePreferences.store(uiTesting: false)
    XCTAssertTrue(standard === UserDefaults.standard)
    let original = keys.map { standard.object(forKey: $0) as? NSObject }
    let isolated = SpikePreferences.store(uiTesting: true)
    let previousTestValues = keys.map { isolated.object(forKey: $0) }
    defer {
      for (key, value) in zip(keys, previousTestValues) {
        if let value {
          isolated.set(value, forKey: key)
        } else {
          isolated.removeObject(forKey: key)
        }
      }
    }
    isolated.set("synthetic-alarm", forKey: keys[0])
    isolated.set(1_000.0, forKey: keys[1])
    isolated.set(45, forKey: keys[2])

    XCTAssertEqual(SpikePreferences.store(uiTesting: true).integer(forKey: keys[2]), 45)
    for (key, expected) in zip(keys, original) {
      XCTAssertEqual(standard.object(forKey: key) as? NSObject, expected)
    }
  }

  @MainActor
  func testLateCompletionCannotRestartAudioAfterStop() {
    let audio = AudioSpikeController(speechSynthesizer: FakeSpeechSynthesizer())
    audio.stop()
    // Replay a completion arriving after the user has already stopped playback.
    audio.speechSynthesizer(
      AVSpeechSynthesizer(), didFinish: AVSpeechUtterance(string: "Cancelled narration")
    )
    XCTAssertEqual(audio.phase, .stopped)
    XCTAssertNil(MPNowPlayingInfoCenter.default().nowPlayingInfo)
    audio.stop()
  }

  @MainActor
  func testNarrationAdvertisesPausableMediaInsteadOfLiveStream() {
    let audio = AudioSpikeController(speechSynthesizer: FakeSpeechSynthesizer())
    defer { audio.stop() }
    audio.startNarration(
      script: "A calm test sentence.", title: "Test", transitionToAmbience: false)
    XCTAssertEqual(
      MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyIsLiveStream]
        as? Bool,
      false
    )
  }

  func testAlarmDisabledRunIsReadyWithoutAuthorizationOrSchedule() {
    let result = FeasibilityRunGate.evaluate(
      alarmEnabled: false,
      authorization: .denied,
      schedule: .notScheduled,
      now: now
    )

    XCTAssertEqual(result, .ready)
  }

  func testAlarmEnabledRunRequiresAuthorization() {
    let result = FeasibilityRunGate.evaluate(
      alarmEnabled: true,
      authorization: .denied,
      schedule: .notScheduled,
      now: now
    )

    XCTAssertEqual(
      result,
      .blocked(
        "Alarm-enabled runs require AlarmKit authorization before playback starts."
      )
    )
  }

  func testAlarmEnabledRunRequiresFutureScheduledAlarm() {
    let result = FeasibilityRunGate.evaluate(
      alarmEnabled: true,
      authorization: .authorized,
      schedule: .scheduled(now),
      now: now
    )

    XCTAssertEqual(
      result,
      .blocked(
        "Alarm-enabled runs require a successfully scheduled future alarm."
      )
    )
  }

  func testAlarmEnabledRunIsReadyAfterSuccessfulSchedule() {
    let result = FeasibilityRunGate.evaluate(
      alarmEnabled: true,
      authorization: .authorized,
      schedule: .scheduled(now.addingTimeInterval(60)),
      now: now
    )

    XCTAssertEqual(result, .ready)
  }

  func testNarrationTransitionUsesSelectedFallback() {
    XCTAssertEqual(
      PlaybackTransitionPolicy.destinationAfterNarration(ambienceEnabled: true),
      .ambience
    )
    XCTAssertEqual(
      PlaybackTransitionPolicy.destinationAfterNarration(ambienceEnabled: false),
      .silence
    )
  }

  func testInterruptionPolicyWaitsForManualResumeAfterSystemInterruption() {
    XCTAssertEqual(
      SpikeInterruptionPolicy.action(for: .began),
      .pause
    )
    XCTAssertEqual(
      SpikeInterruptionPolicy.action(for: .ended(systemSuggestsResume: true)),
      .waitForManualResume
    )
    XCTAssertEqual(
      SpikeInterruptionPolicy.action(for: .outputRouteDisconnected),
      .pause
    )
  }

  func testRestDurationPolicyClampsCustomDurations() {
    XCTAssertEqual(RestDurationPolicy.normalized(minutes: 1), 5)
    XCTAssertEqual(RestDurationPolicy.normalized(minutes: 35), 35)
    XCTAssertEqual(RestDurationPolicy.normalized(minutes: 300), 180)
  }

  func testWakeDateUsesTheWholeRestWindow() {
    let wakeDate = RestDurationPolicy.wakeDate(startingAt: now, minutes: 35)

    XCTAssertEqual(wakeDate.timeIntervalSince(now), 35 * 60)
  }
}

private final class FakeSpeechSynthesizer: AVSpeechSynthesizer {
  var utterances: [AVSpeechUtterance] = []
  var onStop: (() -> Void)?
  var canContinue = true
  private var testSpeaking = false
  private var testPaused = false

  override var isSpeaking: Bool { testSpeaking }
  override var isPaused: Bool { testPaused }

  override func speak(_ utterance: AVSpeechUtterance) {
    utterances.append(utterance)
    testSpeaking = true
    testPaused = false
  }

  override func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool {
    testSpeaking = false
    testPaused = false
    onStop?()
    return true
  }

  override func pauseSpeaking(at boundary: AVSpeechBoundary) -> Bool {
    testPaused = true
    return true
  }

  override func continueSpeaking() -> Bool {
    guard canContinue else { return false }
    testPaused = false
    testSpeaking = true
    return true
  }
}

// The test and controller schedule buffers on the main actor; rendering never reads this counter.
private final class TrackingAmbiencePlayer: AVAudioPlayerNode, @unchecked Sendable {
  private(set) var scheduledBufferCount = 0

  override func scheduleBuffer(
    _ buffer: AVAudioPCMBuffer,
    at when: AVAudioTime?,
    options: AVAudioPlayerNodeBufferOptions = [],
    completionHandler: AVAudioNodeCompletionHandler? = nil
  ) {
    scheduledBufferCount += 1
    super.scheduleBuffer(buffer, at: when, options: options, completionHandler: completionHandler)
  }
}

@MainActor
final class PlaybackRegressionTests: XCTestCase {
  func testRouteLossRestoresPurgedAmbienceLoopWithRunningEngine() async throws {
    let speech = FakeSpeechSynthesizer()
    let engine = AVAudioEngine()
    let player = TrackingAmbiencePlayer()
    let audio = AudioSpikeController(
      speechSynthesizer: speech, ambienceEngine: engine, ambiencePlayer: player
    )
    defer { audio.stop() }
    audio.startNarration(script: "Test", title: "Test", transitionToAmbience: true)
    let utterance = try XCTUnwrap(speech.utterances.first)
    _ = speech.stopSpeaking(at: .immediate)
    audio.speechSynthesizer(speech, didFinish: utterance)
    XCTAssertEqual(player.scheduledBufferCount, 1)
    NotificationCenter.default.post(
      name: AVAudioSession.routeChangeNotification, object: nil,
      userInfo: [
        AVAudioSessionRouteChangeReasonKey:
          AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue
      ]
    )
    await wait(for: .interrupted, in: audio)
    player.stop()  // Reproduce a purged queue without stopping the engine.
    XCTAssertTrue(engine.isRunning)
    audio.resume()
    XCTAssertEqual(player.scheduledBufferCount, 2)
    XCTAssertTrue(player.isPlaying)
    XCTAssertEqual(audio.phase, .ambience)
  }

  func testManualResumeReactivatesAudioBeforeContinuingSpeech() {
    let speech = FakeSpeechSynthesizer()
    var activations = 0
    let audio = AudioSpikeController(speechSynthesizer: speech) {
      activations += 1
      if activations == 2 { XCTAssertTrue(speech.isPaused) }
    }
    defer { audio.stop() }
    audio.startNarration(script: "Test", title: "Test", transitionToAmbience: false)
    audio.pause()
    audio.resume()
    XCTAssertEqual(activations, 2)
    XCTAssertEqual(audio.phase, .narrating)
  }

  func testResumeActivationFailureNeverAdvertisesPlayingAudio() {
    enum ActivationError: Error { case unavailable }
    let speech = FakeSpeechSynthesizer()
    var activations = 0
    let audio = AudioSpikeController(speechSynthesizer: speech) {
      activations += 1
      if activations > 1 { throw ActivationError.unavailable }
    }
    defer { audio.stop() }
    audio.startNarration(script: "Test", title: "Test", transitionToAmbience: false)
    audio.pause()
    audio.resume()
    XCTAssertEqual(audio.phase, .failed)
    XCTAssertFalse(speech.isSpeaking)
    XCTAssertNil(MPNowPlayingInfoCenter.default().nowPlayingInfo)
  }

  func testSpeechResumeFailureNeverAdvertisesPlayingAudio() {
    let speech = FakeSpeechSynthesizer()
    let audio = AudioSpikeController(speechSynthesizer: speech)
    defer { audio.stop() }
    audio.startNarration(script: "Test", title: "Test", transitionToAmbience: false)
    audio.pause()
    speech.canContinue = false
    audio.resume()
    XCTAssertEqual(audio.phase, .failed)
    XCTAssertNil(MPNowPlayingInfoCenter.default().nowPlayingInfo)
  }

  func testInterruptedAmbienceRestartsStoppedEngineOnExplicitResume() async throws {
    let speech = FakeSpeechSynthesizer()
    let engine = AVAudioEngine()
    let audio = AudioSpikeController(speechSynthesizer: speech, ambienceEngine: engine)
    defer { audio.stop() }
    audio.startNarration(script: "Test", title: "Test", transitionToAmbience: true)
    let utterance = try XCTUnwrap(speech.utterances.first)
    _ = speech.stopSpeaking(at: .immediate)
    audio.speechSynthesizer(speech, didFinish: utterance)
    XCTAssertEqual(audio.phase, .ambience)
    NotificationCenter.default.post(
      name: AVAudioSession.interruptionNotification, object: nil,
      userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]
    )
    await wait(for: .interrupted, in: audio)
    engine.stop()
    XCTAssertFalse(engine.isRunning)
    audio.resume()
    XCTAssertTrue(engine.isRunning)
    XCTAssertEqual(audio.phase, .ambience)
  }

  func testStopInvalidatesTheUtteranceBeforeSynchronousCompletion() throws {
    let speech = FakeSpeechSynthesizer()
    let audio = AudioSpikeController(speechSynthesizer: speech)
    audio.startNarration(script: "Test", title: "Test", transitionToAmbience: true)
    let utterance = try XCTUnwrap(speech.utterances.first)
    speech.onStop = { [weak audio] in
      audio?.speechSynthesizer(speech, didFinish: utterance)
    }
    audio.stop()
    XCTAssertEqual(audio.phase, .stopped)
    XCTAssertNil(MPNowPlayingInfoCenter.default().nowPlayingInfo)
  }

  func testReplacingNarrationIgnoresOldCompletionAndCancellation() throws {
    let speech = FakeSpeechSynthesizer()
    let audio = AudioSpikeController(speechSynthesizer: speech)
    defer { audio.stop() }
    audio.startNarration(script: "First", title: "First", transitionToAmbience: true)
    let old = try XCTUnwrap(speech.utterances.first)
    audio.startNarration(script: "Second", title: "Second", transitionToAmbience: false)
    audio.speechSynthesizer(speech, didFinish: old)
    audio.speechSynthesizer(speech, didCancel: old)
    XCTAssertEqual(audio.phase, .narrating)
    XCTAssertEqual(
      MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyTitle] as? String,
      "Second"
    )
  }

  func testNaturalCompletionStillTransitionsToSilenceAndIsHandledOnce() throws {
    let speech = FakeSpeechSynthesizer()
    let audio = AudioSpikeController(speechSynthesizer: speech)
    audio.startNarration(script: "Test", title: "Test", transitionToAmbience: false)
    let utterance = try XCTUnwrap(speech.utterances.first)
    audio.speechSynthesizer(speech, didFinish: utterance)
    XCTAssertEqual(audio.phase, .stopped)
    let events = audio.eventLog.count
    audio.speechSynthesizer(speech, didFinish: utterance)
    XCTAssertEqual(audio.eventLog.count, events)
  }

  func testRemoteTogglePausesAndResumesCurrentNarration() {
    let speech = FakeSpeechSynthesizer()
    let audio = AudioSpikeController(speechSynthesizer: speech)
    defer { audio.stop() }
    audio.startNarration(script: "Test", title: "Test", transitionToAmbience: false)
    audio.togglePlayback()
    XCTAssertEqual(audio.phase, .paused)
    XCTAssertTrue(speech.isPaused)
    audio.togglePlayback()
    XCTAssertEqual(audio.phase, .narrating)
    XCTAssertFalse(speech.isPaused)
    XCTAssertTrue(MPRemoteCommandCenter.shared().togglePlayPauseCommand.isEnabled)
    XCTAssertFalse(MPRemoteCommandCenter.shared().changePlaybackPositionCommand.isEnabled)
  }

  func testSystemInterruptionPausesAndRequiresExplicitResume() async {
    let speech = FakeSpeechSynthesizer()
    let audio = AudioSpikeController(speechSynthesizer: speech)
    defer { audio.stop() }
    audio.startNarration(script: "Test", title: "Test", transitionToAmbience: false)
    NotificationCenter.default.post(
      name: AVAudioSession.interruptionNotification,
      object: nil,
      userInfo: [
        AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue
      ]
    )
    await wait(for: .interrupted, in: audio)
    XCTAssertTrue(speech.isPaused)

    NotificationCenter.default.post(
      name: AVAudioSession.interruptionNotification,
      object: nil,
      userInfo: [
        AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
        AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume
          .rawValue,
      ]
    )
    for _ in 0..<5 { await Task.yield() }
    XCTAssertEqual(audio.phase, .interrupted)
    XCTAssertTrue(audio.statusMessage.contains("Resume manually"))
    audio.resume()
    XCTAssertEqual(audio.phase, .narrating)
  }

  func testDisconnectedOutputPausesUntilExplicitResume() async {
    let speech = FakeSpeechSynthesizer()
    let audio = AudioSpikeController(speechSynthesizer: speech)
    defer { audio.stop() }
    audio.startNarration(script: "Test", title: "Test", transitionToAmbience: false)
    NotificationCenter.default.post(
      name: AVAudioSession.routeChangeNotification,
      object: nil,
      userInfo: [
        AVAudioSessionRouteChangeReasonKey:
          AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue
      ]
    )
    await wait(for: .interrupted, in: audio)
    XCTAssertTrue(speech.isPaused)
    XCTAssertTrue(audio.statusMessage.contains("Audio output disconnected"))
    audio.resume()
    XCTAssertEqual(audio.phase, .narrating)
  }

  func testMediaServicesResetInvalidatesAudioUntilControllerRecreation() async {
    let speech = FakeSpeechSynthesizer()
    let audio = AudioSpikeController(speechSynthesizer: speech)
    audio.startNarration(script: "Test", title: "Test", transitionToAmbience: true)
    NotificationCenter.default.post(
      name: AVAudioSession.mediaServicesWereResetNotification, object: nil
    )
    await wait(for: .failed, in: audio)
    XCTAssertFalse(speech.isSpeaking)
    XCTAssertNil(MPNowPlayingInfoCenter.default().nowPlayingInfo)
    audio.resume()
    audio.togglePlayback()
    XCTAssertEqual(audio.phase, .failed)
    XCTAssertFalse(speech.isSpeaking)
    audio.stop()
    XCTAssertFalse(audio.canStartNewRun)
    let priorCount = speech.utterances.count
    audio.startNarration(script: "New", title: "New", transitionToAmbience: false)
    XCTAssertEqual(speech.utterances.count, priorCount)
    XCTAssertEqual(audio.phase, .failed)
    NotificationCenter.default.post(
      name: AVAudioSession.mediaServicesWereResetNotification, object: nil
    )
    for _ in 0..<5 { await Task.yield() }
    XCTAssertEqual(audio.phase, .failed)
  }

  func testIdleAndStoppedMediaResetsAlsoPreventNewRuns() async {
    for startsStopped in [false, true] {
      let speech = FakeSpeechSynthesizer()
      let audio = AudioSpikeController(speechSynthesizer: speech)
      if startsStopped { audio.stop() }
      NotificationCenter.default.post(
        name: AVAudioSession.mediaServicesWereResetNotification, object: nil
      )
      await wait(for: .failed, in: audio)
      XCTAssertFalse(audio.canStartNewRun)
      audio.stop()
      XCTAssertFalse(audio.canStartNewRun)
      audio.startNarration(script: "New", title: "New", transitionToAmbience: true)
      XCTAssertTrue(speech.utterances.isEmpty)
      XCTAssertEqual(audio.phase, .failed)
    }
  }

  private func wait(for phase: PlaybackPhase, in audio: AudioSpikeController) async {
    if audio.phase == phase { return }
    let changed = expectation(description: "Playback reached \(phase.rawValue)")
    let observation = audio.$phase.dropFirst().sink { updatedPhase in
      if updatedPhase == phase { changed.fulfill() }
    }
    await fulfillment(of: [changed], timeout: 2)
    observation.cancel()
  }
}

@MainActor
private final class FakeAlarmSystem: AlarmSystem {
  var authorization: AlarmAuthorizationSnapshot = .authorized
  var records: [SystemAlarmRecord] = []
  var failCancellation = false
  var failReads = false
  var failScheduling = false
  var scheduledIDs: [UUID] = []
  var cancelledIDs: [UUID] = []
  var continuation: AsyncStream<Void>.Continuation?
  var onSubscription: (() -> Void)?

  enum Failure: Error { case requested }

  func requestAuthorization() async throws -> AlarmAuthorizationSnapshot { authorization }
  func alarms() throws -> [SystemAlarmRecord] {
    if failReads { throw Failure.requested }
    return records
  }
  func schedule(id: UUID, at date: Date) async throws {
    if failScheduling { throw Failure.requested }
    scheduledIDs.append(id)
    records = [
      SystemAlarmRecord(id: id, state: .scheduled, originalDate: date, countdownFireDate: nil)
    ]
  }
  func cancel(id: UUID) throws {
    if failCancellation { throw Failure.requested }
    cancelledIDs.append(id)
    records.removeAll { $0.id == id }
  }
  func updates() -> AsyncStream<Void> {
    AsyncStream {
      continuation = $0
      onSubscription?()
    }
  }
}

@MainActor
final class AlarmRegressionTests: XCTestCase {
  private let now = Date(timeIntervalSince1970: 1_000)
  private var suiteName = ""
  private var defaults: UserDefaults!

  override func setUp() {
    suiteName = "HonkshoolTests.\(UUID().uuidString)"
    defaults = UserDefaults(suiteName: suiteName)!
  }

  override func tearDown() {
    defaults.removePersistentDomain(forName: suiteName)
  }

  func testSnoozeRefreshUsesSystemDeadlineAndSurvivesRelaunch() async throws {
    let system = FakeAlarmSystem()
    let service = AlarmSpikeService(system: system, defaults: defaults, now: { self.now })
    let scheduled = await service.schedule(at: now.addingTimeInterval(60))
    XCTAssertTrue(scheduled)
    let id = try XCTUnwrap(system.scheduledIDs.first)
    let snoozeDate = now.addingTimeInterval(600)
    system.records = [
      SystemAlarmRecord(
        id: id, state: .countdown, originalDate: now.addingTimeInterval(60),
        countdownFireDate: snoozeDate
      )
    ]
    service.refresh()
    XCTAssertEqual(service.alarmStatus.phase, .snoozed)
    XCTAssertEqual(service.scheduledDate, snoozeDate)
    let reopened = AlarmSpikeService(
      system: system, defaults: defaults, now: { self.now.addingTimeInterval(200) })
    XCTAssertEqual(reopened.alarmStatus, service.alarmStatus)
    XCTAssertTrue(reopened.cancel())
    XCTAssertEqual(system.cancelledIDs, [id])
    XCTAssertFalse(reopened.hasTrackedAlarm)
  }

  func testMissingSnoozeDeadlineNeverFallsBackToOriginalAlarmTime() async throws {
    let system = FakeAlarmSystem()
    let service = AlarmSpikeService(system: system, defaults: defaults, now: { self.now })
    _ = await service.schedule(at: now.addingTimeInterval(60))
    let id = try XCTUnwrap(system.scheduledIDs.first)
    system.records = [
      SystemAlarmRecord(
        id: id, state: .countdown, originalDate: now.addingTimeInterval(60), countdownFireDate: nil
      )
    ]
    service.refresh()
    XCTAssertEqual(service.alarmStatus.phase, .snoozed)
    XCTAssertNil(service.scheduledDate)
    XCTAssertTrue(service.hasTrackedAlarm)
  }

  func testAlarmUpdatesReconcileRingingAndRemoval() async throws {
    let system = FakeAlarmSystem()
    let service = AlarmSpikeService(system: system, defaults: defaults, now: { self.now })
    _ = await service.schedule(at: now.addingTimeInterval(60))
    let id = try XCTUnwrap(system.scheduledIDs.first)
    let subscribed = expectation(description: "Subscribed to system alarm updates")
    system.onSubscription = { subscribed.fulfill() }
    let task = Task { await service.observeUpdates() }
    defer { task.cancel() }
    await fulfillment(of: [subscribed], timeout: 2)
    let ringing = expectation(description: "Ringing state published")
    let removed = expectation(description: "Removed alarm published")
    let observation = service.$alarmStatus.dropFirst().sink { status in
      if status.phase == .alerting { ringing.fulfill() }
      if status.phase == .none { removed.fulfill() }
    }
    defer { observation.cancel() }
    system.records = [
      SystemAlarmRecord(id: id, state: .alerting, originalDate: now, countdownFireDate: nil)
    ]
    system.continuation?.yield(())
    await fulfillment(of: [ringing], timeout: 2)
    XCTAssertEqual(service.alarmStatus.phase, .alerting)
    XCTAssertNil(service.scheduledDate)
    system.records = []
    system.continuation?.yield(())
    await fulfillment(of: [removed], timeout: 2)
    XCTAssertFalse(service.hasTrackedAlarm)
    XCTAssertEqual(service.alarmStatus.phase, .none)
  }

  func testFailedCancellationRetainsIdentityAndBlocksReplacement() async {
    let system = FakeAlarmSystem()
    let service = AlarmSpikeService(system: system, defaults: defaults, now: { self.now })
    _ = await service.schedule(at: now.addingTimeInterval(60))
    system.failCancellation = true
    XCTAssertFalse(service.cancel())
    XCTAssertTrue(service.hasTrackedAlarm)
    let replaced = await service.schedule(at: now.addingTimeInterval(120))
    XCTAssertFalse(replaced)
    XCTAssertEqual(system.scheduledIDs.count, 1)
    system.failCancellation = false
    XCTAssertTrue(service.cancel())
  }

  func testReadFailureHidesStaleTimeAndPreservesCancellation() async {
    let system = FakeAlarmSystem()
    let service = AlarmSpikeService(system: system, defaults: defaults, now: { self.now })
    _ = await service.schedule(at: now.addingTimeInterval(60))
    system.failReads = true
    service.refresh()
    XCTAssertEqual(service.alarmStatus.phase, .unavailable)
    XCTAssertNil(service.scheduledDate)
    XCTAssertTrue(service.hasTrackedAlarm)
    XCTAssertTrue(service.cancel())
  }

  func testDeniedOrPastAlarmNeverReachesSystemScheduler() async {
    let system = FakeAlarmSystem()
    system.authorization = .denied
    let service = AlarmSpikeService(system: system, defaults: defaults, now: { self.now })
    let denied = await service.schedule(at: now.addingTimeInterval(60))
    XCTAssertFalse(denied)
    system.authorization = .authorized
    let past = await service.schedule(at: now)
    XCTAssertFalse(past)
    XCTAssertTrue(system.scheduledIDs.isEmpty)
    XCTAssertFalse(service.hasTrackedAlarm)
  }

  func testFailedScheduleCannotPassGateAndReconcilesMissingAlarm() async {
    let system = FakeAlarmSystem()
    system.failScheduling = true
    let service = AlarmSpikeService(system: system, defaults: defaults, now: { self.now })
    let scheduled = await service.schedule(at: now.addingTimeInterval(60))
    XCTAssertFalse(scheduled)
    XCTAssertEqual(service.alarmStatus.phase, .unavailable)
    XCTAssertEqual(service.scheduleSnapshot, .notScheduled)
    XCTAssertTrue(service.hasTrackedAlarm)
    service.refresh()
    XCTAssertFalse(service.hasTrackedAlarm)
    XCTAssertEqual(service.alarmStatus.phase, .none)
  }

  func testPausedAndRepeatedSnoozeDoNotRetainPreviousDeadline() async throws {
    let system = FakeAlarmSystem()
    let service = AlarmSpikeService(system: system, defaults: defaults, now: { self.now })
    _ = await service.schedule(at: now.addingTimeInterval(60))
    let id = try XCTUnwrap(system.scheduledIDs.first)
    system.records = [
      SystemAlarmRecord(id: id, state: .paused, originalDate: now, countdownFireDate: nil)
    ]
    service.refresh()
    XCTAssertEqual(service.alarmStatus.phase, .paused)
    XCTAssertNil(service.scheduledDate)
    for offset in [600.0, 1_200.0] {
      let deadline = now.addingTimeInterval(offset)
      system.records = [
        SystemAlarmRecord(
          id: id, state: .countdown, originalDate: now, countdownFireDate: deadline
        )
      ]
      service.refresh()
      XCTAssertEqual(service.alarmStatus.phase, .snoozed)
      XCTAssertEqual(service.scheduledDate, deadline)
    }
  }

  func testAuthorizationRefreshesAfterSystemGrant() async {
    let system = FakeAlarmSystem()
    system.authorization = .notDetermined
    let service = AlarmSpikeService(system: system, defaults: defaults, now: { self.now })
    XCTAssertEqual(service.authorization, .notDetermined)
    system.authorization = .authorized
    await service.requestAuthorization()
    XCTAssertEqual(service.authorization, .authorized)
    XCTAssertEqual(service.alarmStatus.phase, .none)
    XCTAssertEqual(service.statusMessage, "Authorized. No Honkshool alarm is scheduled.")
  }

  func testCancelWithoutTrackedAlarmIsIdempotent() {
    let system = FakeAlarmSystem()
    let service = AlarmSpikeService(system: system, defaults: defaults, now: { self.now })
    XCTAssertTrue(service.cancel())
    XCTAssertTrue(system.cancelledIDs.isEmpty)
    XCTAssertFalse(service.hasTrackedAlarm)
  }

  func testProductSnoozeIntervalRemainsNineMinutes() {
    XCTAssertEqual(HonkshoolAlarmMetadata.snoozeSeconds, 9 * 60)
  }
}
