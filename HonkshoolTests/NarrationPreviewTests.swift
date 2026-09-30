import AVFoundation
import Foundation
import XCTest

@testable import Honkshool

@MainActor
private final class FakePreviewPlayer: NarrationPreviewPlaying {
  var onCompletion: (() -> Void)?
  var onFailure: (() -> Void)?
  var stopped = false
  var played = false
  func prepareToPlay() -> Bool { true }
  func play() -> Bool {
    played = true
    return true
  }
  func stop() { stopped = true }
}

final class NarrationPreviewTests: XCTestCase {
  @MainActor
  func testExplicitStartAndTwelveSecondLimitReleaseOnlyOwnedAudio() {
    let player = FakePreviewPlayer()
    var activations = 0
    var deactivations = 0
    var scheduledDelay: TimeInterval?
    var expiration: (@MainActor () -> Void)?
    let controller = NarrationPreviewController(
      makePlayer: { _ in player },
      activate: { activations += 1 },
      deactivate: { deactivations += 1 },
      schedule: { delay, action in
        scheduledDelay = delay
        expiration = action
        return { expiration = nil }
      },
      notifications: NotificationCenter())

    XCTAssertEqual(activations, 0)
    controller.startVerified(url: URL(fileURLWithPath: "/unused.wav"), canPreview: false)
    XCTAssertEqual(activations, 0)
    controller.startVerified(url: URL(fileURLWithPath: "/unused.wav"), canPreview: true)
    XCTAssertTrue(player.played)
    XCTAssertTrue(controller.isPlaying)
    XCTAssertEqual(scheduledDelay, 12)
    XCTAssertEqual(activations, 1)
    expiration?()
    XCTAssertFalse(controller.isPlaying)
    XCTAssertTrue(player.stopped)
    XCTAssertEqual(deactivations, 1)
    XCTAssertNil(expiration)
  }

  @MainActor
  func testCompletionAndFailureStopPreview() {
    let player = FakePreviewPlayer()
    var deactivations = 0
    let controller = NarrationPreviewController(
      makePlayer: { _ in player }, activate: {},
      deactivate: { deactivations += 1 }, notifications: NotificationCenter())
    controller.startVerified(url: URL(fileURLWithPath: "/unused.wav"), canPreview: true)
    player.onCompletion?()
    XCTAssertEqual(controller.status, "Preview finished.")
    XCTAssertEqual(deactivations, 1)
    XCTAssertFalse(controller.isPlaying)
  }

  @MainActor
  func testVerifiedBundledFirstSessionCanStartWithoutSystemAudio() throws {
    let catalog = try PreparedCatalog.load()
    let player = FakePreviewPlayer()
    let controller = NarrationPreviewController(
      makePlayer: { _ in player }, activate: {}, deactivate: {},
      notifications: NotificationCenter())
    controller.start(catalog: catalog, canPreview: true)
    XCTAssertTrue(controller.isPlaying)
    XCTAssertTrue(player.played)
    controller.stop()
  }

  @MainActor
  func testRouteLossStopsPreview() async {
    let center = NotificationCenter()
    let player = FakePreviewPlayer()
    var deactivations = 0
    let controller = NarrationPreviewController(
      makePlayer: { _ in player }, activate: {},
      deactivate: { deactivations += 1 }, notifications: center)
    controller.startVerified(url: URL(fileURLWithPath: "/unused.wav"), canPreview: true)
    center.post(
      name: AVAudioSession.routeChangeNotification, object: nil,
      userInfo: [
        AVAudioSessionRouteChangeReasonKey:
          AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue
      ])
    await Task.yield()
    XCTAssertFalse(controller.isPlaying)
    XCTAssertEqual(deactivations, 1)
  }

  @MainActor
  func testLateCallbacksFromOldPlayerCannotStopNewPreview() {
    let first = FakePreviewPlayer()
    let second = FakePreviewPlayer()
    var players: [FakePreviewPlayer] = [first, second]
    var expirations: [@MainActor () -> Void] = []
    let controller = NarrationPreviewController(
      makePlayer: { _ in players.removeFirst() }, activate: {}, deactivate: {},
      schedule: { _, action in
        expirations.append(action)
        return {}
      }, notifications: NotificationCenter())
    let url = URL(fileURLWithPath: "/unused.wav")

    controller.startVerified(url: url, canPreview: true)
    let lateCompletion = first.onCompletion
    let lateFailure = first.onFailure
    controller.stop()
    controller.startVerified(url: url, canPreview: true)
    lateCompletion?()
    lateFailure?()
    expirations[0]()

    XCTAssertTrue(controller.isPlaying)
    XCTAssertFalse(second.stopped)
    controller.startVerified(url: url, canPreview: false)
    XCTAssertFalse(controller.isPlaying)
    XCTAssertTrue(second.stopped)
  }
}
