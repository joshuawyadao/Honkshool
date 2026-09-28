import AVFoundation
import AlarmKit
import XCTest

@testable import Honkshool

@MainActor
final class NapAmbiencePlayerTests: XCTestCase {
  func testShortPCMContinuesPastMultipleLoopBoundariesAndHonorsControls() async throws {
    let url = try makeShortWAV()
    defer { try? FileManager.default.removeItem(at: url) }
    let player = try NapAmbiencePlayer(url: url)
    var failure: String?
    player.onFailure = { failure = $0 }

    XCTAssertTrue(player.prepareToPlay())
    XCTAssertTrue(player.play())
    try await Task.sleep(for: .milliseconds(320))
    XCTAssertTrue(player.isPlaying, "The 100 ms file must still play after three loops")
    XCTAssertNil(failure)

    player.pause()
    XCTAssertFalse(player.isPlaying)
    XCTAssertTrue(player.play())
    XCTAssertTrue(player.isPlaying)
    player.stop()
    XCTAssertFalse(player.isPlaying)
    XCTAssertNil(failure)
  }

  private func makeShortWAV() throws -> URL {
    let sampleRate: UInt32 = 44_100
    let frameCount: UInt32 = 4_410
    let payloadBytes = frameCount * 2
    var data = Data()
    func append16(_ value: UInt16) {
      data.append(UInt8(truncatingIfNeeded: value))
      data.append(UInt8(truncatingIfNeeded: value >> 8))
    }
    func append32(_ value: UInt32) {
      append16(UInt16(truncatingIfNeeded: value))
      append16(UInt16(truncatingIfNeeded: value >> 16))
    }
    data.append(contentsOf: "RIFF".utf8)
    append32(36 + payloadBytes)
    data.append(contentsOf: "WAVEfmt ".utf8)
    append32(16)
    append16(1)  // PCM
    append16(1)  // mono
    append32(sampleRate)
    append32(sampleRate * 2)
    append16(2)  // block alignment
    append16(16)
    data.append(contentsOf: "data".utf8)
    append32(payloadBytes)
    data.append(Data(repeating: 0, count: Int(payloadBytes)))
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("NapAmbience-\(UUID().uuidString).wav")
    try data.write(to: url)
    return url
  }
}

/// Opt-in physical checks use the bundled production audio and real clocks.
/// The short plans and near-end narration seed exist only in this test target.
@MainActor
final class RealRainDeviceTests: XCTestCase {
  private func requirePhysicalOptIn() throws {
    guard ProcessInfo.processInfo.environment["HONKSHOOL_REAL_RAIN_TEST"] == "1" else {
      throw XCTSkip("Set HONKSHOOL_REAL_RAIN_TEST=1 for the physical iPhone pass.")
    }
    #if targetEnvironment(simulator)
      throw XCTSkip("A simulator cannot establish physical rain or alarm playback.")
    #endif
  }

  private func storeURL() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("RealRainDeviceTests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
    return directory.appendingPathComponent("History.store")
  }

  private func review(
    catalog: PreparedCatalog, duration: TimeInterval, selection: SessionSelection? = nil,
    alarm: Bool = false, startLead: TimeInterval = 3
  ) throws -> NapPlanReview {
    let journey = try XCTUnwrap(catalog.journeys.first)
    let sessionID = try XCTUnwrap(journey.sessionIDs.first)
    var request = NapRequest(
      window: .duration(duration),
      startingAt: selection ?? SessionSelection(journeyID: journey.id, sessionID: sessionID))
    request.fallback = .ambience(id: PreparedAmbience.gentleRainID)
    request.alarmEnabled = alarm
    let now = Date.now
    var state = NapPlanReviewState()
    try state.review(
      id: UUID().uuidString, request: request,
      startingAt: now.addingTimeInterval(startLead), now: now,
      catalog: catalog.planningCatalog,
      availableAmbienceIDs: PreparedAmbience.availableIDs())
    try state.confirm(at: Date.now)
    let confirmed = try XCTUnwrap(state.confirmed)
    XCTAssertEqual(confirmed.plan.fallback, request.fallback)
    return confirmed
  }

