import AVFoundation
import Combine
import CryptoKit
import Foundation
import UIKit

@MainActor
protocol NarrationPreviewPlaying: AnyObject {
  var onCompletion: (() -> Void)? { get set }
  var onFailure: (() -> Void)? { get set }
  func prepareToPlay() -> Bool
  func play() -> Bool
  func stop()
}

@MainActor
final class BundledNarrationPreviewPlayer: NSObject, NarrationPreviewPlaying, AVAudioPlayerDelegate
{
  var onCompletion: (() -> Void)?
  var onFailure: (() -> Void)?
  private let player: AVAudioPlayer

  init(url: URL) throws {
    player = try AVAudioPlayer(contentsOf: url)
    super.init()
    player.delegate = self
  }

  func prepareToPlay() -> Bool { player.prepareToPlay() }
  func play() -> Bool { player.play() }
  func stop() { player.stop() }

  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    if flag { onCompletion?() } else { onFailure?() }
  }

  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    onFailure?()
  }
}

enum NarrationPreviewVerification: Sendable {
  case verified(URL)
  case unavailable
  case mismatch
}

/// A short, user-initiated sample. It never writes history or schedules an alarm.
@MainActor
final class NarrationPreviewController: ObservableObject {
  typealias Scheduler = @MainActor (TimeInterval, @escaping @MainActor () -> Void) -> (() -> Void)

  @Published private(set) var isPlaying = false
  @Published private(set) var isPreparing = false
  @Published private(set) var status = "Ready to preview George."

  private let verify: @Sendable (PreparedSession) -> NarrationPreviewVerification
  private let isForeground: @MainActor () -> Bool
  private let makePlayer: @MainActor (URL) throws -> NarrationPreviewPlaying
  private let activate: @MainActor () throws -> Void
  private let deactivate: @MainActor () -> Void
  private let schedule: Scheduler
  private let notifications: NotificationCenter
  private var player: NarrationPreviewPlaying?
  private var preparation: Task<Void, Never>?
  private var cancelLimit: (() -> Void)?
  private var observers: [NSObjectProtocol] = []
  private var ownsAudioActivation = false
  private var generation = 0

  init(
    verify: @escaping @Sendable (PreparedSession) -> NarrationPreviewVerification = {
      NarrationPreviewController.verifyBundledAudio($0)
    },
    isForeground: @escaping @MainActor () -> Bool = {
      UIApplication.shared.applicationState == .active
    },
    makePlayer: @escaping @MainActor (URL) throws -> NarrationPreviewPlaying = {
      try BundledNarrationPreviewPlayer(url: $0)
    },
    activate: @escaping @MainActor () throws -> Void = {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
      try session.setActive(true)
    },
    deactivate: @escaping @MainActor () -> Void = {
      try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    },
    schedule: @escaping Scheduler = { delay, action in
      let task = Task { @MainActor in
        try? await Task.sleep(for: .seconds(delay))
        guard !Task.isCancelled else { return }
        action()
      }
      return { task.cancel() }
    },
    notifications: NotificationCenter = .default
  ) {
    self.verify = verify
    self.isForeground = isForeground
    self.makePlayer = makePlayer
    self.activate = activate
    self.deactivate = deactivate
    self.schedule = schedule
    self.notifications = notifications
  }

  /// The first published session is the only approved preview source.
  func start(catalog: PreparedCatalog, canPreview: Bool) {
    guard canPreview else {
      if isPreparing || isPlaying {
        stop(reason: "Preview stopped because another audio session began.")
      } else {
        status = "Finish the current rest or Feasibility Lab audio before previewing."
      }
      return
    }
    guard !isPreparing, !isPlaying else { return }
    guard isForeground() else {
      status = "Preview stopped."
      return
    }
    guard let prepared = catalog.sessions["turning-fuel-into-motion"],
      prepared.narrationAsset != nil
    else {
      status = "George’s bundled recording is unavailable."
      return
    }

    generation += 1
    let activeGeneration = generation
    isPreparing = true
    status = "Checking George’s bundled recording."
    installObservers()
    let verify = self.verify
    preparation = Task { [weak self] in
      let worker = Task.detached(priority: .utility) { verify(prepared) }
      let result = await withTaskCancellationHandler {
        await worker.value
      } onCancel: {
        worker.cancel()
      }
      guard let self, !Task.isCancelled, self.generation == activeGeneration else { return }
      self.preparation = nil
      self.isPreparing = false
      self.removeObservers()
      guard self.isForeground() else {
        self.status = "Preview stopped."
        return
      }
      switch result {
      case .verified(let url):
        self.startVerified(url: url, canPreview: true)
      case .unavailable:
        self.status = "George’s bundled recording is unavailable."
      case .mismatch:
        self.status = "George’s bundled recording could not be verified."
      }
    }
  }

