import Foundation

/// IDs are supplied by the catalog and remain stable when titles or estimates change.
struct Session: Equatable, Sendable {
  typealias ID = String

  let id: ID
  let revision: String
  let title: String
  let estimatedDuration: TimeInterval

  init(id: ID, revision: String, title: String, estimatedDuration: TimeInterval) throws {
    guard !id.isEmpty, !revision.isEmpty else { throw NapDomainError.invalidIdentity }
    guard estimatedDuration.isFinite, estimatedDuration > 0 else {
      throw NapDomainError.invalidDuration
    }
    self.id = id
    self.revision = revision
    self.title = title
    self.estimatedDuration = estimatedDuration
  }
}

struct Journey: Equatable, Sendable {
  typealias ID = String

  let id: ID
  let title: String
  let sessionIDs: [Session.ID]
  let nextJourneyIDs: [ID]

  init(id: ID, title: String, sessionIDs: [Session.ID], nextJourneyIDs: [ID] = []) throws {
    guard !id.isEmpty, (sessionIDs + nextJourneyIDs).allSatisfy({ !$0.isEmpty }) else {
      throw NapDomainError.invalidIdentity
    }
    guard Set(sessionIDs).count == sessionIDs.count,
      Set(nextJourneyIDs).count == nextJourneyIDs.count
    else { throw NapDomainError.duplicateIdentity }
    self.id = id
    self.title = title
    self.sessionIDs = sessionIDs
    self.nextJourneyIDs = nextJourneyIDs
  }
}

/// Missing referenced content is allowed: a partially prepared catalog must fall back safely.
struct NapCatalog: Equatable, Sendable {
  let journeys: [Journey.ID: Journey]
  let sessions: [Session.ID: Session]

  init(journeys: [Journey], sessions: [Session]) throws {
    guard Set(journeys.map(\.id)).count == journeys.count,
      Set(sessions.map(\.id)).count == sessions.count
    else { throw NapDomainError.duplicateIdentity }
    self.journeys = Dictionary(uniqueKeysWithValues: journeys.map { ($0.id, $0) })
    self.sessions = Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0) })
  }
}

/// A revision-bound position in either a script or prepared audio. Callers must never
/// derive one kind of position from the other.
struct ResumePoint: Equatable, Sendable {
  private enum Position: Equatable, Sendable {
    case script(utf16Offset: Int)
    case audio(seconds: TimeInterval)
  }

  let sessionID: Session.ID
  let revision: String
  private let position: Position
  let estimatedRemainingDuration: TimeInterval

  var utf16Offset: Int? {
    if case .script(let offset) = position { return offset }
    return nil
  }

  var audioOffset: TimeInterval? {
    if case .audio(let seconds) = position { return seconds }
    return nil
  }

  init(session: Session, utf16Offset: Int, estimatedRemainingDuration: TimeInterval) throws {
    guard utf16Offset >= 0 else { throw NapDomainError.invalidResumePoint }
    guard estimatedRemainingDuration.isFinite, estimatedRemainingDuration > 0 else {
      throw NapDomainError.invalidDuration
    }
    self.sessionID = session.id
    self.revision = session.revision
    self.position = .script(utf16Offset: utf16Offset)
    self.estimatedRemainingDuration = estimatedRemainingDuration
  }

  init(session: Session, audioOffset: TimeInterval, estimatedRemainingDuration: TimeInterval) throws
  {
    guard audioOffset.isFinite, audioOffset >= 0 else {
      throw NapDomainError.invalidResumePoint
    }
    guard estimatedRemainingDuration.isFinite, estimatedRemainingDuration > 0 else {
      throw NapDomainError.invalidDuration
    }
    self.sessionID = session.id
    self.revision = session.revision
    self.position = .audio(seconds: audioOffset)
    self.estimatedRemainingDuration = estimatedRemainingDuration
  }

  func matches(_ session: Session) -> Bool {
    sessionID == session.id && revision == session.revision
  }

  /// A resumed run must keep its position kind and cannot move backwards.
  func isAtOrAfter(_ earlier: ResumePoint) -> Bool {
    switch (position, earlier.position) {
    case (.script(let current), .script(let previous)): return current >= previous
    case (.audio(let current), .audio(let previous)): return current >= previous
    default: return false
    }
  }
}

enum NapDomainError: Error, Equatable {
  case invalidIdentity
  case duplicateIdentity
  case invalidDuration
  case invalidDeadline
  case invalidStartingPoint
  case invalidTransition
  case cyclicRoute
  case invalidResumePoint
  case invalidPlaybackTime
  case deadlineExceeded
  case playbackEnded
  case duplicatePlaybackRecord
}
