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

  func testRelativeWakeEstimateAdvancesWithTheProposedStartTime() {
    let earlier = RestDurationPolicy.wakeDate(startingAt: now, minutes: 35)
    let later = RestDurationPolicy.wakeDate(
      startingAt: now.addingTimeInterval(600), minutes: 35
    )
    XCTAssertEqual(later.timeIntervalSince(earlier), 600)
  }
}

private final class FakeSpeechSynthesizer: AVSpeechSynthesizer {
  var utterances: [AVSpeechUtterance] = []
  var onStop: (() -> Void)?
  var canContinue = true
  var delaysPause = false
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
    if !delaysPause { testPaused = true }
    return true
  }

  func completePause() { testPaused = true }

  override func continueSpeaking() -> Bool {
    guard canContinue else { return false }
    testPaused = false
    testSpeaking = true
    return true
  }
}

@MainActor
private final class FakePreparedNarrationPlayer: PreparedNarrationPlaying {
  var onCompletion: (() -> Void)?
  var onFailure: ((String) -> Void)?
  var isPlaying = false
  var currentTime: TimeInterval = 12.5
  var duration: TimeInterval = 727.625
  var canPrepare = true
  var canPlay = true
  var onPrepare: (() -> Void)?
  private(set) var playCount = 0
  private(set) var pauseCount = 0
  private(set) var stopCount = 0

  func prepareToPlay() -> Bool {
    onPrepare?()
    return canPrepare
  }
  func play() -> Bool {
    playCount += 1
    isPlaying = canPlay
    return canPlay
  }
  func pause() {
    pauseCount += 1
    isPlaying = false
  }
  func stop() {
    stopCount += 1
    isPlaying = false
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
  func testPreparedNarrationUsesFixedDeadlineAndSupportsPauseResume() throws {
    let player = FakePreparedNarrationPlayer()
    let now = Date(timeIntervalSince1970: 1_000)
    var scheduledDelay: TimeInterval?
    var deadlineAction: (@MainActor () -> Void)?
    var deadlineCancelled = false
    var activations = 0
    let audio = AudioSpikeController(
      preparedNarrationPlayerFactory: { _ in player },
      clock: { now },
      deadlineScheduler: { delay, action in
        scheduledDelay = delay
        deadlineAction = action
        return { deadlineCancelled = true }
      },
      activateAudioSession: { activations += 1 }
    )
    defer { audio.stop() }

    audio.startPreparedNarration(
      url: URL(fileURLWithPath: "/prepared.wav"), title: "Prepared",
      transitionToAmbience: false, wakeDeadline: now.addingTimeInterval(90))

    XCTAssertEqual(audio.phase, .narrating)
    XCTAssertEqual(player.playCount, 1)
    XCTAssertEqual(scheduledDelay, 90)
    XCTAssertEqual(activations, 1)
    XCTAssertEqual(
      MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration]
        as? TimeInterval,
      player.duration)

    player.currentTime = 42
    audio.pause()
    XCTAssertEqual(audio.phase, .paused)
    XCTAssertEqual(player.pauseCount, 1)
    XCTAssertEqual(
      MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime]
        as? TimeInterval,
      42)
    audio.resume()
    XCTAssertEqual(audio.phase, .narrating)
    XCTAssertEqual(player.playCount, 2)
    XCTAssertEqual(activations, 2)

