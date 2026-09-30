import CoreFoundation
import Foundation

struct RestDefaults: Equatable {
  var durationMinutes: Int
  var soundID: String?
  var wakeAlarm: Bool

  static let initial = RestDefaults(durationMinutes: 20, soundID: nil, wakeAlarm: true)
}

@MainActor
enum RestPreferences {
  private static let durationKey = "restDefaultDurationMinutes"
  private static let soundKey = "defaultRestSoundID"
  private static let alarmKey = "defaultRestWakeAlarm"

  static func load(defaults: UserDefaults? = nil) -> RestDefaults {
    let defaults = defaults ?? SpikePreferences.defaults
    let duration: Int
    if let number = defaults.object(forKey: durationKey) as? NSNumber,
      CFGetTypeID(number) != CFBooleanGetTypeID()
    {
      duration = min(max(number.intValue, 1), 180)
    } else {
      duration = RestDefaults.initial.durationMinutes
    }
    let sound = defaults.string(forKey: soundKey)
    let alarm: Bool
    if let number = defaults.object(forKey: alarmKey) as? NSNumber,
      CFGetTypeID(number) == CFBooleanGetTypeID()
    {
      alarm = number.boolValue
    } else {
      alarm = RestDefaults.initial.wakeAlarm
    }
    return RestDefaults(
      durationMinutes: duration,
      soundID: sound == PreparedAmbience.gentleRainID ? sound : nil,
      wakeAlarm: alarm)
  }

  static func save(_ value: RestDefaults, defaults: UserDefaults? = nil) {
    let defaults = defaults ?? SpikePreferences.defaults
    defaults.set(min(max(value.durationMinutes, 1), 180), forKey: durationKey)
    if value.soundID == PreparedAmbience.gentleRainID {
      defaults.set(PreparedAmbience.gentleRainID, forKey: soundKey)
    } else {
      defaults.removeObject(forKey: soundKey)
    }
    defaults.set(value.wakeAlarm, forKey: alarmKey)
  }

  static func reset(defaults: UserDefaults? = nil) {
    let defaults = defaults ?? SpikePreferences.defaults
    defaults.removeObject(forKey: durationKey)
    defaults.removeObject(forKey: soundKey)
    defaults.removeObject(forKey: alarmKey)
  }
}
