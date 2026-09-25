import AVFoundation
import Combine
import MediaPlayer

struct AudioEvent: Identifiable {
  let id = UUID()
  let message: String
}

@MainActor
protocol PreparedNarrationPlaying: AnyObject {
  var onCompletion: (() -> Void)? { get set }
  var onFailure: ((String) -> Void)? { get set }
  var isPlaying: Bool { get }
  var currentTime: TimeInterval { get }
  var duration: TimeInterval { get }

  func prepareToPlay() -> Bool
  func play() -> Bool
  func pause()
  func stop()
}

@MainActor
final class PreparedNarrationPlayer: NSObject, PreparedNarrationPlaying {
  var onCompletion: (() -> Void)?
  var onFailure: ((String) -> Void)?

  private let player: AVAudioPlayer

  var isPlaying: Bool { player.isPlaying }
  var currentTime: TimeInterval { player.currentTime }
  var duration: TimeInterval { player.duration }

  init(url: URL) throws {
    player = try AVAudioPlayer(contentsOf: url)
    super.init()
    player.delegate = self
  }

  func prepareToPlay() -> Bool { player.prepareToPlay() }
  func play() -> Bool { player.play() }
  func pause() { player.pause() }
  func stop() { player.stop() }

  #if DEBUG
    /// Lets a focused test exercise the bundled file's real completion callback promptly.
    func seekForTesting(to time: TimeInterval) { player.currentTime = time }
  #endif
}

extension PreparedNarrationPlayer: AVAudioPlayerDelegate {
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    if flag {
      onCompletion?()
    } else {
      onFailure?("Prepared narration ended before reaching its final frame.")
    }
  }

  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    onFailure?(error?.localizedDescription ?? "The prepared narration could not be decoded.")
  }
}

typealias PlaybackDeadlineScheduler =
  @MainActor (
    _ delay: TimeInterval,
    _ action: @escaping @MainActor () -> Void
  ) -> @MainActor () -> Void

@MainActor
final class AudioSpikeController: NSObject, ObservableObject {
  @Published private(set) var phase: PlaybackPhase = .idle
  @Published private(set) var statusMessage = "Ready to test narration."
  @Published private(set) var eventLog: [AudioEvent] = []
  @Published private(set) var interruptionIsActive = false

  private let speechSynthesizer: AVSpeechSynthesizer
  private var activeUtterance: AVSpeechUtterance?
  private let preparedNarrationPlayerFactory: @MainActor (URL) throws -> PreparedNarrationPlaying
  private var preparedNarrationPlayer: PreparedNarrationPlaying?
  private let deadlineScheduler: PlaybackDeadlineScheduler
  private let clock: @MainActor () -> Date
  private var cancelDeadline: (@MainActor () -> Void)?
  private var activeRunID: UUID?
  private var preparedWakeDeadline: Date?
  private let ambienceEngine: AVAudioEngine
  private let activateAudioSession: @MainActor () throws -> Void
  private let ambiencePlayer: AVAudioPlayerNode
  private var ambienceBuffer: AVAudioPCMBuffer?
  private var hasAmbienceToResume = false
  private var observerTokens: [NSObjectProtocol] = []
  private var shouldTransitionToAmbience = true
  private var remoteCommandsInstalled = false
  private var remoteCommandTokens: [(MPRemoteCommand, Any)] = []
  private var narrationStartedAt: Date?
  private var requiresRelaunch = false
  private var pauseRequested = false
  private var resumeAfterPause = false

  var canStartNewRun: Bool {
    !requiresRelaunch && !interruptionIsActive
      && (phase == .idle || phase == .stopped || phase == .failed)
  }

  var canResume: Bool {
    !requiresRelaunch && !interruptionIsActive && (phase == .paused || phase == .interrupted)
  }

