import AVFoundation
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