  private func controller(
    history: ListeningHistoryStore,
    onRain: @escaping @MainActor (NapAmbiencePlayer) -> Void,
    onNarration: @escaping @MainActor (NapRunAudioPlayer) -> Void = { _ in }
  ) -> NapRunController {
    NapRunController(
      playerFactory: { url in
        let player = try NapRunAudioPlayer(url: url)
        onNarration(player)
        return player
      },
      ambienceFactory: { url in
        let player = try NapAmbiencePlayer(url: url)
        onRain(player)
        return player
      },
      history: history)
  }

  private func waitUntil(
    within seconds: TimeInterval, file: StaticString = #filePath, line: UInt = #line,
    _ condition: @MainActor () -> Bool
  ) async throws {
    let limit = Date.now.addingTimeInterval(seconds)
    while Date.now < limit {
      if condition() { return }
      try await Task.sleep(for: .milliseconds(100))
    }
    XCTAssertTrue(condition(), "Timed out after \(seconds) seconds.", file: file, line: line)
  }

  func testRealRainLoopsPauseResumeAndStopWithoutHistory() async throws {
    try requirePhysicalOptIn()
    let catalog = try PreparedCatalog.load()
    let historyPath = try storeURL()
    let store = ListeningHistoryStore(storeURL: historyPath)
    XCTAssertNil(store.errorMessage)
    let approved = try review(catalog: catalog, duration: 45)
    XCTAssertTrue(approved.plan.route.isEmpty)
    var rain: NapAmbiencePlayer?
    let run = controller(history: store, onRain: { rain = $0 })
    defer { run.stop() }
    try run.start(review: approved, catalog: catalog)
    try await waitUntil(within: 5) { run.phase == .ambience && rain?.isPlaying == true }

    let loopDuration: TimeInterval = 9.866259
    try await Task.sleep(for: .seconds(loopDuration * 2 + 1))
    XCTAssertEqual(run.phase, .ambience)
    XCTAssertTrue(try XCTUnwrap(rain).isPlaying, "Rain must survive two natural loop boundaries.")
    XCTAssertTrue(store.entries.isEmpty)
    run.pause()
    XCTAssertEqual(run.phase, .paused)
    XCTAssertFalse(try XCTUnwrap(rain).isPlaying)
    run.resume()
    try await waitUntil(within: 2) { run.phase == .ambience && rain?.isPlaying == true }
    run.stop()
    XCTAssertEqual(run.phase, .stopped)
    XCTAssertFalse(try XCTUnwrap(rain).isPlaying)
    XCTAssertTrue(store.entries.isEmpty)
    XCTAssertTrue(ListeningHistoryStore(storeURL: historyPath).entries.isEmpty)
  }