    try XCTUnwrap(deadlineAction)()
    XCTAssertEqual(audio.phase, .stopped)
    XCTAssertEqual(player.stopCount, 1)
    XCTAssertTrue(deadlineCancelled)
    XCTAssertTrue(audio.statusMessage.contains("wake deadline"))
    XCTAssertNil(MPNowPlayingInfoCenter.default().nowPlayingInfo)
  }

  func testPreparedNarrationInterruptionPublishesPausedElapsedTime() async throws {
    let player = FakePreparedNarrationPlayer()
    let audio = AudioSpikeController(
      preparedNarrationPlayerFactory: { _ in player },
      deadlineScheduler: { _, _ in {} },
      activateAudioSession: {}
    )
    defer { audio.stop() }
    audio.startPreparedNarration(
      url: URL(fileURLWithPath: "/prepared.wav"), title: "Prepared",
      transitionToAmbience: false, wakeDeadline: .now.addingTimeInterval(90))
    player.currentTime = 53

    NotificationCenter.default.post(
      name: AVAudioSession.interruptionNotification, object: nil,
      userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]
    )
    await wait(for: .interrupted, in: audio)

    XCTAssertEqual(player.pauseCount, 1)
    XCTAssertEqual(
      MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime]
        as? TimeInterval,
      53)
  }

  func testPreparedNarrationRejectsPastDeadlineBeforeLoadingPlayer() {
    let now = Date(timeIntervalSince1970: 1_000)
    var factoryCalls = 0
    let audio = AudioSpikeController(
      preparedNarrationPlayerFactory: { _ in
        factoryCalls += 1
        return FakePreparedNarrationPlayer()
      },
      clock: { now },
      activateAudioSession: {}
    )
    defer { audio.stop() }

    audio.startPreparedNarration(
      url: URL(fileURLWithPath: "/prepared.wav"), title: "Prepared",
      transitionToAmbience: false, wakeDeadline: now)

    XCTAssertEqual(audio.phase, .failed)
    XCTAssertEqual(factoryCalls, 0)
    XCTAssertTrue(audio.statusMessage.contains("future wake deadline"))
  }

  func testPreparedNarrationSchedulesRemainingTimeAfterSlowSetup() {
    let player = FakePreparedNarrationPlayer()
    var currentTime = Date(timeIntervalSince1970: 1_000)
    player.onPrepare = { currentTime.addTimeInterval(10) }
    var scheduledDelay: TimeInterval?
    let audio = AudioSpikeController(
      preparedNarrationPlayerFactory: { _ in player },
      clock: { currentTime },
      deadlineScheduler: { delay, _ in
        scheduledDelay = delay
        return {}
      },
      activateAudioSession: {}
    )
    defer { audio.stop() }

    audio.startPreparedNarration(
      url: URL(fileURLWithPath: "/prepared.wav"), title: "Prepared",
      transitionToAmbience: false,
      wakeDeadline: currentTime.addingTimeInterval(90))

    XCTAssertEqual(audio.phase, .narrating)
    XCTAssertEqual(player.playCount, 1)
    XCTAssertEqual(scheduledDelay, 80)
  }

  func testPreparedNarrationDoesNotStartIfSetupPassesWakeDeadline() {
    let player = FakePreparedNarrationPlayer()
    var currentTime = Date(timeIntervalSince1970: 1_000)
    player.onPrepare = { currentTime.addTimeInterval(91) }
    let audio = AudioSpikeController(
      preparedNarrationPlayerFactory: { _ in player },
      clock: { currentTime },
      activateAudioSession: {}
    )
    defer { audio.stop() }

    audio.startPreparedNarration(
      url: URL(fileURLWithPath: "/prepared.wav"), title: "Prepared",
      transitionToAmbience: false,
      wakeDeadline: currentTime.addingTimeInterval(90))

    XCTAssertEqual(audio.phase, .stopped)
    XCTAssertEqual(player.playCount, 0)
    XCTAssertTrue(audio.statusMessage.contains("wake deadline"))
  }

  func testPausedPreparedNarrationCannotResumeAfterWakeDeadline() {
    let player = FakePreparedNarrationPlayer()
    var currentTime = Date(timeIntervalSince1970: 1_000)
    let audio = AudioSpikeController(
      preparedNarrationPlayerFactory: { _ in player },
      clock: { currentTime },
      deadlineScheduler: { _, _ in {} },
      activateAudioSession: {}
    )
    defer { audio.stop() }

    audio.startPreparedNarration(
      url: URL(fileURLWithPath: "/prepared.wav"), title: "Prepared",
      transitionToAmbience: false,
      wakeDeadline: currentTime.addingTimeInterval(90))
    audio.pause()
    currentTime.addTimeInterval(91)
    audio.resume()

    XCTAssertEqual(audio.phase, .stopped)
    XCTAssertEqual(player.playCount, 1)
    XCTAssertTrue(audio.statusMessage.contains("wake deadline"))
  }

  func testPreparedNarrationEndingAfterWakeDeadlineIsStoppedInsteadOfCompleted() throws {
    let player = FakePreparedNarrationPlayer()
    var currentTime = Date(timeIntervalSince1970: 1_000)
    let audio = AudioSpikeController(
      preparedNarrationPlayerFactory: { _ in player },
      clock: { currentTime },
      deadlineScheduler: { _, _ in {} },
      activateAudioSession: {}
    )
    defer { audio.stop() }

    audio.startPreparedNarration(
      url: URL(fileURLWithPath: "/prepared.wav"), title: "Prepared",
      transitionToAmbience: false,
      wakeDeadline: currentTime.addingTimeInterval(90))
    let completion = try XCTUnwrap(player.onCompletion)
    currentTime.addTimeInterval(91)
    completion()

    XCTAssertEqual(audio.phase, .stopped)
    XCTAssertTrue(audio.statusMessage.contains("wake deadline"))
    XCTAssertFalse(audio.eventLog.contains { $0.message.contains("Prepared narration completed") })
  }

  func testPreparedNarrationCompletionTransitionsOnceAndCancelsDeadline() throws {
    let player = FakePreparedNarrationPlayer()
    var deadlineCancelled = false
    let audio = AudioSpikeController(
      preparedNarrationPlayerFactory: { _ in player },
      deadlineScheduler: { _, _ in { deadlineCancelled = true } },
      activateAudioSession: {}
    )
    audio.startPreparedNarration(
      url: URL(fileURLWithPath: "/prepared.wav"), title: "Prepared",
      transitionToAmbience: false, wakeDeadline: .now.addingTimeInterval(60))
    let completion = try XCTUnwrap(player.onCompletion)

    completion()
    XCTAssertEqual(audio.phase, .stopped)
    XCTAssertTrue(deadlineCancelled)
    XCTAssertTrue(audio.statusMessage.contains("silence"))
    let events = audio.eventLog.count
    completion()
    XCTAssertEqual(audio.eventLog.count, events)
  }

  func testFixedDeadlineStopsAmbienceAfterPreparedNarrationCompletesEarly() throws {
    let narration = FakePreparedNarrationPlayer()
    let ambience = TrackingAmbiencePlayer()
    var deadlineAction: (@MainActor () -> Void)?
    let audio = AudioSpikeController(
      ambienceEngine: AVAudioEngine(),
      ambiencePlayer: ambience,
      preparedNarrationPlayerFactory: { _ in narration },
      deadlineScheduler: { _, action in
        deadlineAction = action
        return {}
      },
      activateAudioSession: {}
    )
    defer { audio.stop() }
    audio.startPreparedNarration(
      url: URL(fileURLWithPath: "/prepared.wav"), title: "Prepared",
      transitionToAmbience: true, wakeDeadline: .now.addingTimeInterval(60))

    try XCTUnwrap(narration.onCompletion)()
    XCTAssertEqual(audio.phase, .ambience)
    XCTAssertTrue(ambience.isPlaying)
    try XCTUnwrap(deadlineAction)()
    XCTAssertEqual(audio.phase, .stopped)
    XCTAssertFalse(ambience.isPlaying)
    XCTAssertTrue(audio.statusMessage.contains("wake deadline"))
  }

  func testBundledGeorgeTailNaturallyTransitionsToAmbienceBeforeDeadline() async throws {
    let catalog = try PreparedCatalog.load()
    let prepared = try XCTUnwrap(catalog.sessions["turning-fuel-into-motion"])
    let url = try prepared.narrationURL()
    var deadlineAction: (@MainActor () -> Void)?
    var realPlayer: PreparedNarrationPlayer?
    let audio = AudioSpikeController(
      preparedNarrationPlayerFactory: { url in
        let player = try PreparedNarrationPlayer(url: url)
        player.seekForTesting(to: player.duration - 1.25)
        realPlayer = player
        return player
      },
      deadlineScheduler: { _, action in
        deadlineAction = action
        return {}
      }
    )
    defer { audio.stop() }

    audio.startPreparedNarration(
      url: url, title: prepared.session.title, transitionToAmbience: true,
      wakeDeadline: .now.addingTimeInterval(60))
    XCTAssertEqual(audio.phase, .narrating)
    let player = try XCTUnwrap(realPlayer)
    XCTAssertGreaterThan(player.currentTime, player.duration - 2)

    for _ in 0..<80 where audio.phase != .ambience {
      try await Task.sleep(for: .milliseconds(100))
    }
    XCTAssertEqual(audio.phase, .ambience)
    XCTAssertTrue(audio.eventLog.contains { $0.message.contains("ambience") })

    try XCTUnwrap(deadlineAction)()
    XCTAssertEqual(audio.phase, .stopped)
    XCTAssertTrue(audio.statusMessage.contains("wake deadline"))
  }

  func testStoppedPreparedNarrationIgnoresCapturedStaleCompletion() throws {
    let first = FakePreparedNarrationPlayer()
    let second = FakePreparedNarrationPlayer()
    var players = [first, second]
    let audio = AudioSpikeController(
      preparedNarrationPlayerFactory: { _ in players.removeFirst() },
      deadlineScheduler: { _, _ in {} },
      activateAudioSession: {}
    )
    defer { audio.stop() }
    let deadline = Date.now.addingTimeInterval(60)
    audio.startPreparedNarration(
      url: URL(fileURLWithPath: "/first.wav"), title: "First",
      transitionToAmbience: true, wakeDeadline: deadline)
    let staleCompletion = try XCTUnwrap(first.onCompletion)
    audio.stop()
    audio.startPreparedNarration(
      url: URL(fileURLWithPath: "/second.wav"), title: "Second",
      transitionToAmbience: false, wakeDeadline: deadline)

    staleCompletion()
    XCTAssertEqual(audio.phase, .narrating)
    XCTAssertTrue(second.isPlaying)
    XCTAssertEqual(
      MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyTitle] as? String,
      "Second")
  }

  func testInterruptionCancelsResumeQueuedAtSpeechBoundary() async throws {
    let speech = FakeSpeechSynthesizer()
    speech.delaysPause = true
    var activations = 0
    let audio = AudioSpikeController(
      speechSynthesizer: speech, activateAudioSession: { activations += 1 }
    )
    defer { audio.stop() }
    audio.startNarration(script: "Test", title: "Test", transitionToAmbience: false)
    let utterance = try XCTUnwrap(speech.utterances.first)
    audio.pause()
    audio.resume()
    NotificationCenter.default.post(
      name: AVAudioSession.interruptionNotification, object: nil,
      userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]
    )
    await wait(for: .interrupted, in: audio)
    audio.resume()
    speech.completePause()
    audio.speechSynthesizer(speech, didPause: utterance)
    XCTAssertEqual(audio.phase, .interrupted)
    XCTAssertEqual(activations, 1)
    NotificationCenter.default.post(
      name: AVAudioSession.interruptionNotification, object: nil,
      userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue]
    )
    for _ in 0..<5 { await Task.yield() }
    XCTAssertEqual(audio.phase, .interrupted)
    audio.resume()
    XCTAssertEqual(audio.phase, .narrating)
    XCTAssertEqual(activations, 2)
  }

  func testImmediateResumeWaitsForSpeechPauseBoundary() throws {
    let speech = FakeSpeechSynthesizer()
    speech.delaysPause = true
    let audio = AudioSpikeController(speechSynthesizer: speech)
    defer { audio.stop() }
    audio.startNarration(script: "Test", title: "Test", transitionToAmbience: false)
    let utterance = try XCTUnwrap(speech.utterances.first)
    audio.pause()
    XCTAssertFalse(speech.isPaused)
    audio.resume()
    XCTAssertEqual(audio.phase, .paused)
    speech.completePause()
    audio.speechSynthesizer(speech, didPause: utterance)
    XCTAssertEqual(audio.phase, .narrating)
    XCTAssertFalse(speech.isPaused)
  }

  func testStopClearsResumeQueuedForPendingPause() throws {
    let speech = FakeSpeechSynthesizer()
    speech.delaysPause = true
    let audio = AudioSpikeController(speechSynthesizer: speech)
    audio.startNarration(script: "Test", title: "Test", transitionToAmbience: true)
    let utterance = try XCTUnwrap(speech.utterances.first)
    audio.pause()
    audio.resume()
    audio.stop()
    audio.speechSynthesizer(speech, didPause: utterance)
    XCTAssertEqual(audio.phase, .stopped)
    XCTAssertFalse(speech.isSpeaking)
    XCTAssertNil(MPNowPlayingInfoCenter.default().nowPlayingInfo)
  }

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
    let audio = AudioSpikeController(
      speechSynthesizer: speech,
      activateAudioSession: {
        activations += 1
        if activations == 2 { XCTAssertTrue(speech.isPaused) }
      })
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
    let audio = AudioSpikeController(
      speechSynthesizer: speech,
      activateAudioSession: {
        activations += 1
        if activations > 1 { throw ActivationError.unavailable }
      })
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
    XCTAssertFalse(engine.isRunning)
    NotificationCenter.default.post(
      name: AVAudioSession.interruptionNotification, object: nil,
      userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue]
    )
    for _ in 0..<5 { await Task.yield() }
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
    var activations = 0
    let audio = AudioSpikeController(
      speechSynthesizer: speech, activateAudioSession: { activations += 1 }
    )
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
    XCTAssertFalse(audio.canResume)
    XCTAssertFalse(MPRemoteCommandCenter.shared().playCommand.isEnabled)
    audio.resume()
    audio.togglePlayback()
    XCTAssertEqual(activations, 1)
    XCTAssertEqual(audio.phase, .interrupted)

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
    XCTAssertTrue(audio.canResume)
    XCTAssertEqual(activations, 1)
    audio.resume()
    XCTAssertEqual(audio.phase, .narrating)
    XCTAssertEqual(activations, 2)
  }

  func testInterruptionBlocksNewRunsEvenAfterStopOrWhileIdle() async {
    let speech = FakeSpeechSynthesizer()
    let audio = AudioSpikeController(speechSynthesizer: speech, activateAudioSession: {})
    NotificationCenter.default.post(
      name: AVAudioSession.interruptionNotification, object: nil,
      userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]
    )
    for _ in 0..<5 { await Task.yield() }
    XCTAssertFalse(audio.canStartNewRun)
    audio.startNarration(script: "Test", title: "Test", transitionToAmbience: false)
    audio.stop()
    XCTAssertFalse(audio.canStartNewRun)
    audio.startNarration(script: "Test", title: "Test", transitionToAmbience: false)
    XCTAssertTrue(speech.utterances.isEmpty)
    NotificationCenter.default.post(
      name: AVAudioSession.interruptionNotification, object: nil,
      userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue]
    )
    for _ in 0..<5 { await Task.yield() }
    XCTAssertTrue(audio.canStartNewRun)
    XCTAssertEqual(audio.phase, .stopped)
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
  var readCount = 0
  var scheduledIDs: [UUID] = []
  var cancelledIDs: [UUID] = []
  var continuation: AsyncStream<Void>.Continuation?
  var onSubscription: (() -> Void)?

  enum Failure: Error { case requested }

  func requestAuthorization() async throws -> AlarmAuthorizationSnapshot { authorization }
  func alarms() throws -> [SystemAlarmRecord] {
    readCount += 1
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

  func testReconciliationDoesNotPollWithoutAnUnresolvedCountdown() async {
    let system = FakeAlarmSystem()
    let service = AlarmSpikeService(system: system, defaults: defaults, now: { self.now })
    var delays: [Duration] = []
    let initialReads = system.readCount
    await service.reconcileCountdown { delays.append($0) }
    XCTAssertTrue(delays.isEmpty)
    XCTAssertEqual(system.readCount, initialReads)
    _ = await service.schedule(at: now.addingTimeInterval(60))
    let scheduledReads = system.readCount
    await service.reconcileCountdown { delays.append($0) }
    XCTAssertTrue(delays.isEmpty)
    XCTAssertEqual(system.readCount, scheduledReads)
  }

  func testUnresolvedCountdownBacksOffThenStopsWhenDeadlineArrives() async throws {
    let system = FakeAlarmSystem()
    let service = AlarmSpikeService(system: system, defaults: defaults, now: { self.now })
    _ = await service.schedule(at: now.addingTimeInterval(60))
    let id = try XCTUnwrap(system.scheduledIDs.first)
    system.records = [
      SystemAlarmRecord(id: id, state: .countdown, originalDate: now, countdownFireDate: nil)
    ]
    service.refresh()
    XCTAssertTrue(service.needsCountdownReconciliation)
    var delays: [Duration] = []
    let deadline = now.addingTimeInterval(540)
    await service.reconcileCountdown { delay in
      delays.append(delay)
      if delays.count == 7 {
        system.records = [
          SystemAlarmRecord(
            id: id, state: .countdown, originalDate: self.now, countdownFireDate: deadline
          )
        ]
      }
    }
    XCTAssertEqual(delays, Array(repeating: .seconds(1), count: 5) + [.seconds(30), .seconds(30)])
    XCTAssertFalse(service.needsCountdownReconciliation)
    XCTAssertEqual(service.scheduledDate, deadline)
    let resolvedReads = system.readCount
    await service.reconcileCountdown { _ in XCTFail("Resolved countdown must not poll") }
    XCTAssertEqual(system.readCount, resolvedReads)
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

@MainActor
final class RealAlarmCutoffDeviceTests: XCTestCase {
  func testRealAlarmAlertsAsPreparedNarrationStopsAtWakeDeadline() async throws {
    guard ProcessInfo.processInfo.environment["HONKSHOOL_REAL_ALARM_TEST"] == "1" else {
      throw XCTSkip("Opt in with TEST_RUNNER_HONKSHOOL_REAL_ALARM_TEST=1 on a physical iPhone.")
    }
    #if targetEnvironment(simulator)
      throw XCTSkip("A simulator alarm cannot establish physical-iPhone delivery.")
    #else
      let system = AppleAlarmSystem()
      guard system.authorization == .authorized else {
        throw XCTSkip("Authorize Honkshool alarms on the iPhone before this device test.")
      }

      let catalog = try PreparedCatalog.load()
      let prepared = try XCTUnwrap(catalog.sessions["turning-fuel-into-motion"])
      let deadline = Date.now.addingTimeInterval(75)
      let alarmID = UUID()
      try await system.schedule(id: alarmID, at: deadline)
      let audio = AudioSpikeController()
      defer {
        audio.stop()
        do {
          try system.cancel(id: alarmID)
        } catch {
          try? AlarmManager.shared.stop(id: alarmID)
          if (try? system.alarms().contains(where: { $0.id == alarmID })) ?? true {
            XCTFail("The test alarm could not be cleaned up: \(error)")
          }
        }
      }

      audio.startPreparedNarration(
        url: try prepared.narrationURL(), title: prepared.session.title,
        transitionToAmbience: false, wakeDeadline: deadline)
      guard audio.phase == .narrating else {
        XCTFail("Prepared narration did not start: \(audio.statusMessage)")
        return
      }

      var alertObservedAt: Date?
      var stopObservedAt: Date?
      while Date.now < deadline.addingTimeInterval(7) {
        let observedAt = Date.now
        if stopObservedAt == nil && audio.phase == .stopped {
          stopObservedAt = observedAt
        }
        if alertObservedAt == nil,
          let alarm = try system.alarms().first(where: { $0.id == alarmID }),
          alarm.state == .alerting
        {
          alertObservedAt = observedAt
        }
        if alertObservedAt != nil && stopObservedAt != nil { break }
        try await Task.sleep(for: .milliseconds(200))
      }

      let alert = try XCTUnwrap(alertObservedAt, "AlarmKit never reported the real alarm alerting.")
      let stopped = try XCTUnwrap(stopObservedAt, "Prepared narration did not stop at wake.")
      XCTAssertLessThanOrEqual(abs(alert.timeIntervalSince(deadline)), 5)
      XCTAssertLessThanOrEqual(abs(stopped.timeIntervalSince(deadline)), 3)
      XCTAssertTrue(audio.statusMessage.contains("wake deadline"))
    #endif
  }
}
