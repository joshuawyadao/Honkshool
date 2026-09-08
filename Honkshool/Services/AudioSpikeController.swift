import AVFoundation
import Combine
import MediaPlayer

struct AudioEvent: Identifiable {
  let id = UUID()
  let message: String
}

@MainActor
final class AudioSpikeController: NSObject, ObservableObject {
  @Published private(set) var phase: PlaybackPhase = .idle
  @Published private(set) var statusMessage = "Ready to test narration."
  @Published private(set) var eventLog: [AudioEvent] = []

  private let speechSynthesizer: AVSpeechSynthesizer
  private var activeUtterance: AVSpeechUtterance?
  private let ambienceEngine = AVAudioEngine()
  private let ambiencePlayer = AVAudioPlayerNode()
  private var ambienceBuffer: AVAudioPCMBuffer?
  private var observerTokens: [NSObjectProtocol] = []
  private var shouldTransitionToAmbience = true
  private var remoteCommandsInstalled = false
  private var remoteCommandTokens: [(MPRemoteCommand, Any)] = []
  private var narrationStartedAt: Date?

  init(speechSynthesizer: AVSpeechSynthesizer = AVSpeechSynthesizer()) {
    self.speechSynthesizer = speechSynthesizer
    super.init()
    speechSynthesizer.delegate = self
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

  func pause() {
    switch phase {
    case .narrating:
      guard speechSynthesizer.pauseSpeaking(at: .word) else { return }
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
    guard phase == .paused || phase == .interrupted else { return }

    if speechSynthesizer.isPaused {
      _ = speechSynthesizer.continueSpeaking()
      phase = .narrating
      statusMessage = "Narration resumed."
    } else if ambienceEngine.isRunning {
      ambiencePlayer.play()
      phase = .ambience
      statusMessage = "Neutral ambience resumed."
    } else {
      statusMessage = "Nothing is available to resume; start a new test."
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
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, mode: .spokenAudio, options: [])
    try session.setActive(true)
    appendEvent("Activated exclusive playback audio session")
  }

  private func startAmbience() {
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

      ambiencePlayer.volume = 0.12
      ambiencePlayer.scheduleBuffer(
        ambienceBuffer,
        at: nil,
        options: .loops
      )
      ambiencePlayer.play()
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
    activeUtterance = nil
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
          self?.appendEvent("Media services reset; start a new test run")
          self?.phase = .interrupted
          self?.statusMessage = "Media services reset. Start a new test run."
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
      guard phase == .narrating || phase == .ambience || phase == .paused else { return }
      if speechSynthesizer.isSpeaking {
        _ = speechSynthesizer.pauseSpeaking(at: .word)
      }
      if ambiencePlayer.isPlaying {
        ambiencePlayer.pause()
      }
      phase = .interrupted
      statusMessage = "Audio was interrupted. The spike will not resume automatically."
      appendEvent("Interruption began; playback paused")
      updateNowPlayingPlaybackRate(0)
    case .ended:
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
      _ = speechSynthesizer.pauseSpeaking(at: .word)
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
        guard let self else { return .commandFailed }
        Task { @MainActor in action(self) }
        return .success
      }
      remoteCommandTokens.append((command, token))
    }
  }

  private func updateNowPlaying(title: String, playbackRate: Float) {
    MPNowPlayingInfoCenter.default().nowPlayingInfo = [
      MPMediaItemPropertyTitle: title,
      MPMediaItemPropertyArtist: "Honkshool feasibility spike",
      MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
      MPNowPlayingInfoPropertyPlaybackRate: playbackRate,
      MPNowPlayingInfoPropertyDefaultPlaybackRate: 1,
      MPNowPlayingInfoPropertyIsLiveStream: false,
    ]
  }

  private func updateNowPlayingPlaybackRate(_ playbackRate: Float) {
    var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
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
}

extension AudioSpikeController: @preconcurrency AVSpeechSynthesizerDelegate {
  func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer,
    didFinish utterance: AVSpeechUtterance
  ) {
    guard activeUtterance === utterance else { return }
    activeUtterance = nil
    if let narrationStartedAt {
      let duration = Date.now.timeIntervalSince(narrationStartedAt)
      appendEvent(
        "Narration delegate completed after \(duration.formatted(.number.precision(.fractionLength(1)))) seconds"
      )
    } else {
      appendEvent("Narration delegate reported completion")
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
