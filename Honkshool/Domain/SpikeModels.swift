import Foundation

enum AlarmAuthorizationSnapshot: Equatable, Sendable {
  case notDetermined
  case denied
  case authorized
}

enum AlarmScheduleSnapshot: Equatable, Sendable {
  case notScheduled
  case scheduled(Date)
  case failed
}

enum FeasibilityRunReadiness: Equatable, Sendable {
  case ready
  case blocked(String)
}

enum FeasibilityRunGate {
  static func evaluate(
    alarmEnabled: Bool,
    authorization: AlarmAuthorizationSnapshot,
    schedule: AlarmScheduleSnapshot,
    now: Date
  ) -> FeasibilityRunReadiness {
    guard alarmEnabled else {
      return .ready
    }

    guard authorization == .authorized else {
      return .blocked(
        "Alarm-enabled runs require AlarmKit authorization before playback starts."
      )
    }

    guard case .scheduled(let date) = schedule, date > now else {
      return .blocked(
        "Alarm-enabled runs require a successfully scheduled future alarm."
      )
    }

    return .ready
  }
}

enum PlaybackPhase: String, Equatable, Sendable {
  case idle
  case narrating
  case paused
  case ambience
  case stopped
  case interrupted
  case failed
}

enum PlaybackDestination: Equatable, Sendable {
  case ambience
  case silence
}

enum PlaybackTransitionPolicy {
  static func destinationAfterNarration(
    ambienceEnabled: Bool
  ) -> PlaybackDestination {
    ambienceEnabled ? .ambience : .silence
  }
}

enum InterruptionEvent: Equatable, Sendable {
  case began
  case ended(systemSuggestsResume: Bool)
  case outputRouteDisconnected
}

enum InterruptionAction: Equatable, Sendable {
  case pause
  case waitForManualResume
}

enum SpikeInterruptionPolicy {
  static func action(for event: InterruptionEvent) -> InterruptionAction {
    switch event {
    case .began, .outputRouteDisconnected:
      return .pause
    case .ended:
      // The spike records whether iOS suggests resumption, but deliberately
      // waits for a person to resume until device evidence supports a policy.
      return .waitForManualResume
    }
  }
}

enum RestDurationPolicy {
  static let recommendedMinutes = [20, 30, 45, 60]
  static let initialSavedMinutes = 35
  static let allowedMinutes = 5...180

  static func normalized(minutes: Int) -> Int {
    min(max(minutes, allowedMinutes.lowerBound), allowedMinutes.upperBound)
  }

  static func wakeDate(startingAt startDate: Date, minutes: Int) -> Date {
    startDate.addingTimeInterval(TimeInterval(normalized(minutes: minutes) * 60))
  }
}
