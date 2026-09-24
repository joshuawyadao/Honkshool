import AVFoundation
import Combine
import MediaPlayer

enum NapRunPhase: Equatable {
  case idle
  case waiting
  case narrating
  case paused
  case interrupted
  case resting
  case stopped
  case finished
  case failed
}

enum NapRunError: Error, Equatable {
  case alreadyRunning
  case staleStart
  case alarmUnavailable
  case ambienceUnavailable
  case contentUnavailable
  case invalidCheckpoint
  case audioUnavailable
}

@MainActor
protocol NapRunAudioPlaying: AnyObject {
  var onCompletion: (() -> Void)? { get set }
  var onFailure: ((String) -> Void)? { get set }
  var currentTime: TimeInterval { get }
  var duration: TimeInterval { get }

  func prepareToPlay() -> Bool
  func seek(to time: TimeInterval)
  func play() -> Bool
  func pause()
  func stop()
}

@MainActor
final class NapRunAudioPlayer: NSObject, NapRunAudioPlaying {
  var onCompletion: (() -> Void)?
  var onFailure: ((String) -> Void)?

  private let player: AVAudioPlayer

  var currentTime: TimeInterval { player.currentTime }
  var duration: TimeInterval { player.duration }

  init(url: URL) throws {
    player = try AVAudioPlayer(contentsOf: url)
    super.init()
    player.delegate = self
  }

  func prepareToPlay() -> Bool { player.prepareToPlay() }
  func seek(to time: TimeInterval) { player.currentTime = time }
  func play() -> Bool { player.play() }
  func pause() { player.pause() }
  func stop() { player.stop() }
}

extension NapRunAudioPlayer: AVAudioPlayerDelegate {
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    if flag {
      onCompletion?()
    } else {
      onFailure?("Prepared narration ended before its final frame.")
    }
  }

  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    onFailure?(error?.localizedDescription ?? "Prepared narration could not be decoded.")
  }
}

typealias NapRunScheduler =
  @MainActor (
    _ delay: TimeInterval,
    _ action: @escaping @MainActor () -> Void
  ) -> @MainActor () -> Void

struct NapRunCheckpoint: Equatable {
  let capturedAt: Date
  let resumePoint: ResumePoint
  let playedDuration: TimeInterval
}

/// Executes only the reviewed route. This object owns one in-memory run, not alarm or history storage.
@MainActor
final class NapRunController: NSObject, ObservableObject {
  @Published private(set) var phase: NapRunPhase = .idle
  @Published private(set) var statusMessage = "Ready to start a reviewed plan."
  @Published private(set) var records: [PlaybackRecord] = []
  @Published private(set) var latestVerifiedCheckpoint: NapRunCheckpoint?

  private struct PreparedRouteItem {
    let planned: PlannedSession
    let prepared: PreparedSession
    let url: URL
  }

  private let playerFactory: @MainActor (URL) throws -> NapRunAudioPlaying
  private let clock: @MainActor () -> Date
  private let scheduler: NapRunScheduler
  private let activateAudioSession: @MainActor () throws -> Void
  private let deactivateAudioSession: @MainActor () -> Void
  private let manageRemoteCommands: Bool
  private var route: [PreparedRouteItem] = []
  private var playback: NapPlayback?
  private var player: NapRunAudioPlaying?
  private var currentSessionStartedAt: Date?
  private var currentSessionOffset: TimeInterval = 0
  private var activeToken: UUID?
  private var cancelStart: (@MainActor () -> Void)?
  private var cancelNarrationStart: (@MainActor () -> Void)?
  private var cancelDeadline: (@MainActor () -> Void)?
  private var cancelCheckpoint: (@MainActor () -> Void)?
  private var interruptionIsActive = false
  private var appIsForeground = true
  private var waitingForNarration = false
  private var observerTokens: [NSObjectProtocol] = []
  private var remoteCommandTokens: [(MPRemoteCommand, Any)] = []