  nonisolated private static func verifyBundledAudio(
    _ prepared: PreparedSession
  ) -> NarrationPreviewVerification {
    guard !Task<Never, Never>.isCancelled else { return .unavailable }
    do {
      let url = try prepared.narrationURL()
      guard !Task<Never, Never>.isCancelled else { return .unavailable }
      let bytes = try Data(contentsOf: url, options: .mappedIfSafe)
      guard !Task<Never, Never>.isCancelled else { return .unavailable }
      let hash = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
      return hash == prepared.narrationAsset?.sha256 ? .verified(url) : .mismatch
    } catch {
      return .unavailable
    }
  }

  /// Internal seam permits bounded playback tests without activating system audio.
  func startVerified(url: URL, canPreview: Bool) {
    guard canPreview else {
      if isPreparing || isPlaying {
        stop(reason: "Preview stopped because another audio session began.")
      }
      return
    }
    guard !isPreparing, !isPlaying else { return }
    guard isForeground() else {
      stop(reason: "Preview stopped.")
      return
    }
    generation += 1
    let activeGeneration = generation
    do {
      let next = try makePlayer(url)
      guard next.prepareToPlay() else {
        status = "George’s preview could not be prepared."
        return
      }
      try activate()
      ownsAudioActivation = true
      player = next
      next.onCompletion = { [weak self] in
        guard self?.generation == activeGeneration else { return }
        self?.stop(reason: "Preview finished.")
      }
      next.onFailure = { [weak self] in
        guard self?.generation == activeGeneration else { return }
        self?.stop(reason: "George’s preview stopped unexpectedly.")
      }
      installObservers()
      guard next.play() else {
        stop(reason: "George’s preview could not start.")
        return
      }
      guard player != nil else { return }
      isPlaying = true
      status = "Playing a 12-second George preview."
      cancelLimit = schedule(12) { [weak self] in
        guard self?.generation == activeGeneration else { return }
        self?.stop(reason: "Preview finished.")
      }
    } catch {
      stop(reason: "George’s preview could not start.")
    }
  }

  func stop(reason: String = "Preview stopped.") {
    generation += 1
    preparation?.cancel()
    preparation = nil
    isPreparing = false
    cancelLimit?()
    cancelLimit = nil
    player?.stop()
    player = nil
    removeObservers()
    if ownsAudioActivation { deactivate() }
    ownsAudioActivation = false
    isPlaying = false
    status = reason
  }

  private func removeObservers() {
    observers.forEach(notifications.removeObserver)
    observers.removeAll()
  }

  private func installObservers() {
    let activeGeneration = generation
    observers.append(
      notifications.addObserver(
        forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
      ) { [weak self] notification in
        guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
          raw == AVAudioSession.InterruptionType.began.rawValue
        else { return }
        MainActor.assumeIsolated {
          guard self?.generation == activeGeneration else { return }
          self?.stop(reason: "Audio was interrupted. Preview stopped.")
        }
      })
    observers.append(
      notifications.addObserver(
        forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main
      ) { [weak self] notification in
        guard let raw = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
          raw == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue
        else { return }
        MainActor.assumeIsolated {
          guard self?.generation == activeGeneration else { return }
          self?.stop(reason: "Audio output disconnected. Preview stopped.")
        }
      })
    for name in [
      UIApplication.didEnterBackgroundNotification,
      AVAudioSession.mediaServicesWereResetNotification,
    ] {
      observers.append(
        notifications.addObserver(forName: name, object: nil, queue: .main) {
          [weak self] _ in
          MainActor.assumeIsolated {
            guard self?.generation == activeGeneration else { return }
            self?.stop(reason: "Preview stopped.")
          }
        })
    }
  }
}
