import AVFoundation
import Combine
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
      isForeground: { true },
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
      isForeground: { true },
      makePlayer: { _ in player }, activate: {},
      deactivate: { deactivations += 1 }, notifications: NotificationCenter())
    controller.startVerified(url: URL(fileURLWithPath: "/unused.wav"), canPreview: true)
    player.onCompletion?()
    XCTAssertEqual(controller.status, "Preview finished.")
    XCTAssertEqual(deactivations, 1)
    XCTAssertFalse(controller.isPlaying)
  }

  @MainActor
  func testVerifiedBundledFirstSessionCanStartWithoutSystemAudio() async throws {
    let catalog = try PreparedCatalog.load()
    let player = FakePreviewPlayer()
    let controller = NarrationPreviewController(
      isForeground: { true },
      makePlayer: { _ in player }, activate: {}, deactivate: {},
      notifications: NotificationCenter())
    let playing = expectation(description: "Verified preview started")
    let observation = controller.$isPlaying.sink { if $0 { playing.fulfill() } }

    controller.start(catalog: catalog, canPreview: true)
    XCTAssertTrue(controller.isPreparing)
    XCTAssertFalse(controller.isPlaying)
    await fulfillment(of: [playing], timeout: 5)
    XCTAssertTrue(player.played)
    XCTAssertFalse(controller.isPreparing)
    controller.stop()
    withExtendedLifetime(observation) {}
  }

  @MainActor
  func testInjectedVerificationRunsOffMainActor() async throws {
    let catalog = try PreparedCatalog.load()
    let player = FakePreviewPlayer()
    let playing = expectation(description: "Off-main verification started playback")
    let controller = NarrationPreviewController(
      verify: { _ in
        Thread.isMainThread ? .unavailable : .verified(URL(fileURLWithPath: "/verified.wav"))
      },
      isForeground: { true }, makePlayer: { _ in player },
      activate: {}, deactivate: {}, notifications: NotificationCenter())
    let observation = controller.$isPlaying.sink { if $0 { playing.fulfill() } }

    controller.start(catalog: catalog, canPreview: true)
    await fulfillment(of: [playing], timeout: 5)
    XCTAssertTrue(player.played)
    controller.stop()
    withExtendedLifetime(observation) {}
  }

  @MainActor
  func testFailedVerificationNeverActivatesAudio() async throws {
    let catalog = try PreparedCatalog.load()
    let results: [NarrationPreviewVerification] = [.unavailable, .mismatch]
    for result in results {
      var activations = 0
      var deactivations = 0
      let controller = NarrationPreviewController(
        verify: { _ in result }, isForeground: { true },
        makePlayer: { _ in
          XCTFail("Player must not be created")
          return FakePreviewPlayer()
        },
        activate: { activations += 1 }, deactivate: { deactivations += 1 },
        notifications: NotificationCenter())
      let expected =
        switch result {
        case .unavailable: "George’s bundled recording is unavailable."
        case .mismatch: "George’s bundled recording could not be verified."
        case .verified: ""
        }
      let settled = expectation(description: "Verification failure published")
      let observation = controller.$status.sink { if $0 == expected { settled.fulfill() } }

      controller.start(catalog: catalog, canPreview: true)
      await fulfillment(of: [settled], timeout: 5)
      XCTAssertFalse(controller.isPreparing)
      XCTAssertFalse(controller.isPlaying)
      XCTAssertEqual(activations, 0)
      XCTAssertEqual(deactivations, 0)
      withExtendedLifetime(observation) {}
    }
  }

  @MainActor
  func testStoppedPreparationCannotReplaceNewPreview() async throws {
    let catalog = try PreparedCatalog.load()
    let started = expectation(description: "Old verification started")
    let finished = expectation(description: "Old verification finished")
    let gate = HeldVerification(started: started, finished: finished)
    defer { gate.release.signal() }
    let newPlayer = FakePreviewPlayer()
    var openedURLs: [URL] = []
    var activations = 0
    let controller = NarrationPreviewController(
      verify: { _ in gate.run() }, isForeground: { true },
      makePlayer: { url in
        openedURLs.append(url)
        return newPlayer
      },
      activate: { activations += 1 }, deactivate: {}, notifications: NotificationCenter())
    let playing = expectation(description: "New preview started")
    let observation = controller.$isPlaying.sink { if $0 { playing.fulfill() } }

    controller.start(catalog: catalog, canPreview: true)
    await fulfillment(of: [started], timeout: 5)
    controller.stop()
    controller.start(catalog: catalog, canPreview: true)
    await fulfillment(of: [playing], timeout: 5)
    gate.release.signal()
    await fulfillment(of: [finished], timeout: 5)
    await Task.yield()

    XCTAssertEqual(openedURLs, [URL(fileURLWithPath: "/new.wav")])
    XCTAssertEqual(activations, 1)
    XCTAssertTrue(controller.isPlaying)
    XCTAssertEqual(controller.status, "Playing a 12-second George preview.")
    controller.stop()
    withExtendedLifetime(observation) {}
  }

  @MainActor
  func testBackgroundCancelsPreparationBeforeVerifiedStart() async throws {
    let catalog = try PreparedCatalog.load()
    let center = NotificationCenter()
    let started = expectation(description: "Verification started")
    let finished = expectation(description: "Verification finished")
    let gate = HeldVerification(started: started, finished: finished)
    defer { gate.release.signal() }
    var activations = 0
    let controller = NarrationPreviewController(
      verify: { _ in gate.run() }, isForeground: { true },
      makePlayer: { _ in FakePreviewPlayer() },
      activate: { activations += 1 }, deactivate: {}, notifications: center)

    controller.start(catalog: catalog, canPreview: true)
    await fulfillment(of: [started], timeout: 5)
    center.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
    XCTAssertFalse(controller.isPreparing)
    gate.release.signal()
    await fulfillment(of: [finished], timeout: 5)
    await Task.yield()
    XCTAssertEqual(activations, 0)
    XCTAssertFalse(controller.isPlaying)
  }

  @MainActor
  func testEligibilityLossCancelsPreparationBeforeVerifiedStart() async throws {
    let catalog = try PreparedCatalog.load()
    let started = expectation(description: "Verification started")
    let finished = expectation(description: "Verification finished")
    let gate = HeldVerification(started: started, finished: finished)
    defer { gate.release.signal() }
    var activations = 0
    let controller = NarrationPreviewController(
      verify: { _ in gate.run() }, isForeground: { true },
      makePlayer: { _ in FakePreviewPlayer() },
      activate: { activations += 1 }, deactivate: {}, notifications: NotificationCenter())

    controller.start(catalog: catalog, canPreview: true)
    await fulfillment(of: [started], timeout: 5)
    controller.start(catalog: catalog, canPreview: false)
    XCTAssertFalse(controller.isPreparing)
    gate.release.signal()
    await fulfillment(of: [finished], timeout: 5)
    await Task.yield()
    XCTAssertEqual(activations, 0)
    XCTAssertFalse(controller.isPlaying)
  }

  @MainActor
  func testForegroundGateRejectsCompletedVerification() async throws {
    let catalog = try PreparedCatalog.load()
    let started = expectation(description: "Verification started")
    let finished = expectation(description: "Verification finished")
    let gate = HeldVerification(started: started, finished: finished)
    defer { gate.release.signal() }
    var foreground = true
    var activations = 0
    let controller = NarrationPreviewController(
      verify: { _ in gate.run() }, isForeground: { foreground },
      makePlayer: { _ in FakePreviewPlayer() },
      activate: { activations += 1 }, deactivate: {}, notifications: NotificationCenter())

    controller.start(catalog: catalog, canPreview: true)
    await fulfillment(of: [started], timeout: 5)
    foreground = false
    gate.release.signal()
    await fulfillment(of: [finished], timeout: 5)
    await Task.yield()
    XCTAssertEqual(activations, 0)
    XCTAssertFalse(controller.isPlaying)
  }

  @MainActor
  func testRouteLossStopsPreview() async {
    let center = NotificationCenter()
    let player = FakePreviewPlayer()
    var deactivations = 0
    let controller = NarrationPreviewController(
      isForeground: { true },
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
      isForeground: { true },
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

private final class HeldVerification: @unchecked Sendable {
  let started: XCTestExpectation
  let finished: XCTestExpectation
  let release = DispatchSemaphore(value: 0)
  private let lock = NSLock()
  private var calls = 0

  init(started: XCTestExpectation, finished: XCTestExpectation) {
    self.started = started
    self.finished = finished
  }

  func run() -> NarrationPreviewVerification {
    lock.lock()
    calls += 1
    let call = calls
    lock.unlock()
    if call == 1 {
      started.fulfill()
      release.wait()
      finished.fulfill()
      return .verified(URL(fileURLWithPath: "/old.wav"))
    }
    return .verified(URL(fileURLWithPath: "/new.wav"))
  }
}
