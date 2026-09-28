import Foundation
import XCTest

@testable import Honkshool

final class PreparedAmbienceTests: XCTestCase {
  func testAcceptedBundledRainIsAvailableByStableIdentity() throws {
    let url = try PreparedAmbience.resolve(id: PreparedAmbience.gentleRainID)

    XCTAssertEqual(url.lastPathComponent, "GentleRain.wav")
    XCTAssertEqual(PreparedAmbience.availableIDs(), [PreparedAmbience.gentleRainID])
    XCTAssertEqual(PreparedAmbience.displayName(for: PreparedAmbience.gentleRainID), "Gentle rain")
  }

  func testUnknownSoundAndMissingBundleAreUnavailable() {
    XCTAssertThrowsError(try PreparedAmbience.resolve(id: "other-sound")) {
      XCTAssertEqual($0 as? PreparedAmbienceError, .unknownID("other-sound"))
    }
    let emptyBundle = Bundle(for: Self.self)
    XCTAssertTrue(PreparedAmbience.availableIDs(bundle: emptyBundle).isEmpty)
    XCTAssertThrowsError(
      try PreparedAmbience.resolve(id: PreparedAmbience.gentleRainID, bundle: emptyBundle)
    ) {
      XCTAssertEqual(
        $0 as? PreparedAmbienceError,
        .missingResource(PreparedAmbience.gentleRainID))
    }
  }

  func testChangedAudioCannotBeSelectedEvenWithAcceptedProvenance() throws {
    let fixture = try makeBundle()
    defer { try? FileManager.default.removeItem(at: fixture.url) }
    try Data(repeating: 0, count: 128).write(to: fixture.rain)

    XCTAssertTrue(PreparedAmbience.availableIDs(bundle: fixture.bundle).isEmpty)
    XCTAssertThrowsError(
      try PreparedAmbience.resolve(id: PreparedAmbience.gentleRainID, bundle: fixture.bundle)
    ) {
      XCTAssertEqual($0 as? PreparedAmbienceError, .invalidAudio)
    }
  }

  func testProvenanceMustRecordTheAcceptedCandidate() throws {
    let fixture = try makeBundle()
    defer { try? FileManager.default.removeItem(at: fixture.url) }
    let altered = try Data(contentsOf: fixture.provenance)
      .replacingOccurrences(
        of: "accepted-for-playback", with: "prepared-candidate-awaiting-listening")
    try altered.write(to: fixture.provenance)

    XCTAssertTrue(PreparedAmbience.availableIDs(bundle: fixture.bundle).isEmpty)
    XCTAssertThrowsError(
      try PreparedAmbience.resolve(id: PreparedAmbience.gentleRainID, bundle: fixture.bundle)
    ) {
      XCTAssertEqual($0 as? PreparedAmbienceError, .invalidProvenance)
    }
  }

  private func makeBundle() throws -> (
    url: URL, bundle: Bundle, rain: URL, provenance: URL
  ) {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("RainFixture-\(UUID().uuidString).bundle", isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    let rain = url.appendingPathComponent("GentleRain.wav")
    let provenance = url.appendingPathComponent("GentleRain-Provenance.json")
    try FileManager.default.copyItem(
      at: PreparedAmbience.resolve(id: PreparedAmbience.gentleRainID), to: rain)
    let source = try XCTUnwrap(
      Bundle.main.url(
        forResource: "GentleRain-Provenance", withExtension: "json"))
    try FileManager.default.copyItem(at: source, to: provenance)
    let bundle = try XCTUnwrap(Bundle(url: url))
    return (url, bundle, rain, provenance)
  }
}

extension Data {
  fileprivate func replacingOccurrences(of source: String, with replacement: String) throws -> Data
  {
    let text = try XCTUnwrap(String(data: self, encoding: .utf8))
    return Data(text.replacingOccurrences(of: source, with: replacement).utf8)
  }
}