  func testRealNarrationResumeNaturallyHandsOffToRainAndKeepsPartialHistory() async throws {
    try requirePhysicalOptIn()
    let catalog = try PreparedCatalog.load()
    let journey = try XCTUnwrap(catalog.journeys.first)
    let sessionID = try XCTUnwrap(journey.sessionIDs.first)
    let prepared = try XCTUnwrap(catalog.sessions[sessionID])
    let asset = try XCTUnwrap(prepared.narrationAsset)
    // Test-only seed: seek to eight seconds before the real George file ends.
    // Playback still has to advance and finish naturally; no callback is fabricated.
    let seedOffset = asset.duration - 8
    let seed = try ResumePoint(
      session: prepared.session, audioOffset: seedOffset,
      estimatedRemainingDuration: 8, audioAssetSHA256: asset.sha256)
    try prepared.validateAudioResumePoint(seed)
    let storePath = try storeURL()
    let firstStore = ListeningHistoryStore(storeURL: storePath)
    XCTAssertNil(firstStore.errorMessage)
    let firstSelection = SessionSelection(
      journeyID: journey.id, sessionID: sessionID, resumePoint: seed)
    let firstReview = try review(catalog: catalog, duration: 35, selection: firstSelection)
    XCTAssertEqual(firstReview.plan.route.count, 1)
    var firstNarration: NapRunAudioPlayer?
    let firstRun = controller(
      history: firstStore, onRain: { _ in },
      onNarration: {
        firstNarration = $0
      })
    defer { firstRun.stop() }
    try firstRun.start(review: firstReview, catalog: catalog)
    try await waitUntil(within: 5) { firstRun.phase == .narrating }
    try await Task.sleep(for: .seconds(3))
    if firstRun.phase == .interrupted {
      let diagnostic = XCTAttachment(
        string:
          "First narration was interrupted after three seconds. Status: \(firstRun.statusMessage); audio position: \(firstNarration?.currentTime ?? -1)."
      )
      diagnostic.name = "Real narration interruption"
      diagnostic.lifetime = .keepAlways
      add(diagnostic)
    }
    XCTAssertTrue(
      firstRun.phase == .narrating || firstRun.phase == .interrupted,
      "Unexpected phase after real narration advanced: \(firstRun.phase), \(firstRun.statusMessage)"
    )
    XCTAssertGreaterThan(try XCTUnwrap(firstNarration).currentTime, seedOffset + 2)
    firstRun.stop()
    XCTAssertEqual(firstRun.phase, .stopped)
    XCTAssertNil(firstStore.errorMessage)
    let partial = try XCTUnwrap(firstStore.entries.first?.record)
    XCTAssertFalse(partial.isCompleted)
    XCTAssertGreaterThan(try XCTUnwrap(partial.resumePoint?.audioOffset), seedOffset + 2)

    let reopened = ListeningHistoryStore(storeURL: storePath)
    XCTAssertNil(reopened.errorMessage)
    XCTAssertEqual(reopened.entries.count, 1)
    let savedSelection = try XCTUnwrap(reopened.history.resumeSelection(for: partial.id))
    let savedPoint = try XCTUnwrap(savedSelection.resumePoint)
    XCTAssertEqual(savedPoint, partial.resumePoint)
    let secondReview = try review(catalog: catalog, duration: 35, selection: savedSelection)
    XCTAssertEqual(secondReview.plan.route.count, 1)
    var rain: NapAmbiencePlayer?
    var secondNarration: NapRunAudioPlayer?
    let secondRun = controller(
      history: reopened, onRain: { rain = $0 },
      onNarration: { secondNarration = $0 })
    defer { secondRun.stop() }
    try secondRun.start(review: secondReview, catalog: catalog)
    try await waitUntil(within: 5) { secondRun.phase == .narrating }
    try await waitUntil(within: 12) {
      secondRun.phase == .ambience && rain?.isPlaying == true
    }
    let storedSecondRun = reopened.entries.filter { $0.record.planID == secondReview.plan.id }
      .map { entry in
        "\(entry.record.isCompleted ? "completed" : "partial") played=\(entry.record.playedDuration) checkpoint=\(entry.isCheckpoint)"
      }
    let handoff = XCTAttachment(
      string:
        "Narration position after handoff: \(secondNarration?.currentTime ?? -1); duration: \(secondNarration?.duration ?? -1); completed record played: \(secondRun.records.first?.playedDuration ?? -1); stored rows: \(storedSecondRun)."
    )
    handoff.name = "Real narration to rain handoff"
    handoff.lifetime = .keepAlways
    add(handoff)
    XCTAssertEqual(secondRun.records.count, 1)
    XCTAssertTrue(try XCTUnwrap(secondRun.records.first).isCompleted)
    let handedOffAt = Date.now
    try await Task.sleep(for: .seconds(21))
    XCTAssertGreaterThan(Date.now.timeIntervalSince(handedOffAt), 19.7)
    XCTAssertEqual(secondRun.phase, .ambience)
    XCTAssertTrue(try XCTUnwrap(rain).isPlaying)
    secondRun.stop()
    XCTAssertNil(reopened.errorMessage)
    let final = ListeningHistoryStore(storeURL: storePath)
    XCTAssertNil(final.errorMessage)
    XCTAssertEqual(final.entries.count, 2)
    XCTAssertEqual(final.entries.filter { $0.record.isCompleted }.count, 1)
    XCTAssertEqual(final.entries.filter { !$0.record.isCompleted }.count, 1)
    XCTAssertEqual(final.entries.first { $0.id == partial.id }?.record, partial)
  }

