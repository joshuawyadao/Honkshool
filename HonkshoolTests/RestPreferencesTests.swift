import Foundation
import XCTest

@testable import Honkshool

final class RestPreferencesTests: XCTestCase {
  @MainActor
  func testDefaultsAndExplicitPersistence() throws {
    let defaults = try makeDefaults()
    defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }

    XCTAssertEqual(RestPreferences.load(defaults: defaults), .initial)
    RestPreferences.save(
      RestDefaults(
        durationMinutes: 48, soundID: PreparedAmbience.gentleRainID, wakeAlarm: false),
      defaults: defaults)
    XCTAssertEqual(
      RestPreferences.load(defaults: defaults),
      RestDefaults(
        durationMinutes: 48, soundID: PreparedAmbience.gentleRainID, wakeAlarm: false))
    XCTAssertEqual(defaults.integer(forKey: "restDefaultDurationMinutes"), 48)

    RestPreferences.reset(defaults: defaults)
    XCTAssertEqual(RestPreferences.load(defaults: defaults), .initial)
  }

  @MainActor
  func testInvalidStoredValuesAreConstrained() throws {
    let defaults = try makeDefaults()
    defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }

    defaults.set(999, forKey: "restDefaultDurationMinutes")
    defaults.set("not-a-prepared-sound", forKey: "defaultRestSoundID")
    defaults.set("not-a-boolean", forKey: "defaultRestWakeAlarm")
    XCTAssertEqual(
      RestPreferences.load(defaults: defaults),
      RestDefaults(
        durationMinutes: 180, soundID: nil, wakeAlarm: true))

    defaults.set(-7, forKey: "restDefaultDurationMinutes")
    XCTAssertEqual(RestPreferences.load(defaults: defaults).durationMinutes, 1)
    defaults.set(2, forKey: "defaultRestWakeAlarm")
    XCTAssertTrue(RestPreferences.load(defaults: defaults).wakeAlarm)
    RestPreferences.save(
      RestDefaults(durationMinutes: 0, soundID: "unknown", wakeAlarm: false),
      defaults: defaults)
    XCTAssertEqual(
      RestPreferences.load(defaults: defaults),
      RestDefaults(
        durationMinutes: 1, soundID: nil, wakeAlarm: false))
  }

  @MainActor
  func testEffectiveSoundUsesAvailabilityWithoutErasingSavedPreference() throws {
    let defaults = try makeDefaults()
    defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }
    defaults.set(PreparedAmbience.gentleRainID, forKey: "defaultRestSoundID")

    XCTAssertNil(RestPreferences.load(defaults: defaults, availableAmbienceIDs: []).soundID)
    XCTAssertEqual(defaults.string(forKey: "defaultRestSoundID"), PreparedAmbience.gentleRainID)
    XCTAssertEqual(
      RestPreferences.load(
        defaults: defaults, availableAmbienceIDs: [PreparedAmbience.gentleRainID]
      ).soundID,
      PreparedAmbience.gentleRainID)

    defaults.set("unknown-legacy-sound", forKey: "defaultRestSoundID")
    XCTAssertNil(
      RestPreferences.load(
        defaults: defaults, availableAmbienceIDs: ["unknown-legacy-sound"]
      ).soundID)
  }

  @MainActor
  func testLabDurationRemainsIndependentOfRestDefaults() throws {
    let defaults = try makeDefaults()
    defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }
    defaults.set(35, forKey: "preferredRestMinutes")

    XCTAssertEqual(RestPreferences.load(defaults: defaults).durationMinutes, 20)
    RestPreferences.save(
      RestDefaults(durationMinutes: 45, soundID: nil, wakeAlarm: true),
      defaults: defaults)
    XCTAssertEqual(defaults.integer(forKey: "preferredRestMinutes"), 35)
    XCTAssertEqual(RestPreferences.load(defaults: defaults).durationMinutes, 45)

    RestPreferences.reset(defaults: defaults)
    XCTAssertEqual(defaults.integer(forKey: "preferredRestMinutes"), 35)
    XCTAssertEqual(RestPreferences.load(defaults: defaults).durationMinutes, 20)
  }

  private let defaultsSuiteName = "Honkshool.RestPreferencesTests.\(UUID().uuidString)"

  private func makeDefaults() throws -> UserDefaults {
    let defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsSuiteName))
    defaults.removePersistentDomain(forName: defaultsSuiteName)
    return defaults
  }
}
