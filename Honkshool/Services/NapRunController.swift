import AVFoundation
import Combine
import MediaPlayer

enum NapRunPhase: Equatable {
  case idle
  case waiting
  case narrating
  case ambience
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
  case contentUnavailable
  case invalidCheckpoint
  case audioUnavailable
  case invalidTimerPlan
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

/// Executes only the reviewed route. Alarm scheduling and history storage have separate owners.
@MainActor
final class NapRunController: NSObject, ObservableObject {
  @Published private(set) var phase: NapRunPhase = .idle
  @Published private(set) var statusMessage = "Ready to start a reviewed plan."
  @Published private(set) var records: [PlaybackRecord] = []
  @Published private(set) var latestVerifiedCheckpoint: NapRunCheckpoint?
  @Published private(set) var lastRunPlanID: String?
  /// Read-only presentation snapshot survives Stop so every tab shows the same fixed timing.
  @Published private(set) var presentationPlan: NapPlan?

  var currentNarrationTitle: String? {
    guard let presentationPlan,
      [.narrating, .paused, .interrupted].contains(phase),
      presentationPlan.route.indices.contains(records.count)
    else { return nil }
    return presentationPlan.route[records.count].session.title
  }

  private struct PreparedRouteItem {
    let planned: PlannedSession
    let prepared: PreparedSession
    let url: URL
  }

  private let playerFactory: @MainActor (URL) throws -> NapRunAudioPlaying
  private let ambienceFactory: @MainActor (URL) throws -> NapAmbiencePlaying
  private let resolveAmbience: @MainActor (String) throws -> URL
  private let clock: @MainActor () -> Date
  private let scheduler: NapRunScheduler
  private let activateAudioSession: @MainActor () throws -> Void
  private let deactivateAudioSession: @MainActor () -> Void
  private let manageRemoteCommands: Bool
  private let history: (any NapHistoryRecording)?
  private var route: [PreparedRouteItem] = []
  private var playback: NapPlayback?
  private var player: NapRunAudioPlaying?
  private var ambiencePlayer: NapAmbiencePlaying?
  private var ambienceURL: URL?
  private var ambienceToken: UUID?
  private var restFailureMessage: String?
  private var isSettling = false
  private var currentSessionStartedAt: Date?
  private var currentSessionOffset: TimeInterval = 0
  private var activeToken: UUID?
  private var cancelStart: (@MainActor () -> Void)?
  private var cancelNarrationStart: (@MainActor () -> Void)?
  private var cancelDeadline: (@MainActor () -> Void)?
  private var cancelCheckpoint: (@MainActor () -> Void)?
  private var interruptionIsActive = false
  private var appIsForeground = true
  private var waitingForPlayback = false

  /// Silent settling before narration still requires the foreground start gate.
  var hasPassedPlaybackAdmission: Bool { hasActiveRun && !waitingForPlayback }
  private var activeRunHasWakeAlarm = false
  private var observerTokens: [NSObjectProtocol] = []
  private var remoteCommandTokens: [(MPRemoteCommand, Any)] = []

  var hasActiveRun: Bool {
    switch phase {
    case .waiting, .narrating, .ambience, .paused, .interrupted, .resting: true
    default: false
    }
  }

  var canPause: Bool { phase == .narrating || phase == .ambience }
  var canResume: Bool {
    (phase == .paused || phase == .interrupted) && !interruptionIsActive
  }

