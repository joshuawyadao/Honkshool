import ActivityKit
import Foundation

/// Only timing and semantic state leave the app for the Lock Screen.
struct RestActivityAttributes: ActivityAttributes, Equatable {
  struct ContentState: Codable, Hashable {
    let countdownStart: Date
    let deadline: Date
    let playback: PlaybackStatus
    let alarm: AlarmStatus
  }

  enum PlaybackStatus: String, Codable, Hashable {
    case narrating
    case ambience
    case resting
    case paused
    case interrupted
    case stopped
  }

  enum AlarmStatus: String, Codable, Hashable {
    case none
    case scheduled
    case snoozed
    case paused
    case alerting
    case unknown
  }

  let planID: String
  let start: Date
  let deadline: Date
}
