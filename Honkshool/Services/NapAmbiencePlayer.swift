import AVFoundation

@MainActor
protocol NapAmbiencePlaying: AnyObject {
  var onFailure: ((String) -> Void)? { get set }

  func prepareToPlay() -> Bool
  func play() -> Bool
  func pause()
  func stop()
}

/// Plays the prepared file at its authored level and rate. Runtime owns the
/// deadline and audio session; this adapter only owns the looping file player.
@MainActor
final class NapAmbiencePlayer: NSObject, NapAmbiencePlaying {
  var onFailure: ((String) -> Void)?

  private let player: AVAudioPlayer
  private var expectsPlayback = false

  var isPlaying: Bool { player.isPlaying }

  init(url: URL) throws {
    player = try AVAudioPlayer(contentsOf: url)
    super.init()
    player.numberOfLoops = -1
    player.delegate = self
  }

  func prepareToPlay() -> Bool {
    let ready = player.prepareToPlay()
    if !ready { onFailure?("Gentle rain could not be prepared for playback.") }
    return ready
  }

  func play() -> Bool {
    let started = player.play()
    expectsPlayback = started
    if !started { onFailure?("Gentle rain could not start playing.") }
    return started
  }

  func pause() {
    expectsPlayback = false
    player.pause()
  }

  func stop() {
    expectsPlayback = false
    player.stop()
  }
}

extension NapAmbiencePlayer: AVAudioPlayerDelegate {
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    guard expectsPlayback else { return }
    expectsPlayback = false
    onFailure?("Gentle rain ended unexpectedly.")
  }

  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    guard expectsPlayback else { return }
    expectsPlayback = false
    onFailure?(error?.localizedDescription ?? "Gentle rain could not be decoded.")
  }
}