  init(
    playerFactory: @escaping @MainActor (URL) throws -> NapRunAudioPlaying = {
      try NapRunAudioPlayer(url: $0)
    },
    ambienceFactory: @escaping @MainActor (URL) throws -> NapAmbiencePlaying = {
      try NapAmbiencePlayer(url: $0)
    },
    resolveAmbience: @escaping @MainActor (String) throws -> URL = {
      try PreparedAmbience.resolve(id: $0)
    },
    clock: @escaping @MainActor () -> Date = { .now },
    scheduler: @escaping NapRunScheduler = { delay, action in
      let task = Task { @MainActor in
        do {
          // Default clock tolerance may coalesce a one-minute start beyond the
          // approved start window. Keep start, checkpoint, and cutoff timing precise.
          try await Task.sleep(for: .seconds(max(0, delay)), tolerance: .zero)
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
    manageRemoteCommands: Bool = true,
    history: (any NapHistoryRecording)? = nil
  ) {
    self.playerFactory = playerFactory
    self.ambienceFactory = ambienceFactory
    self.resolveAmbience = resolveAmbience
    self.clock = clock
    self.scheduler = scheduler
    self.activateAudioSession = activateAudioSession
    self.deactivateAudioSession = deactivateAudioSession
    self.manageRemoteCommands = manageRemoteCommands
    self.history = history
    super.init()
    if observeSystemEvents { installAudioObservers() }
  }

  deinit {
    for token in observerTokens { NotificationCenter.default.removeObserver(token) }
    for (command, token) in remoteCommandTokens { command.removeTarget(token) }
  }

  func preflight(review: NapPlanReview, catalog: PreparedCatalog) throws {
    _ = try preparedRoute(for: review, catalog: catalog)
  }

  func start(
    review: NapPlanReview, catalog: PreparedCatalog,
    scheduledAlarm: ScheduledNapAlarm? = nil
  ) throws {
    let preparedRoute = try preparedRoute(for: review, catalog: catalog)
    if let deadline = review.plan.wakeAlarm {
      guard let scheduledAlarm, scheduledAlarm.planID == review.plan.id,
        scheduledAlarm.deadline == deadline
      else { throw NapRunError.alarmUnavailable }
    } else if scheduledAlarm != nil {
      throw NapRunError.alarmUnavailable
    }
    let nextPlayback = try NapPlayback(plan: review.plan, runID: UUID().uuidString)
    let resolvedRain: URL?
    if case .ambience(let id) = review.plan.fallback {
      resolvedRain = try? resolveAmbience(id)
    } else {
      resolvedRain = nil
    }
    // Asset resolution and an earlier AlarmKit await may consume the last
    // instant of the approved start window.
    let now = clock()
    guard now <= review.plan.start else { throw NapRunError.staleStart }
    route = preparedRoute
    playback = nextPlayback
    ambienceURL = resolvedRain
    restFailureMessage =
      review.plan.fallback != .silence && resolvedRain == nil
      ? "The selected rest sound is unavailable. Rest continues in silence." : nil
    presentationPlan = review.plan
    lastRunPlanID = review.plan.id
    records = []
    latestVerifiedCheckpoint = nil
    activeRunHasWakeAlarm = scheduledAlarm != nil
    let token = UUID()
    activeToken = token
    waitingForPlayback = true
    phase = .waiting
    statusMessage = "Keep Honkshool open until playback begins at the approved start."
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

  /// Start an approved timer in the foreground without a narration catalog or
  /// a future start task. Its deadline was fixed when the timer was created.
  func startTimer(
    plan: NapPlan, scheduledAlarm: ScheduledNapAlarm? = nil
  ) throws {
    guard plan.isTimer, plan.route.isEmpty, plan.transitions.isEmpty else {
      throw NapRunError.invalidTimerPlan
    }
    guard !hasActiveRun else { throw NapRunError.alreadyRunning }
    guard !interruptionIsActive, appIsForeground else { throw NapRunError.audioUnavailable }
    if let deadline = plan.wakeAlarm {
      guard let scheduledAlarm, scheduledAlarm.planID == plan.id,
        scheduledAlarm.deadline == deadline
      else { throw NapRunError.alarmUnavailable }
    } else if scheduledAlarm != nil {
      throw NapRunError.alarmUnavailable
    }
    let nextPlayback = try NapPlayback(plan: plan, runID: UUID().uuidString)
    let resolvedRain: URL?
    if case .ambience(let id) = plan.fallback {
      resolvedRain = try? resolveAmbience(id)
    } else {
      resolvedRain = nil
    }
    let now = clock()
    guard plan.canStartTimer(at: now) else { throw NapRunError.staleStart }
    route = []
    playback = nextPlayback
    ambienceURL = resolvedRain
    restFailureMessage =
      plan.fallback != .silence && resolvedRain == nil
      ? "The selected rest sound is unavailable. Rest continues in silence." : nil
    presentationPlan = plan
    lastRunPlanID = plan.id
    records = []
    latestVerifiedCheckpoint = nil
    activeRunHasWakeAlarm = scheduledAlarm != nil
    let token = UUID()
    activeToken = token
    waitingForPlayback = true
    phase = .waiting
    statusMessage = "Starting the rest timer."
    cancelDeadline = scheduler(plan.deadline.timeIntervalSince(now)) { [weak self] in
      self?.reachDeadline(token: token)
    }
    beginAtPlannedStart(token: token)
  }

  private func preparedRoute(
    for review: NapPlanReview, catalog: PreparedCatalog
  ) throws -> [PreparedRouteItem] {
    guard !hasActiveRun else { throw NapRunError.alreadyRunning }
    guard !interruptionIsActive, appIsForeground else { throw NapRunError.audioUnavailable }
    let now = clock()
    guard now.timeIntervalSinceReferenceDate.isFinite, now <= review.plan.start,
      now < review.plan.deadline
    else { throw NapRunError.staleStart }

    return try review.plan.route.map { planned -> PreparedRouteItem in
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
  }

  func pause() {
    guard canPause else { return }
    pauseOutput()
    phase = .paused
    statusMessage = "Paused. Resume explicitly when ready."
    updateNowPlayingRate(0)
  }

  private func pauseOutput() {
    player?.pause()
    ambiencePlayer?.pause()
    cancelNarrationStart?()
    cancelNarrationStart = nil
    if let token = activeToken { captureCheckpoint(token: token) }
  }

  func resume() {
    guard canResume, let token = activeToken, let playback else { return }
    guard clock() < playback.plan.deadline else {
      reachDeadline(token: token)
      return
    }
    if (isSettling && clock() >= playback.plan.narrationStart)
      || (!isSettling && player == nil && ambiencePlayer == nil)
    {
      // A paused completion must still advance through the entire approved route.
      // A pause never moves the approved narration window or wake deadline.
      phase = .resting
      startNextSession(token: token)
      return
    }
    do {
      try activateAudioSession()
      guard clock() < playback.plan.deadline else {
        reachDeadline(token: token)
        return
      }
      if let player {
        guard player.play() else {
          fail("Prepared narration could not resume.", token: token)
          return
        }
        guard clock() < playback.plan.deadline else {
          reachDeadline(token: token)
          return
        }
        phase = .narrating
        statusMessage = "Narration resumed."
      } else if let ambiencePlayer {
        // Session reactivation may have consumed the rest of settling.
        if isSettling && clock() >= playback.plan.narrationStart {
          phase = .resting
          startNextSession(token: token)
          return
        }
        let generation = ambienceToken
        guard ambiencePlayer.play() else {
          fallBackToSilence("Gentle rain could not resume.", token: token)
          return
        }
        guard activeToken == token, ambienceToken == generation else { return }
        guard clock() < playback.plan.deadline else {
          reachDeadline(token: token)
          return
        }
        phase = .ambience
        statusMessage = "Gentle rain resumed."
        scheduleNarrationAfterSettling(token: token)
      } else {
        beginRest(token: token, settling: isSettling)
        scheduleNarrationAfterSettling(token: token)
        return
      }
      updateNowPlayingRate(1)
    } catch {
      if player != nil {
        fail("Audio could not resume: \(error.localizedDescription)", token: token)
      } else {
        fallBackToSilence("Gentle rain could not resume.", token: token)
      }
    }
  }

  func stop() {
    guard let token = activeToken else { return }
    if let playback, clock() >= playback.plan.deadline {
      reachDeadline(token: token)
      return
    }
    recordPartialIfPossible(reason: .stopped, token: token)
    let hadWakeAlarm = activeRunHasWakeAlarm
    let stopped = playback?.plan.isTimer == true ? "Rest stopped." : "Playback stopped."
    clearRun()
    phase = .stopped
    statusMessage =
      hadWakeAlarm
      ? "\(stopped) The wake alarm was not cancelled here; check its status separately."
      : "\(stopped) No wake alarm was scheduled."
  }

  private var restartInstruction: String {
    presentationPlan?.isTimer == true ? "Set a new timer." : "Review a new Nap Plan."
  }

  func scenePhaseChanged(isActive: Bool) {
    appIsForeground = isActive
    guard !isActive, let token = activeToken else { return }
    if waitingForPlayback {
      fail(
        "The app left the foreground before playback began. \(restartInstruction)", token: token)
    } else {
      captureCheckpoint(token: token)
    }
  }

  func resetPresentation() {
    guard !hasActiveRun else { return }
    records = []
    latestVerifiedCheckpoint = nil
    lastRunPlanID = nil
    presentationPlan = nil
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
      fail("The app must stay open until playback begins. \(restartInstruction)", token: token)
      return
    }
    // A suspended app may deliver the start timer long after the approved instant.
    let startIsValid =
      playback.plan.isTimer
      ? playback.plan.canStartTimer(at: now)
      : now.timeIntervalSince(playback.plan.start) <= 1
    guard startIsValid else {
      clearRun()
      phase = .failed
      statusMessage =
        playback.plan.isTimer
        ? "The timer start took too long. Set a new timer."
        : "The approved start passed. Review a new Nap Plan before starting."
      return
    }
    guard !interruptionIsActive else {
      clearRun()
      phase = .failed
      statusMessage =
        playback.plan.isTimer
        ? "Audio is interrupted. Set a new timer when it ends."
        : "Audio is interrupted. Review a new Nap Plan when it ends."
      return
    }
    if route.isEmpty {
      beginRest(token: token, settling: false)
    } else if now < playback.plan.narrationStart {
      beginRest(token: token, settling: true)
      scheduleNarrationAfterSettling(token: token)
    } else {
      startNextSession(token: token)
    }
  }

  private func scheduleNarrationAfterSettling(token: UUID) {
    guard activeToken == token, isSettling, let playback,
      phase != .paused, phase != .interrupted
    else { return }
    cancelNarrationStart?()
    cancelNarrationStart = scheduler(
      max(0, playback.plan.narrationStart.timeIntervalSince(clock()))
    ) {
      [weak self] in
      self?.startNextSession(token: token)
    }
  }

  private func startNextSession(token: UUID) {
    guard activeToken == token, let playback, phase != .paused, phase != .interrupted else {
      return
    }
    if waitingForPlayback && !appIsForeground {
      fail("The app must stay open until playback begins. \(restartInstruction)", token: token)
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
        _ = try playback.remainingRestSegments()
        beginRest(token: token, settling: false)
        return
      }
      let index = playback.records.count
      guard route.indices.contains(index), route[index].planned == planned else {
        fail("The approved narration route is unavailable.", token: token)
        return
      }
      let item = route[index]
      isSettling = false
      releaseAmbience()
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
        guard let self, self.playback?.records.count == index else { return }
        self.fail(message, token: token)
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
        nextPlayer.onCompletion = nil
        nextPlayer.onFailure = nil
        nextPlayer.stop()
        fail("The prepared narration could not start.", token: token)
        return
      }
      guard activeToken == token else {
        nextPlayer.stop()
        return
      }
      player = nextPlayer
      currentSessionStartedAt = started
      currentSessionOffset = offset
      guard clock() < playback.plan.deadline else {
        reachDeadline(token: token)
        return
      }
      waitingForPlayback = false
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
    // Successful completion proves the file reached its end. AVAudioPlayer may
    // rewind currentTime before this callback, so it is no longer position evidence.
    let played = min(
      max(0, player.duration - currentSessionOffset), max(0, now.timeIntervalSince(started)))
    do {
      var updated = playback
      let record = try updated.recordSession(
        startedAt: started, endedAt: now, playedDuration: played, outcome: .completed)
      self.playback = updated
      records.append(record)
      history?.save(record, isCheckpoint: false)
      latestVerifiedCheckpoint = nil
      releasePlayer()
      startNextSession(token: token)
    } catch {
      fail("Completion could not be recorded: \(error.localizedDescription)", token: token)
    }
  }

  private func beginRest(token: UUID, settling: Bool) {
    guard activeToken == token, let playback else { return }
    guard clock() < playback.plan.deadline else {
      reachDeadline(token: token)
      return
    }
    isSettling = settling
    releasePlayer()
    releaseAmbience()
    guard let ambienceURL, restFailureMessage == nil else {
      presentSilentRest()
      return
    }
    do {
      try activateAudioSession()
      let nextPlayer = try ambienceFactory(ambienceURL)
      guard nextPlayer.prepareToPlay() else {
        nextPlayer.stop()
        fallBackToSilence("Gentle rain could not be prepared.", token: token)
        return
      }
      guard clock() < playback.plan.deadline else {
        nextPlayer.stop()
        reachDeadline(token: token)
        return
      }
      if playback.plan.isTimer && waitingForPlayback
        && !playback.plan.canStartTimer(at: clock())
      {
        nextPlayer.stop()
        fail("The timer start took too long. Set a new timer.", token: token)
        return
      }
      if settling && clock() >= playback.plan.narrationStart {
        nextPlayer.stop()
        startNextSession(token: token)
        return
      }
      let generation = UUID()
      ambienceToken = generation
      ambiencePlayer = nextPlayer
      nextPlayer.onFailure = { [weak self] _ in
        guard let self, self.ambienceToken == generation else { return }
        self.fallBackToSilence("Gentle rain stopped unexpectedly.", token: token)
      }
      guard nextPlayer.play() else {
        fallBackToSilence("Gentle rain could not start.", token: token)
        return
      }
      guard activeToken == token, ambienceToken == generation else { return }
      guard clock() < playback.plan.deadline else {
        reachDeadline(token: token)
        return
      }
      if playback.plan.isTimer && waitingForPlayback
        && !playback.plan.canStartTimer(at: clock())
      {
        fail("The timer start took too long. Set a new timer.", token: token)
        return
      }
      waitingForPlayback = false
      phase = .ambience
      statusMessage =
        settling
        ? "Gentle rain is playing until narration begins."
        : "Gentle rain is playing until the fixed deadline."
      installRemoteCommandsIfNeeded()
      MPNowPlayingInfoCenter.default().nowPlayingInfo = [
        MPMediaItemPropertyTitle: "Gentle rain",
        MPMediaItemPropertyArtist: "Honkshool",
        MPNowPlayingInfoPropertyPlaybackRate: 1,
        MPNowPlayingInfoPropertyDefaultPlaybackRate: 1,
        MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
        MPNowPlayingInfoPropertyIsLiveStream: false,
      ]
    } catch {
      fallBackToSilence("Gentle rain is unavailable.", token: token)
    }
  }

  private func fallBackToSilence(_ message: String, token: UUID) {
    guard activeToken == token, let playback else { return }
    guard clock() < playback.plan.deadline else {
      reachDeadline(token: token)
      return
    }
    // Failed setup must meet the same admission limit as successful rain.
    // A sound failure after admission may still continue the rest in silence.
    if playback.plan.isTimer && waitingForPlayback
      && !playback.plan.canStartTimer(at: clock())
    {
      fail("The timer start took too long. Set a new timer.", token: token)
      return
    }
    let wasPaused = phase == .paused || phase == .interrupted
    let previousPhase = phase
    releaseAmbience()
    restFailureMessage = "\(message) Rest continues in silence."
    presentSilentRest()
    guard activeToken == token else { return }
    // Losing the sound must never undo an explicit pause or interruption.
    if wasPaused {
      phase = previousPhase
      statusMessage = "Gentle rain is unavailable. Resume explicitly to continue the plan."
      installRemoteCommandsIfNeeded()
      MPNowPlayingInfoCenter.default().nowPlayingInfo = [
        MPMediaItemPropertyTitle: "Resting in silence",
        MPMediaItemPropertyArtist: "Honkshool",
        MPNowPlayingInfoPropertyPlaybackRate: 0,
        MPNowPlayingInfoPropertyDefaultPlaybackRate: 1,
        MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
        MPNowPlayingInfoPropertyIsLiveStream: false,
      ]
    } else {
      scheduleNarrationAfterSettling(token: token)
    }
  }

  private func presentSilentRest() {
    waitingForPlayback = isSettling
    removeRemoteCommands()
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    deactivateAudioSession()
    phase = .resting
    statusMessage =
      restFailureMessage
      ?? (isSettling
        ? "Resting in silence until narration begins."
        : "Rest continues in silence until the fixed deadline.")
    if isSettling && !appIsForeground, let token = activeToken {
      fail(
        "Rain became unavailable before narration while the app was backgrounded. Review a new Nap Plan.",
        token: token)
    }
  }

  private func releaseAmbience() {
    ambienceToken = nil
    ambiencePlayer?.onFailure = nil
    ambiencePlayer?.stop()
    ambiencePlayer = nil
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
    let hadRain = ambiencePlayer != nil
    let hadWakeAlarm = activeRunHasWakeAlarm
    clearRun()
    phase = .finished
    if hadNarration && now > playback.plan.deadline {
      statusMessage =
        records.last?.checkpointCapturedAt == nil
        ? "The fixed deadline passed and audio stopped. No verified partial checkpoint was available."
        : "Audio stopped after the fixed deadline. An earlier verified position was recorded for resumption."
    } else if hadRain && now > playback.plan.deadline {
      statusMessage = "Gentle rain stopped after the fixed deadline."
    } else {
      statusMessage =
        hadWakeAlarm
        ? "The fixed rest deadline arrived. Honkshool audio stopped; the system wake alarm was scheduled separately."
        : "The fixed rest deadline arrived. Honkshool audio stopped."
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
        estimatedRemainingDuration: player.duration - offset,
        audioAssetSHA256: route[playback.records.count].prepared.narrationAsset?.sha256)
      let played = min(max(0, offset - currentSessionOffset), now.timeIntervalSince(started))
      var updated = playback
      let record = try updated.recordSession(
        startedAt: started, endedAt: now, playedDuration: played,
        outcome: .partial(reason: reason, resumePoint: point))
      self.playback = updated
      records.append(record)
      history?.save(record, isCheckpoint: false)
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
      history?.save(record, isCheckpoint: false)
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
      estimatedRemainingDuration: player.duration - offset,
      audioAssetSHA256: route[playback.records.count].prepared.narrationAsset?.sha256)
    {
      latestVerifiedCheckpoint = NapRunCheckpoint(
        capturedAt: now, resumePoint: point,
        playedDuration: min(max(0, offset - currentSessionOffset), now.timeIntervalSince(started)))
      // A copied domain run validates this evidence without ending the live run.
      // On relaunch it remains a checkpoint at this instant, never a guessed stop time.
      var snapshot = playback
      if let record = try? snapshot.recordSession(
        startedAt: started, endedAt: now,
        playedDuration: min(max(0, offset - currentSessionOffset), now.timeIntervalSince(started)),
        outcome: .partial(reason: .interrupted, resumePoint: point))
      {
        history?.save(record, isCheckpoint: true)
      }
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
    waitingForPlayback = false
    activeRunHasWakeAlarm = false
    cancelStart?()
    cancelStart = nil
    cancelNarrationStart?()
    cancelNarrationStart = nil
    cancelDeadline?()
    cancelDeadline = nil
    cancelCheckpoint?()
    cancelCheckpoint = nil
    releasePlayer()
    releaseAmbience()
    ambienceURL = nil
    restFailureMessage = nil
    isSettling = false
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
          guard let self, let token = self.activeToken,
            self.player != nil || self.ambiencePlayer != nil
          else { return }
          // Only initialized audio players are invalidated by a media reset.
          // Player-free silent rest keeps its independently scheduled deadline.
          self.fail("Audio services reset. \(self.restartInstruction)", token: token)
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
      if waitingForPlayback, let token = activeToken {
        fail("Audio was interrupted before playback. \(restartInstruction)", token: token)
        return
      }
      guard canPause || phase == .paused else { return }
      pauseOutput()
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
    if waitingForPlayback, let token = activeToken {
      fail("Audio output disconnected before playback. \(restartInstruction)", token: token)
      return
    }
    guard canPause || phase == .paused else { return }
    pauseOutput()
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
          if $0.canPause { $0.pause() } else { $0.resume() }
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
