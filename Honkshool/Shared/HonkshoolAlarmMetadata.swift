import AlarmKit
import AppIntents

struct HonkshoolAlarmMetadata: AlarmMetadata {
  static let snoozeSeconds: Double = 9 * 60
  let source: String
}

struct CancelHonkshoolAlarmIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Cancel Honkshool alarm"

  @Parameter(title: "Alarm ID")
  var alarmID: String

  init() {}

  init(alarmID: String) {
    self.alarmID = alarmID
  }

  func perform() async throws -> some IntentResult {
    if let id = UUID(uuidString: alarmID) {
      try AlarmManager.shared.cancel(id: id)
    }
    return .result()
  }
}
