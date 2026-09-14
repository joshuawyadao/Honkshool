#if DEBUG
  import AVFoundation
  import AlarmKit
  import Foundation

  @MainActor
  enum UITestFixtures {
    static let launchArgument = "-ui-testing"
    static let alarmScenarioEnvironmentKey = "HONKSHOOL_UI_TEST_ALARM"
    static let deterministicAudioEnvironmentKey = "HONKSHOOL_UI_TEST_AUDIO"
    static let resetEnvironmentKey = "HONKSHOOL_UI_TEST_RESET"

    private static let alarmID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private static let storedAlarmIDKey = "feasibilityAlarmID"
    private static let storedAlarmDateKey = "feasibilityAlarmDate"

    static var isEnabled: Bool {
      ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    static func preparePersistentState(defaults: UserDefaults = .standard) {
      guard isEnabled else { return }
      if ProcessInfo.processInfo.environment[resetEnvironmentKey] == "1" {
        defaults.removeObject(forKey: storedAlarmIDKey)
        defaults.removeObject(forKey: storedAlarmDateKey)
        defaults.set(RestDurationPolicy.initialSavedMinutes, forKey: "preferredRestMinutes")
      }

      guard scenario?.startsWithTrackedAlarm == true else { return }
      defaults.set(alarmID.uuidString, forKey: storedAlarmIDKey)
      defaults.set(Date.now.timeIntervalSince1970, forKey: storedAlarmDateKey)
    }

    static func makeAlarmSystem() -> (any AlarmSystem)? {
      guard isEnabled, let scenario else { return nil }
      return UITestAlarmSystem(scenario: scenario, alarmID: alarmID)
    }

    static func makeSpeechSynthesizer() -> AVSpeechSynthesizer? {
      guard isEnabled,
        ProcessInfo.processInfo.environment[deterministicAudioEnvironmentKey] == "1"
      else { return nil }
      return UITestSpeechSynthesizer()
    }

    private static var scenario: UITestAlarmScenario? {
      guard let rawValue = ProcessInfo.processInfo.environment[alarmScenarioEnvironmentKey]
      else { return nil }
      return UITestAlarmScenario(rawValue: rawValue)
    }
  }

  private enum UITestAlarmScenario: String {
    case notDetermined = "not-determined"
    case denied
    case authorized
    case scheduleFailure = "schedule-failure"
    case snoozed
    case paused
    case alerting
    case readFailure = "read-failure"

    var authorization: AlarmAuthorizationSnapshot {
      switch self {
      case .notDetermined: .notDetermined
      case .denied: .denied
      default: .authorized
      }
    }

    var startsWithTrackedAlarm: Bool {
      switch self {
      case .snoozed, .paused, .alerting, .readFailure: true
      default: false
      }
    }
  }

  @MainActor
  private final class UITestAlarmSystem: AlarmSystem {
    private let scenario: UITestAlarmScenario
    private let initialAlarmID: UUID
    private var records: [SystemAlarmRecord]
    private var continuation: AsyncStream<Void>.Continuation?
    private(set) var authorization: AlarmAuthorizationSnapshot

    init(scenario: UITestAlarmScenario, alarmID: UUID) {
      self.scenario = scenario
      initialAlarmID = alarmID
      authorization = scenario.authorization
      let originalDate = Date.now.addingTimeInterval(60)
      switch scenario {
      case .snoozed:
        records = [
          SystemAlarmRecord(
            id: alarmID,
            state: .countdown,
            originalDate: originalDate,
            countdownFireDate: Date.now.addingTimeInterval(
              HonkshoolAlarmMetadata.snoozeSeconds
            )
          )
        ]
      case .paused:
        records = [
          SystemAlarmRecord(
            id: alarmID, state: .paused, originalDate: originalDate,
            countdownFireDate: nil
          )
        ]
      case .alerting:
        records = [
          SystemAlarmRecord(
            id: alarmID, state: .alerting, originalDate: originalDate,
            countdownFireDate: nil
          )
        ]
      default:
        records = []
      }
    }

    func requestAuthorization() async throws -> AlarmAuthorizationSnapshot {
      if scenario == .notDetermined { authorization = .authorized }
      continuation?.yield(())
      return authorization
    }

    func alarms() throws -> [SystemAlarmRecord] {
      if scenario == .readFailure { throw UITestFixtureError.requestedFailure }
      return records
    }

    func schedule(id: UUID, at date: Date) async throws {
      if scenario == .scheduleFailure { throw UITestFixtureError.requestedFailure }
      records = [
        SystemAlarmRecord(
          id: id, state: .scheduled, originalDate: date, countdownFireDate: nil
        )
      ]
      continuation?.yield(())
    }

    func cancel(id: UUID) throws {
      records.removeAll { $0.id == id || $0.id == initialAlarmID }
      continuation?.yield(())
    }

    func updates() -> AsyncStream<Void> {
      AsyncStream { continuation in
        self.continuation = continuation
        continuation.onTermination = { [weak self] _ in
          Task { @MainActor in self?.continuation = nil }
        }
      }
    }
  }

  private enum UITestFixtureError: Error {
    case requestedFailure
  }

  private final class UITestSpeechSynthesizer: AVSpeechSynthesizer {
    private var testSpeaking = false
    private var testPaused = false

    override var isSpeaking: Bool { testSpeaking }
    override var isPaused: Bool { testPaused }

    override func speak(_ utterance: AVSpeechUtterance) {
      testSpeaking = true
      testPaused = false
    }

    override func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool {
      testSpeaking = false
      testPaused = false
      return true
    }

    override func pauseSpeaking(at boundary: AVSpeechBoundary) -> Bool {
      guard testSpeaking else { return false }
      testPaused = true
      return true
    }

    override func continueSpeaking() -> Bool {
      guard testPaused else { return false }
      testPaused = false
      testSpeaking = true
      return true
    }
  }
#endif