  func testRealRainStopsAtAuthorizedAlarmDeadline() async throws {
    try requirePhysicalOptIn()
    let system = AppleAlarmSystem(source: "real-rain-device-test")
    guard system.authorization == .authorized else {
      throw XCTSkip("Authorize Honkshool alarms before the physical-device test.")
    }
    let catalog = try PreparedCatalog.load()
    let approved = try review(catalog: catalog, duration: 35, alarm: true, startLead: 20)
    XCTAssertTrue(approved.plan.route.isEmpty)
    let suiteName = "RealRainDeviceTests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let service = NapPlanAlarmService(system: system, defaults: defaults)
    let store = ListeningHistoryStore(storeURL: try storeURL())
    XCTAssertNil(store.errorMessage)
    let waitingRun = controller(history: store, onRain: { _ in })
    defer { waitingRun.stop() }
    var rain: NapAmbiencePlayer?
    let run = controller(history: store, onRain: { rain = $0 })
    var ownAlarmID: UUID?
    defer {
      run.stop()
      // Scheduling may persist an identity and then return an uncertain nil result.
      // Recover that exact test-owned UUID before clearing the isolated defaults.
      let persistedID = defaults.data(forKey: "napPlanAlarmReceipt").flatMap {
        try? JSONDecoder().decode(ScheduledNapAlarm.self, from: $0).id
      }
      if let alarmID = ownAlarmID ?? persistedID {
        if !service.cancel() {
          try? system.cancel(id: alarmID)
          if (try? system.alarms().contains(where: { $0.id == alarmID })) ?? true {
            try? AlarmManager.shared.stop(id: alarmID)
          }
        }
        if (try? system.alarms().contains(where: { $0.id == alarmID })) ?? true {
          XCTFail("The isolated rain-test alarm could not be cleaned up.")
        }
      }
    }
    try run.preflight(review: approved, catalog: catalog)
    let scheduled = await service.schedule(for: approved.plan)
    let receipt = try XCTUnwrap(scheduled, service.statusMessage)
    ownAlarmID = receipt.id
    XCTAssertTrue(service.isScheduled(receipt))
    try waitingRun.start(review: approved, catalog: catalog, scheduledAlarm: receipt)
    XCTAssertEqual(waitingRun.phase, .waiting)
    waitingRun.stop()
    XCTAssertEqual(waitingRun.phase, .stopped)
    XCTAssertTrue(service.isScheduled(receipt), "Stopping playback must preserve the system alarm.")
    XCTAssertTrue(store.entries.isEmpty)
    try run.start(review: approved, catalog: catalog, scheduledAlarm: receipt)
    try await waitUntil(within: 25) { run.phase == .ambience && rain?.isPlaying == true }
    let reloadedService = NapPlanAlarmService(system: system, defaults: defaults)
    XCTAssertTrue(reloadedService.hasTrackedAlarm)
    XCTAssertTrue(reloadedService.isScheduled(receipt), "Playback must not take alarm ownership.")

    var alertObservedAt: Date?
    var cutoffObservedAt: Date?
    while Date.now < approved.plan.deadline.addingTimeInterval(7) {
      let observedAt = Date.now
      if cutoffObservedAt == nil && run.phase == .finished && rain?.isPlaying == false {
        cutoffObservedAt = observedAt
      }
      if alertObservedAt == nil,
        let systemAlarm = try? system.alarms().first(where: { $0.id == receipt.id }),
        systemAlarm.state == .alerting
      {
        alertObservedAt = observedAt
      }
      if alertObservedAt != nil && cutoffObservedAt != nil { break }
      try await Task.sleep(for: .milliseconds(100))
    }
    let alert = try XCTUnwrap(alertObservedAt, "The real system alarm never alerted.")
    let cutoff = try XCTUnwrap(cutoffObservedAt, "The rain missed its fixed deadline.")
    let timing = XCTAttachment(
      string: String(
        format: "Alarm alert %+0.3f s; rain cutoff %+0.3f s from fixed deadline.",
        alert.timeIntervalSince(approved.plan.deadline),
        cutoff.timeIntervalSince(approved.plan.deadline)))
    timing.name = "Real rain alarm timing"
    timing.lifetime = .keepAlways
    add(timing)
    XCTAssertLessThanOrEqual(abs(alert.timeIntervalSince(approved.plan.deadline)), 5)
    XCTAssertLessThanOrEqual(abs(cutoff.timeIntervalSince(approved.plan.deadline)), 3)
    XCTAssertEqual(run.phase, .finished)
    XCTAssertFalse(try XCTUnwrap(rain).isPlaying)
    XCTAssertTrue(store.entries.isEmpty)
    XCTAssertNil(store.errorMessage)
  }
}
