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

/// A short, user-initiated sample. It never writes history or schedules an alarm.
@MainActor
final class NarrationPreviewController: ObservableObject {
  typealias Scheduler = @MainActor (TimeInterval, @escaping @MainActor () -> Void) -> (() -> Void)

  @Published private(set) var isPlaying = false
  @Published private(set) var status = "Ready to preview George."

  private let makePlayer: @MainActor (URL) throws -> NarrationPreviewPlaying
  private let activate: @MainActor () throws -> Void
  private let deactivate: @MainActor () -> Void
  private let schedule: Scheduler
  private let notifications: NotificationCenter
  private var player: NarrationPreviewPlaying?
  private var cancelLimit: (() -> Void)?
  private var observers: [NSObjectProtocol] = []
  private var ownsAudioActivation = false
  private var generation = 0

  init(
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
    self.makePlayer = makePlayer
    self.activate = activate
    self.deactivate = deactivate
    self.schedule = schedule
    self.notifications = notifications
  }

  /// The first published session is the only approved preview source.
  func start(catalog: PreparedCatalog, canPreview: Bool) {
    guard canPreview else {
      if isPlaying {
        stop(reason: "Preview stopped because another audio session began.")
      } else {
        status = "Finish the current rest or Feasibility Lab audio before previewing."
      }
      return
    }
    guard let prepared = catalog.sessions["turning-fuel-into-motion"],
      let asset = prepared.narrationAsset
    else {
      status = "George’s bundled recording is unavailable."
      return
    }
    do {
      let url = try prepared.narrationURL()
      let hash = SHA256.hash(data: try Data(contentsOf: url, options: .mappedIfSafe))
        .map { String(format: "%02x", $0) }.joined()
      guard hash == asset.sha256 else {
        status = "George’s bundled recording could not be verified."
        return
      }
      startVerified(url: url, canPreview: canPreview)
    } catch {
      status = "George’s bundled recording is unavailable."
    }
  }

  /// Internal seam permits bounded playback tests without activating system audio.
  func startVerified(url: URL, canPreview: Bool) {
    guard canPreview else {
      if isPlaying { stop(reason: "Preview stopped because another audio session began.") }
      return
    }
    guard !isPlaying else { return }
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
    cancelLimit?()
    cancelLimit = nil
    player?.stop()
    player = nil
    observers.forEach(notifications.removeObserver)
    observers.removeAll()
    if ownsAudioActivation { deactivate() }
    ownsAudioActivation = false
    isPlaying = false
    status = reason
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
        Task { @MainActor in
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
        Task { @MainActor in
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
          Task { @MainActor in
            guard self?.generation == activeGeneration else { return }
            self?.stop(reason: "Preview stopped.")
          }
        })
    }
  }
}