  var hasActiveRun: Bool {
    switch phase {
    case .waiting, .narrating, .paused, .interrupted, .resting: true
    default: false
    }
  }

  init(
    playerFactory: @escaping @MainActor (URL) throws -> NapRunAudioPlaying = {
      try NapRunAudioPlayer(url: $0)
    },
    clock: @escaping @MainActor () -> Date = { .now },
    scheduler: @escaping NapRunScheduler = { delay, action in
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
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .spokenAudio, options: [])
      try session.setActive(true)
    },
    deactivateAudioSession: @escaping @MainActor () -> Void = {
      try? AVAudioSession.sharedInstance().setActive(
        false, options: .notifyOthersOnDeactivation)
    },
    observeSystemEvents: Bool = true,
    manageRemoteCommands: Bool = true
  ) {
    self.playerFactory = playerFactory
    self.clock = clock
    self.scheduler = scheduler
    self.activateAudioSession = activateAudioSession
    self.deactivateAudioSession = deactivateAudioSession
    self.manageRemoteCommands = manageRemoteCommands
    super.init()
    if observeSystemEvents { installAudioObservers() }
  }

  deinit {
    for token in observerTokens { NotificationCenter.default.removeObserver(token) }
    for (command, token) in remoteCommandTokens { command.removeTarget(token) }
  }

  func start(review: NapPlanReview, catalog: PreparedCatalog) throws {
    guard !hasActiveRun else { throw NapRunError.alreadyRunning }
    guard !interruptionIsActive, appIsForeground else { throw NapRunError.audioUnavailable }
    let now = clock()
    guard now.timeIntervalSinceReferenceDate.isFinite, now <= review.plan.start,
      now < review.plan.deadline
    else { throw NapRunError.staleStart }
    // D-021: no run may begin while its promised alarm has not been scheduled.
    guard review.plan.wakeAlarm == nil else { throw NapRunError.alarmUnavailable }
    guard review.plan.fallback == .silence else { throw NapRunError.ambienceUnavailable }

    let preparedRoute = try review.plan.route.map { planned -> PreparedRouteItem in
      guard let prepared = catalog.sessions[planned.session.id],
        prepared.session.revision == planned.session.revision,
        let url = try? prepared.narrationURL()
      else { throw NapRunError.contentUnavailable }
      if let point = planned.resumePoint {
        guard point.audioOffset != nil else { throw NapRunError.invalidCheckpoint }
        do { try prepared.validateAudioResumePoint(point) } catch {
          throw NapRunError.invalidCheckpoint
        }
      }
      return PreparedRouteItem(planned: planned, prepared: prepared, url: url)
    }
    let nextPlayback = try NapPlayback(plan: review.plan, runID: UUID().uuidString)
    route = preparedRoute
    playback = nextPlayback
    records = []
    latestVerifiedCheckpoint = nil
    let token = UUID()
    activeToken = token
    waitingForNarration = true
    phase = .waiting
    statusMessage = "Keep Honkshool open until narration begins at the approved start."
    cancelDeadline = scheduler(review.plan.deadline.timeIntervalSince(now)) { [weak self] in
      self?.reachDeadline(token: token)
    }
    if now == review.plan.start {
      beginAtPlannedStart(token: token)
    } else {
      cancelStart = scheduler(review.plan.start.timeIntervalSince(now)) { [weak self] in
        self?.beginAtPlannedStart(token: token)
      }
    }
  }

  func pause() {
    guard phase == .narrating, let player else { return }
    player.pause()
    phase = .paused
    statusMessage = "Paused. Resume explicitly when ready."
    updateNowPlayingRate(0)
  }

  func resume() {
    guard phase == .paused || phase == .interrupted, !interruptionIsActive,
      let token = activeToken, let player, let playback
    else { return }
    guard clock() < playback.plan.deadline else {
      reachDeadline(token: token)
      return
    }
    do {
      try activateAudioSession()
      guard player.play() else {
        fail("Prepared narration could not resume.", token: token)
        return
      }
      phase = .narrating
      statusMessage = "Narration resumed."
      updateNowPlayingRate(1)
    } catch {
      fail("Audio could not resume: \(error.localizedDescription)", token: token)
    }
  }

  func stop() {
    guard let token = activeToken else { return }
    if let playback, clock() >= playback.plan.deadline {
      reachDeadline(token: token)
      return
    }
    recordPartialIfPossible(reason: .stopped, token: token)
    clearRun()
    phase = .stopped
    statusMessage = "Playback stopped. No wake alarm was scheduled."
  }

  func scenePhaseChanged(isActive: Bool) {
    appIsForeground = isActive
    guard !isActive, waitingForNarration, let token = activeToken else { return }
    fail("The app left the foreground before narration began. Review a new Nap Plan.", token: token)
  }

  func resetPresentation() {
    guard !hasActiveRun else { return }
    records = []
    latestVerifiedCheckpoint = nil
    phase = .idle
    statusMessage = "Ready to start a reviewed plan."
  }

  private func beginAtPlannedStart(token: UUID) {
    guard activeToken == token, let playback else { return }
    cancelStart?()
    cancelStart = nil
    let now = clock()
    if now < playback.plan.start {
      cancelStart = scheduler(playback.plan.start.timeIntervalSince(now)) { [weak self] in
        self?.beginAtPlannedStart(token: token)
      }
      return
    }
    guard now < playback.plan.deadline else {
      reachDeadline(token: token)
      return
    }
    guard appIsForeground else {
      fail("The app must stay open until narration begins. Review a new Nap Plan.", token: token)
      return
    }
    // A suspended app may deliver the start timer long after the approved instant.
    guard now.timeIntervalSince(playback.plan.start) <= 1 else {
      clearRun()
      phase = .failed
      statusMessage = "The approved start passed. Review a new Nap Plan before starting."
      return
    }
    guard !interruptionIsActive else {
      clearRun()
      phase = .failed
      statusMessage = "Audio is interrupted. Review a new Nap Plan when it ends."
      return
    }
    if now < playback.plan.narrationStart {
      phase = .resting
      statusMessage = "Resting in silence until narration begins."
      cancelNarrationStart = scheduler(playback.plan.narrationStart.timeIntervalSince(now)) {
        [weak self] in
        self?.startNextSession(token: token)
      }
    } else {
      startNextSession(token: token)
    }
  }

  private func startNextSession(token: UUID) {
    guard activeToken == token, let playback else { return }
    if waitingForNarration && !appIsForeground {
      fail("The app must stay open until narration begins. Review a new Nap Plan.", token: token)
      return
    }
    cancelNarrationStart?()
    cancelNarrationStart = nil
    let now = clock()
    guard now < playback.plan.deadline else {
      reachDeadline(token: token)
      return
    }
    guard !interruptionIsActive else {
      fail("Audio is interrupted. Review a new Nap Plan when it ends.", token: token)
      return
    }
    do {
      guard let planned = try playback.nextSession(at: now) else {
        if now < playback.plan.narrationStart {
          cancelNarrationStart = scheduler(playback.plan.narrationStart.timeIntervalSince(now)) {
            [weak self] in
            self?.startNextSession(token: token)
          }
          return
        }
        try beginSilentRest(token: token)
        return
      }
      let index = playback.records.count
      guard route.indices.contains(index), route[index].planned == planned else {
        fail("The approved narration route is unavailable.", token: token)
        return
      }
      let item = route[index]
      try activateAudioSession()
      let nextPlayer = try playerFactory(item.url)
      guard nextPlayer.prepareToPlay() else {
        fail("The prepared narration could not be prepared.", token: token)
        return
      }
      let offset = planned.resumePoint?.audioOffset ?? 0
      guard offset >= 0, offset < nextPlayer.duration else {
        fail("The approved audio checkpoint is unavailable.", token: token)
        return
      }
      if offset > 0 { nextPlayer.seek(to: offset) }
      nextPlayer.onCompletion = { [weak self] in
        self?.completeSession(token: token, routeIndex: index)
      }
      nextPlayer.onFailure = { [weak self] message in
        self?.fail(message, token: token)
      }
      guard clock() < playback.plan.deadline else {
        nextPlayer.onCompletion = nil
        nextPlayer.onFailure = nil
        nextPlayer.stop()
        reachDeadline(token: token)
        return
      }
      let started = clock()
      guard nextPlayer.play() else {
        fail("The prepared narration could not start.", token: token)
        return
      }
      player = nextPlayer
      currentSessionStartedAt = started
      currentSessionOffset = offset
      waitingForNarration = false
      captureCheckpoint(token: token)
      phase = .narrating
      statusMessage = "Playing \(planned.session.title)."
      installRemoteCommandsIfNeeded()
      updateNowPlaying(
        title: planned.session.title, duration: nextPlayer.duration, elapsedTime: offset,
        rate: 1)
    } catch {
      fail("Narration could not start: \(error.localizedDescription)", token: token)
    }
  }

  private func completeSession(token: UUID, routeIndex: Int) {
    guard activeToken == token, let playback, playback.records.count == routeIndex,
      let player, let started = currentSessionStartedAt
    else { return }
    let now = clock()
    guard now <= playback.plan.deadline else {
      reachDeadline(token: token)
      return
    }
    let played = min(
      max(0, player.currentTime - currentSessionOffset), now.timeIntervalSince(started))
    do {
      var updated = playback
      let record = try updated.recordSession(
        startedAt: started, endedAt: now, playedDuration: played, outcome: .completed)
      self.playback = updated
      records.append(record)
      latestVerifiedCheckpoint = nil
      releasePlayer()
      startNextSession(token: token)
    } catch {
      fail("Completion could not be recorded: \(error.localizedDescription)", token: token)
    }
  }

  private func beginSilentRest(token: UUID) throws {
    guard activeToken == token, let playback else { return }
    _ = try playback.remainingRestSegments()
    waitingForNarration = false
    releasePlayer()
    removeRemoteCommands()
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    deactivateAudioSession()
    phase = .resting
    statusMessage = "Narration finished. Rest continues in silence until the fixed deadline."
  }

  private func reachDeadline(token: UUID) {
    guard activeToken == token, let playback else { return }
    let now = clock()
    if now < playback.plan.deadline {
      cancelDeadline?()
      cancelDeadline = scheduler(playback.plan.deadline.timeIntervalSince(now)) { [weak self] in
        self?.reachDeadline(token: token)
      }
      return
    }
    if now == playback.plan.deadline {
      recordPartialIfPossible(reason: .deadlineReached, token: token)
    } else {
      recordMissedDeadlinePartial(token: token, stoppedAt: now)
    }
    let hadNarration = player != nil
    clearRun()
    phase = .finished
    if hadNarration && now > playback.plan.deadline {
      statusMessage =
        records.last?.checkpointCapturedAt == nil
        ? "The fixed deadline passed and audio stopped. No verified partial checkpoint was available."
        : "Audio stopped after the fixed deadline. An earlier verified position was recorded for resumption."
    } else {
      statusMessage = "The fixed rest deadline arrived. Honkshool audio stopped."
    }
  }

  private func recordPartialIfPossible(reason: PartialPlaybackReason, token: UUID) {
    guard activeToken == token, let playback, let player,
      let started = currentSessionStartedAt, route.indices.contains(playback.records.count)
    else { return }
    let now = clock()
    guard now <= playback.plan.deadline, started <= now else { return }
    let offset = player.currentTime
    guard offset.isFinite, offset >= currentSessionOffset, offset < player.duration else { return }
    do {
      let planned = route[playback.records.count].planned
      let point = try ResumePoint(
        session: planned.session, audioOffset: offset,
        estimatedRemainingDuration: player.duration - offset)
      let played = min(max(0, offset - currentSessionOffset), now.timeIntervalSince(started))
      var updated = playback
      let record = try updated.recordSession(
        startedAt: started, endedAt: now, playedDuration: played,
        outcome: .partial(reason: reason, resumePoint: point))
      self.playback = updated
      records.append(record)
      latestVerifiedCheckpoint = NapRunCheckpoint(
        capturedAt: now, resumePoint: point, playedDuration: played)
    } catch {
      statusMessage = "A partial playback checkpoint could not be recorded."
    }
  }

  private func recordMissedDeadlinePartial(token: UUID, stoppedAt: Date) {
    guard activeToken == token, let playback, player != nil,
      let started = currentSessionStartedAt,
      let checkpoint = latestVerifiedCheckpoint,
      route.indices.contains(playback.records.count),
      checkpoint.resumePoint.matches(route[playback.records.count].planned.session)
    else { return }
    do {
      var updated = playback
      let record = try updated.recordSession(
        startedAt: started, endedAt: stoppedAt, playedDuration: checkpoint.playedDuration,
        outcome: .partial(reason: .deadlineMissed, resumePoint: checkpoint.resumePoint),
        checkpointCapturedAt: checkpoint.capturedAt)
      self.playback = updated
      records.append(record)
    } catch {
      statusMessage = "The late cutoff could not be recorded from its earlier checkpoint."
    }
  }

  private func fail(_ message: String, token: UUID) {
    guard activeToken == token else { return }
    recordPartialIfPossible(reason: .stopped, token: token)
    clearRun()
    phase = .failed
    statusMessage = message
  }

  private func captureCheckpoint(token: UUID) {
    guard activeToken == token, let playback, let player,
      let started = currentSessionStartedAt,
      route.indices.contains(playback.records.count)
    else { return }
    let now = clock()
    guard now >= started, now < playback.plan.deadline else { return }
    let offset = player.currentTime
    guard offset.isFinite, offset >= currentSessionOffset, offset < player.duration else { return }
    let planned = route[playback.records.count].planned
    if let point = try? ResumePoint(
      session: planned.session, audioOffset: offset,
      estimatedRemainingDuration: player.duration - offset)
    {
      latestVerifiedCheckpoint = NapRunCheckpoint(
        capturedAt: now, resumePoint: point,
        playedDuration: min(max(0, offset - currentSessionOffset), now.timeIntervalSince(started)))
    }
    cancelCheckpoint?()
    cancelCheckpoint = scheduler(min(5, playback.plan.deadline.timeIntervalSince(now))) {
      [weak self] in
      self?.captureCheckpoint(token: token)
    }
  }

  private func releasePlayer() {
    cancelCheckpoint?()
    cancelCheckpoint = nil
    player?.onCompletion = nil
    player?.onFailure = nil
    player?.stop()
    player = nil
    currentSessionStartedAt = nil
    currentSessionOffset = 0
  }

  private func clearRun() {
    activeToken = nil
    waitingForNarration = false
    cancelStart?()
    cancelStart = nil
    cancelNarrationStart?()
    cancelNarrationStart = nil
    cancelDeadline?()
    cancelDeadline = nil
    cancelCheckpoint?()
    cancelCheckpoint = nil
    releasePlayer()
    removeRemoteCommands()
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    deactivateAudioSession()
    playback = nil
    route = []
  }

  private func installAudioObservers() {
    let center = NotificationCenter.default
    observerTokens.append(
      center.addObserver(
        forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
      ) { [weak self] notification in
        Task { @MainActor in self?.handleInterruption(notification) }
      })
    observerTokens.append(
      center.addObserver(
        forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main
      ) { [weak self] notification in
        Task { @MainActor in self?.handleRouteChange(notification) }
      })
    observerTokens.append(
      center.addObserver(
        forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main
      ) { [weak self] _ in
        Task { @MainActor in
          guard let self, let token = self.activeToken else { return }
          self.fail("Audio services reset. Review a new Nap Plan before starting.", token: token)
        }
      })
  }

  private func handleInterruption(_ notification: Notification) {
    guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
      let type = AVAudioSession.InterruptionType(rawValue: raw)
    else { return }
    switch type {
    case .began:
      interruptionIsActive = true
      if waitingForNarration, let token = activeToken {
        fail("Audio was interrupted before narration. Review a new Nap Plan.", token: token)
        return
      }
      guard phase == .narrating || phase == .paused else { return }
      player?.pause()
      phase = .interrupted
      statusMessage = "Audio was interrupted. Resume manually when ready."
      updateNowPlayingRate(0)
    case .ended:
      interruptionIsActive = false
      if phase == .interrupted {
        statusMessage = "The interruption ended. Resume manually when ready."
      }
    @unknown default: break
    }
  }

  private func handleRouteChange(_ notification: Notification) {
    let raw = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt ?? 0
    guard AVAudioSession.RouteChangeReason(rawValue: raw) == .oldDeviceUnavailable else { return }
    if waitingForNarration, let token = activeToken {
      fail("Audio output disconnected before narration. Review a new Nap Plan.", token: token)
      return
    }
    guard
      phase == .narrating || phase == .paused
    else { return }
    player?.pause()
    phase = .interrupted
    statusMessage = "Audio output disconnected. Resume manually after choosing an output."
    updateNowPlayingRate(0)
  }

  private func installRemoteCommandsIfNeeded() {
    guard manageRemoteCommands, remoteCommandTokens.isEmpty else { return }
    let commands = MPRemoteCommandCenter.shared()
    commands.nextTrackCommand.isEnabled = false
    commands.previousTrackCommand.isEnabled = false
    commands.skipForwardCommand.isEnabled = false
    commands.skipBackwardCommand.isEnabled = false
    commands.changePlaybackPositionCommand.isEnabled = false
    let actions: [(MPRemoteCommand, @MainActor (NapRunController) -> Void)] = [
      (commands.playCommand, { $0.resume() }),
      (commands.pauseCommand, { $0.pause() }),
      (
        commands.togglePlayPauseCommand,
        {
          if $0.phase == .narrating { $0.pause() } else { $0.resume() }
        }
      ),
      (commands.stopCommand, { $0.stop() }),
    ]
    for (command, action) in actions {
      command.isEnabled = true
      let token = command.addTarget { [weak self] _ in
        guard let self, self.hasActiveRun else { return .commandFailed }
        Task { @MainActor in action(self) }
        return .success
      }
      remoteCommandTokens.append((command, token))
    }
  }

  private func removeRemoteCommands() {
    for (command, token) in remoteCommandTokens { command.removeTarget(token) }
    remoteCommandTokens.removeAll()
  }

  private func updateNowPlaying(
    title: String, duration: TimeInterval, elapsedTime: TimeInterval, rate: Float
  ) {
    MPNowPlayingInfoCenter.default().nowPlayingInfo = [
      MPMediaItemPropertyTitle: title,
      MPMediaItemPropertyArtist: "Honkshool",
      MPMediaItemPropertyPlaybackDuration: duration,
      MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsedTime,
      MPNowPlayingInfoPropertyPlaybackRate: rate,
      MPNowPlayingInfoPropertyDefaultPlaybackRate: 1,
      MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
      MPNowPlayingInfoPropertyIsLiveStream: false,
    ]
  }

  private func updateNowPlayingRate(_ rate: Float) {
    var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
    if let player { info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime }
    info[MPNowPlayingInfoPropertyPlaybackRate] = rate
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
  }
}
