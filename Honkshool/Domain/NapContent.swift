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

/// A script position, never elapsed seconds. The adapter supplies the position and
/// remaining estimate for this exact revision; no speech speed is inferred here.
struct ResumePoint: Equatable, Sendable {
  let sessionID: Session.ID
  let revision: String
  let utf16Offset: Int
  let estimatedRemainingDuration: TimeInterval

  init(session: Session, utf16Offset: Int, estimatedRemainingDuration: TimeInterval) throws {
    guard utf16Offset >= 0 else { throw NapDomainError.invalidResumePoint }
    guard estimatedRemainingDuration.isFinite, estimatedRemainingDuration > 0 else {
      throw NapDomainError.invalidDuration
    }
    self.sessionID = session.id
    self.revision = session.revision
    self.utf16Offset = utf16Offset
    self.estimatedRemainingDuration = estimatedRemainingDuration
  }

  func matches(_ session: Session) -> Bool {
    sessionID == session.id && revision == session.revision
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