  init(
    speechSynthesizer: AVSpeechSynthesizer? = nil,
    ambienceEngine: AVAudioEngine = AVAudioEngine(),
    ambiencePlayer: AVAudioPlayerNode = AVAudioPlayerNode(),
    preparedNarrationPlayerFactory:
      @escaping @MainActor (URL) throws ->
      PreparedNarrationPlaying = { try PreparedNarrationPlayer(url: $0) },
    clock: @escaping @MainActor () -> Date = { .now },
    deadlineScheduler: @escaping PlaybackDeadlineScheduler = { delay, action in
      let task = Task { @MainActor in
        do {
          try await Task.sleep(for: .seconds(max(0, delay)))
        } catch {
          return
        }
        guard !Task.isCancelled else { return }
        action()
      }
      return { task.cancel() }
    },
    activateAudioSession: @escaping @MainActor () throws -> Void = {
      #if DEBUG
        try UITestFixtures.failAudioActivationIfRequested()
      #endif
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .spokenAudio, options: [])
      try session.setActive(true)
    }
  ) {
    self.ambienceEngine = ambienceEngine
    self.ambiencePlayer = ambiencePlayer
    self.preparedNarrationPlayerFactory = preparedNarrationPlayerFactory
    self.clock = clock
    self.deadlineScheduler = deadlineScheduler
    self.activateAudioSession = activateAudioSession
    #if DEBUG
      self.speechSynthesizer =
        speechSynthesizer ?? UITestFixtures.makeSpeechSynthesizer() ?? AVSpeechSynthesizer()
    #else
      self.speechSynthesizer = speechSynthesizer ?? AVSpeechSynthesizer()
    #endif
    super.init()
    self.speechSynthesizer.delegate = self
    observeAudioEvents()
    installRemoteCommands()
  }

  deinit {
    for token in observerTokens {
      NotificationCenter.default.removeObserver(token)
    }
    for (command, token) in remoteCommandTokens {
      command.removeTarget(token)
    }
  }

  func startNarration(
    script: String,
    title: String,
    transitionToAmbience: Bool
  ) {
    guard !interruptionIsActive else { return }
    guard !requiresRelaunch else {
      phase = .failed
      statusMessage = "Media services reset. Relaunch Honkshool before starting a new test."
      return
    }
    stopAudio(updateStatus: false)
    shouldTransitionToAmbience = transitionToAmbience

    do {
      try configureExclusiveAudioSession()
    } catch {
      fail("Audio session activation failed: \(error.localizedDescription)")
      return
    }

    let utterance = AVSpeechUtterance(string: script)
    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
    utterance.rate = 0.43
    utterance.pitchMultiplier = 1.0
    utterance.volume = 1.0
    utterance.preUtteranceDelay = 0.4
    utterance.postUtteranceDelay = 1.0

    activeUtterance = utterance
    phase = .narrating
    narrationStartedAt = .now
    statusMessage = "Narration is playing. Lock the screen to test background audio."
    appendEvent("Started direct AVSpeechSynthesizer narration")
    updateNowPlaying(title: title, playbackRate: 1)
    speechSynthesizer.speak(utterance)
  }

  func startPreparedNarration(
    url: URL,
    title: String,
    transitionToAmbience: Bool,
    wakeDeadline: Date
  ) {
    guard wakeDeadline > clock() else {
      fail("Prepared narration requires a future wake deadline.")
      return
    }
    guard !interruptionIsActive else { return }
    guard !requiresRelaunch else {
      phase = .failed
      statusMessage = "Media services reset. Relaunch Honkshool before starting a new test."
      return
    }
    stopAudio(updateStatus: false)
    shouldTransitionToAmbience = transitionToAmbience

    do {
      try configureExclusiveAudioSession()
    } catch {
      fail("Audio session activation failed: \(error.localizedDescription)")
      return
    }

    do {
      let player = try preparedNarrationPlayerFactory(url)
      guard player.prepareToPlay() else {
        fail("The prepared George narration could not be prepared for playback.")
        return
      }
      let runID = UUID()
      activeRunID = runID
      preparedWakeDeadline = wakeDeadline
      preparedNarrationPlayer = player
      player.onCompletion = { [weak self] in
        self?.preparedNarrationDidFinish(runID: runID)
      }
      player.onFailure = { [weak self] reason in
        guard self?.activeRunID == runID else { return }
        self?.fail("Prepared narration failed: \(reason)")
      }
      let remaining = wakeDeadline.timeIntervalSince(clock())
      guard remaining > 0 else {
        stopAtWakeDeadline(runID: runID)
        return
      }
      cancelDeadline = deadlineScheduler(remaining) { [weak self] in
        self?.stopAtWakeDeadline(runID: runID)
      }
      guard !stopIfPreparedWakeDeadlinePassed() else { return }
      guard player.play() else {
        fail("The prepared George narration could not start playback.")
        return
      }

      guard !stopIfPreparedWakeDeadlinePassed() else { return }

      phase = .narrating
      narrationStartedAt = clock()
      statusMessage = "George narration is playing. Lock the screen to test background audio."
      appendEvent("Started bundled Kokoro George narration")
      updateNowPlaying(
        title: title, playbackRate: 1, duration: player.duration, elapsedTime: player.currentTime)
    } catch {
      fail("Prepared narration failed to load: \(error.localizedDescription)")
    }
  }

  func pause() {
    switch phase {
    case .narrating:
      if let preparedNarrationPlayer {
        preparedNarrationPlayer.pause()
      } else {
        guard requestNarrationPause() else { return }
      }
    case .ambience:
      ambiencePlayer.pause()
    default:
      return
    }

    phase = .paused
    statusMessage = "Paused. Resume explicitly when ready."
    appendEvent("Paused by user or remote command")
    updateNowPlayingPlaybackRate(0)
  }

  func resume() {
    guard canResume else { return }
    guard !stopIfPreparedWakeDeadlinePassed() else { return }
    if pauseRequested && !speechSynthesizer.isPaused {
      resumeAfterPause = true
      statusMessage = "Waiting for narration to reach a pause boundary."
      return
    }
    pauseRequested = false
    resumeAfterPause = false
    guard preparedNarrationPlayer != nil || speechSynthesizer.isPaused || hasAmbienceToResume else {
      fail("Nothing is available to resume; start a new test.")
      return
    }

    do {
      try configureExclusiveAudioSession()
      guard !stopIfPreparedWakeDeadlinePassed() else { return }
      if let preparedNarrationPlayer {
        guard preparedNarrationPlayer.play() else {
          fail("Prepared narration could not resume; start a new test.")
          return
        }
        phase = .narrating
        statusMessage = "George narration resumed."
      } else if speechSynthesizer.isPaused {
        guard speechSynthesizer.continueSpeaking() else {
          fail("Narration could not resume; start a new test.")
          return
        }
        phase = .narrating
        statusMessage = "Narration resumed."
      } else {
        guard let ambienceBuffer else {
          fail("Ambience is unavailable; start a new test.")
          return
        }
        // Route changes can purge the player queue even if the engine stays running.
        // A neutral loop has no meaningful playback position to preserve.
        ambiencePlayer.stop()
        if !ambienceEngine.isRunning {
          ambienceEngine.prepare()
          try ambienceEngine.start()
        }
        ambiencePlayer.scheduleBuffer(ambienceBuffer, at: nil, options: .loops)
        ambiencePlayer.play()
        phase = .ambience
        statusMessage = "Neutral ambience resumed."
      }
    } catch {
      fail("Audio could not resume: \(error.localizedDescription)")
      return
    }

    appendEvent("Resumed explicitly")
    updateNowPlayingPlaybackRate(1)
  }

  func stop() {
    stopAudio(updateStatus: true)
  }

  func togglePlayback() {
    switch phase {
    case .narrating, .ambience: pause()
    case .paused, .interrupted: resume()
    default: break
    }
  }

  private func configureExclusiveAudioSession() throws {
    try activateAudioSession()
    appendEvent("Activated exclusive playback audio session")
  }

  private func requestNarrationPause() -> Bool {
    pauseRequested = true
    resumeAfterPause = false
    let accepted = speechSynthesizer.pauseSpeaking(at: .word)
    if !accepted { pauseRequested = false }
    return accepted
  }

  private func startAmbience() {
    guard !stopIfPreparedWakeDeadlinePassed() else { return }
    do {
      try configureExclusiveAudioSession()

      if !ambienceEngine.attachedNodes.contains(ambiencePlayer) {
        ambienceEngine.attach(ambiencePlayer)
        let format = AVAudioFormat(
          standardFormatWithSampleRate: 44_100,
          channels: 2
        )!
        ambienceEngine.connect(
          ambiencePlayer,
          to: ambienceEngine.mainMixerNode,
          format: format
        )
        ambienceBuffer = makeNeutralNoiseBuffer(format: format)
      }

      guard let ambienceBuffer else {
        fail("The generated ambience buffer was unavailable.")
        return
      }

      if !ambienceEngine.isRunning {
        ambienceEngine.prepare()
        try ambienceEngine.start()
      }

      guard !stopIfPreparedWakeDeadlinePassed() else { return }
      ambiencePlayer.volume = 0.12
      ambiencePlayer.scheduleBuffer(
        ambienceBuffer,
        at: nil,
        options: .loops
      )
      ambiencePlayer.play()
      hasAmbienceToResume = true
      phase = .ambience
      statusMessage = "Narration finished. Generated neutral ambience is looping."
      appendEvent("Transitioned from narration to generated neutral ambience")
      updateNowPlaying(title: "Neutral ambience", playbackRate: 1)
    } catch {
      fail("Ambience failed to start: \(error.localizedDescription)")
    }
  }

  private func makeNeutralNoiseBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
    let frameCapacity = AVAudioFrameCount(format.sampleRate * 3)
    guard
      let buffer = AVAudioPCMBuffer(
        pcmFormat: format,
        frameCapacity: frameCapacity
      ),
      let channels = buffer.floatChannelData
    else {
      return nil
    }

    buffer.frameLength = frameCapacity
    var generator = SystemRandomNumberGenerator()
    var previousSample: Float = 0

    for frame in 0..<Int(frameCapacity) {
      let white = Float.random(in: -1...1, using: &generator)
      let filtered = (previousSample + (0.025 * white)) / 1.025
      previousSample = filtered
      let sample = filtered * 2.4

      for channel in 0..<Int(format.channelCount) {
        channels[channel][frame] = sample
      }
    }

    return buffer
  }

  private func stopAudio(updateStatus: Bool) {
    // Invalidate ownership before calling into AVFoundation: cancellation can
    // deliver delegate callbacks synchronously or after the next run starts.
    cancelDeadline?()
    cancelDeadline = nil
    activeRunID = nil
    preparedWakeDeadline = nil
    activeUtterance = nil
    preparedNarrationPlayer?.onCompletion = nil
    preparedNarrationPlayer?.onFailure = nil
    preparedNarrationPlayer?.stop()
    preparedNarrationPlayer = nil
    pauseRequested = false
    resumeAfterPause = false
    hasAmbienceToResume = false
    shouldTransitionToAmbience = false
    narrationStartedAt = nil
    if speechSynthesizer.isSpeaking || speechSynthesizer.isPaused {
      speechSynthesizer.stopSpeaking(at: .immediate)
    }
    ambiencePlayer.stop()
    ambienceEngine.stop()
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil

    if updateStatus {
      phase = .stopped
      statusMessage = "Playback stopped. Any scheduled alarm remains active."
      appendEvent("Stopped playback; alarm state was not changed")
    }
    do {
      try AVAudioSession.sharedInstance().setActive(
        false,
        options: .notifyOthersOnDeactivation
      )
    } catch {
      appendEvent("Audio session deactivation reported: \(error.localizedDescription)")
    }
  }

  private func observeAudioEvents() {
    let center = NotificationCenter.default

    observerTokens.append(
      center.addObserver(
        forName: AVAudioSession.interruptionNotification,
        object: nil,
        queue: .main
      ) { [weak self] notification in
        Task { @MainActor in
          self?.handleInterruption(notification)
        }
      }
    )

    observerTokens.append(
      center.addObserver(
        forName: AVAudioSession.routeChangeNotification,
        object: nil,
        queue: .main
      ) { [weak self] notification in
        Task { @MainActor in
          self?.handleRouteChange(notification)
        }
      }
    )

    observerTokens.append(
      center.addObserver(
        forName: AVAudioSession.mediaServicesWereResetNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        Task { @MainActor in
          guard let self else { return }
          self.requiresRelaunch = true
          self.stopAudio(updateStatus: false)
          self.appendEvent("Media services reset; playback is no longer resumable")
          self.phase = .failed
          self.statusMessage =
            "Media services reset. Relaunch Honkshool before starting a new test."
        }
      }
    )
  }

  private func handleInterruption(_ notification: Notification) {
    guard
      let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
      let type = AVAudioSession.InterruptionType(rawValue: rawType)
    else {
      return
    }

    switch type {
    case .began:
      interruptionIsActive = true
      resumeAfterPause = false
      if handlesRemoteMedia {
        MPRemoteCommandCenter.shared().playCommand.isEnabled = false
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.isEnabled = false
      }
      guard phase == .narrating || phase == .ambience || phase == .paused else { return }
      if speechSynthesizer.isSpeaking {
        _ = requestNarrationPause()
      }
      if preparedNarrationPlayer?.isPlaying == true {
        preparedNarrationPlayer?.pause()
      }
      if ambiencePlayer.isPlaying {
        ambiencePlayer.pause()
      }
      phase = .interrupted
      statusMessage = "Audio is interrupted. Wait for it to end before resuming manually."
      appendEvent("Interruption began; playback paused")
      updateNowPlayingPlaybackRate(0)
    case .ended:
      interruptionIsActive = false
      if handlesRemoteMedia {
        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.isEnabled = true
      }
      guard phase == .interrupted else { return }
      let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
      let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
      let suggestion = options.contains(.shouldResume)
      statusMessage = "Interruption ended. Resume manually to continue this test."
      appendEvent(
        "Interruption ended; iOS shouldResume=\(suggestion); waiting for manual resume"
      )
    @unknown default:
      appendEvent("Received an unknown audio interruption state")
    }
  }

  private func handleRouteChange(_ notification: Notification) {
    let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt ?? 0
    let reason = AVAudioSession.RouteChangeReason(rawValue: rawReason) ?? .unknown
    appendEvent("Audio route changed: \(routeChangeDescription(reason))")

    guard reason == .oldDeviceUnavailable,
      phase == .narrating || phase == .ambience || phase == .paused
    else { return }

    if speechSynthesizer.isSpeaking {
      _ = requestNarrationPause()
    }
    if preparedNarrationPlayer?.isPlaying == true {
      preparedNarrationPlayer?.pause()
    }
    if ambiencePlayer.isPlaying {
      ambiencePlayer.pause()
    }
    phase = .interrupted
    statusMessage = "Audio output disconnected. Resume manually after choosing an output."
    updateNowPlayingPlaybackRate(0)
  }

  private func routeChangeDescription(
    _ reason: AVAudioSession.RouteChangeReason
  ) -> String {
    switch reason {
    case .newDeviceAvailable: "new device available"
    case .oldDeviceUnavailable: "old device unavailable"
    case .categoryChange: "category changed"
    case .override: "route overridden"
    case .wakeFromSleep: "device woke from sleep"
    case .noSuitableRouteForCategory: "no suitable route"
    case .routeConfigurationChange: "route configuration changed"
    case .unknown: "unknown"
    @unknown default: "future reason"
    }
  }

  private func installRemoteCommands() {
    guard !remoteCommandsInstalled else { return }
    remoteCommandsInstalled = true

    let commands = MPRemoteCommandCenter.shared()
    commands.nextTrackCommand.isEnabled = false
    commands.previousTrackCommand.isEnabled = false
    commands.skipForwardCommand.isEnabled = false
    commands.skipBackwardCommand.isEnabled = false
    commands.changePlaybackPositionCommand.isEnabled = false

    let actions: [(MPRemoteCommand, @MainActor (AudioSpikeController) -> Void)] = [
      (commands.playCommand, { $0.resume() }),
      (commands.pauseCommand, { $0.pause() }),
      (commands.togglePlayPauseCommand, { $0.togglePlayback() }),
      (commands.stopCommand, { $0.stop() }),
    ]
    for (command, action) in actions {
      command.isEnabled = true
      let token = command.addTarget { [weak self] _ in
        guard let self, self.handlesRemoteMedia else { return .commandFailed }
        Task { @MainActor in action(self) }
        return .success
      }
      remoteCommandTokens.append((command, token))
    }
  }

  private var handlesRemoteMedia: Bool {
    switch phase {
    case .narrating, .paused, .ambience, .interrupted: true
    default: false
    }
  }

  private func updateNowPlaying(
    title: String,
    playbackRate: Float,
    duration: TimeInterval? = nil,
    elapsedTime: TimeInterval? = nil
  ) {
    var info: [String: Any] = [
      MPMediaItemPropertyTitle: title,
      MPMediaItemPropertyArtist: "Honkshool feasibility spike",
      MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
      MPNowPlayingInfoPropertyPlaybackRate: playbackRate,
      MPNowPlayingInfoPropertyDefaultPlaybackRate: 1,
      MPNowPlayingInfoPropertyIsLiveStream: false,
    ]
    if let duration { info[MPMediaItemPropertyPlaybackDuration] = duration }
    if let elapsedTime { info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime }
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
  }

  private func updateNowPlayingPlaybackRate(_ playbackRate: Float) {
    var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
    if let preparedNarrationPlayer {
      info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = preparedNarrationPlayer.currentTime
    }
    info[MPNowPlayingInfoPropertyPlaybackRate] = playbackRate
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
  }

  private func fail(_ message: String) {
    stopAudio(updateStatus: false)
    phase = .failed
    statusMessage = message
    appendEvent(message)
  }

  private func appendEvent(_ message: String) {
    let timestamp = Date.now.formatted(date: .omitted, time: .standard)
    eventLog.insert(AudioEvent(message: "\(timestamp) — \(message)"), at: 0)
    eventLog = Array(eventLog.prefix(30))
  }

  private func preparedNarrationDidFinish(runID: UUID) {
    guard activeRunID == runID, preparedNarrationPlayer != nil else { return }
    guard !stopIfPreparedWakeDeadlinePassed() else { return }
    preparedNarrationPlayer?.onCompletion = nil
    preparedNarrationPlayer?.onFailure = nil
    preparedNarrationPlayer = nil
    completeNarration(source: "Prepared narration")
  }

  private func stopAtWakeDeadline(runID: UUID) {
    guard activeRunID == runID else { return }
    stopAudio(updateStatus: false)
    phase = .stopped
    statusMessage = "The planned wake deadline arrived. Honkshool audio stopped."
    appendEvent("Stopped all audio at the fixed wake deadline")
  }

  private func stopIfPreparedWakeDeadlinePassed() -> Bool {
    guard let preparedWakeDeadline, let activeRunID, clock() >= preparedWakeDeadline else {
      return false
    }
    stopAtWakeDeadline(runID: activeRunID)
    return true
  }

  private func completeNarration(source: String) {
    if let narrationStartedAt {
      let duration = Date.now.timeIntervalSince(narrationStartedAt)
      appendEvent(
        "\(source) completed after \(duration.formatted(.number.precision(.fractionLength(1)))) seconds"
      )
    } else {
      appendEvent("\(source) reported completion")
    }
    self.narrationStartedAt = nil

    switch PlaybackTransitionPolicy.destinationAfterNarration(
      ambienceEnabled: shouldTransitionToAmbience
    ) {
    case .ambience:
      startAmbience()
    case .silence:
      stopAudio(updateStatus: false)
      phase = .stopped
      statusMessage = "Narration finished and transitioned to silence."
      appendEvent("Transitioned from narration to silence")
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
  }
}

extension AudioSpikeController: @preconcurrency AVSpeechSynthesizerDelegate {
  func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer,
    didPause utterance: AVSpeechUtterance
  ) {
    guard activeUtterance === utterance else { return }
    pauseRequested = false
    if resumeAfterPause {
      resumeAfterPause = false
      resume()
    }
  }

  func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer,
    didFinish utterance: AVSpeechUtterance
  ) {
    guard activeUtterance === utterance else { return }
    activeUtterance = nil
    completeNarration(source: "Narration delegate")
  }

  func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer,
    didCancel utterance: AVSpeechUtterance
  ) {
    guard activeUtterance === utterance else { return }
    stopAudio(updateStatus: false)
    phase = .stopped
    statusMessage = "Narration was cancelled. Playback stopped."
    narrationStartedAt = nil
    appendEvent("Narration delegate reported cancellation")
  }
}
