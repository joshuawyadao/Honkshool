import Foundation

enum PartialPlaybackReason: Equatable, Sendable {
  case stopped
  case interrupted
  case deadlineReached
  /// Playback stopped after the deadline; the position was captured earlier.
  case deadlineMissed
}

enum PlaybackOutcome: Equatable, Sendable {
  /// Evidence from actual end-of-session playback, not an elapsed-time estimate.
  case completed
  case partial(reason: PartialPlaybackReason, resumePoint: ResumePoint)
}

struct PlaybackRecord: Equatable, Sendable {
  struct ID: Hashable, Sendable {
    let runID: String
    let routeIndex: Int
  }

  let id: ID
  let planID: String
  let plannedSession: PlannedSession
  let startedAt: Date
  let endedAt: Date
  /// Evidence time for a late stop. This must be at or before the deadline.
  let checkpointCapturedAt: Date?
  /// Active playback only; time paused must not be counted as played.
  let playedDuration: TimeInterval
  let outcome: PlaybackOutcome

  fileprivate init(
    id: ID, planID: String, plannedSession: PlannedSession, startedAt: Date, endedAt: Date,
    checkpointCapturedAt: Date?, playedDuration: TimeInterval, outcome: PlaybackOutcome
  ) {
    self.id = id
    self.planID = planID
    self.plannedSession = plannedSession
    self.startedAt = startedAt
    self.endedAt = endedAt
    self.checkpointCapturedAt = checkpointCapturedAt
    self.playedDuration = playedDuration
    self.outcome = outcome
  }

  /// Validate persisted identity, position, and timing before restoring historical evidence.
  /// The original plan is intentionally not reconstructed from historical content.
  init(
    restoringID id: ID, planID: String, plannedSession: PlannedSession, startedAt: Date,
    endedAt: Date, checkpointCapturedAt: Date?, playedDuration: TimeInterval,
    outcome: PlaybackOutcome
  ) throws {
    guard !id.runID.isEmpty, id.routeIndex >= 0, !planID.isEmpty,
      !plannedSession.journeyID.isEmpty,
      plannedSession.estimatedStart.timeIntervalSinceReferenceDate.isFinite,
      plannedSession.estimatedEnd.timeIntervalSinceReferenceDate.isFinite,
      plannedSession.estimatedEnd > plannedSession.estimatedStart,
      startedAt.timeIntervalSinceReferenceDate.isFinite,
      endedAt.timeIntervalSinceReferenceDate.isFinite,
      endedAt >= startedAt, playedDuration.isFinite, playedDuration >= 0
    else { throw NapDomainError.invalidPlaybackTime }
    if let resume = plannedSession.resumePoint {
      guard resume.matches(plannedSession.session) else { throw NapDomainError.invalidResumePoint }
    }
    switch outcome {
    case .completed:
      guard checkpointCapturedAt == nil else { throw NapDomainError.invalidPlaybackTime }
    case .partial(let reason, let point):
      guard point.matches(plannedSession.session),
        plannedSession.resumePoint.map({ point.isAtOrAfter($0) }) ?? true
      else { throw NapDomainError.invalidResumePoint }
      if reason == .deadlineMissed {
        guard let checkpointCapturedAt,
          checkpointCapturedAt.timeIntervalSinceReferenceDate.isFinite,
          checkpointCapturedAt >= startedAt, checkpointCapturedAt <= endedAt
        else { throw NapDomainError.invalidPlaybackTime }
      } else {
        guard checkpointCapturedAt == nil else { throw NapDomainError.invalidPlaybackTime }
      }
    }
    let evidenceEnd = checkpointCapturedAt ?? endedAt
    let precision =
      max(
        startedAt.timeIntervalSinceReferenceDate.ulp,
        evidenceEnd.timeIntervalSinceReferenceDate.ulp) * 2
    guard playedDuration <= evidenceEnd.timeIntervalSince(startedAt) + precision else {
      throw NapDomainError.invalidPlaybackTime
    }
    self.init(
      id: id, planID: planID, plannedSession: plannedSession, startedAt: startedAt,
      endedAt: endedAt, checkpointCapturedAt: checkpointCapturedAt,
      playedDuration: playedDuration, outcome: outcome)
  }

  var isCompleted: Bool { outcome == .completed }

  var resumePoint: ResumePoint? {
    if case .partial(_, let point) = outcome { return point }
    return nil
  }
}

/// Pure outcome bookkeeping for one approved plan. No clocks, audio, alarms, or storage.
/// A partial final outcome closes this run; its checkpoint can seed a later reviewed plan.
struct NapPlayback: Equatable, Sendable {
  let plan: NapPlan
  let runID: String
  private(set) var records: [PlaybackRecord] = []
  private var endedPartially = false

  init(plan: NapPlan, runID: String) throws {
    guard !runID.isEmpty else { throw NapDomainError.invalidIdentity }
    self.plan = plan
    self.runID = runID
  }

  /// A future runtime must stop narration at this deadline, even with no alarm.
  func mustStop(at date: Date) throws -> Bool {
    guard date.timeIntervalSinceReferenceDate.isFinite else {
      throw NapDomainError.invalidPlaybackTime
    }
    return endedPartially || date >= plan.deadline
  }

  /// Actual completion can move through the approved route early; never add new content.
  func nextSession(at date: Date) throws -> PlannedSession? {
    guard try !mustStop(at: date), date >= plan.narrationStart,
      date >= (records.last?.endedAt ?? plan.narrationStart), records.count < plan.route.count
    else { return nil }
    return plan.route[records.count]
  }

  @discardableResult
  mutating func recordSession(
    startedAt: Date, endedAt: Date, playedDuration: TimeInterval, outcome: PlaybackOutcome,
    checkpointCapturedAt: Date? = nil
  ) throws -> PlaybackRecord {
    guard !endedPartially, records.count < plan.route.count else {
      throw NapDomainError.playbackEnded
    }
    guard startedAt.timeIntervalSinceReferenceDate.isFinite,
      endedAt.timeIntervalSinceReferenceDate.isFinite,
      startedAt >= (records.last?.endedAt ?? plan.narrationStart), endedAt >= startedAt,
      startedAt < plan.deadline, playedDuration.isFinite, playedDuration >= 0
    else { throw NapDomainError.invalidPlaybackTime }
    if endedAt > plan.deadline {
      guard case .partial(reason: .deadlineMissed, resumePoint: _) = outcome else {
        throw NapDomainError.deadlineExceeded
      }
      guard let checkpointCapturedAt,
        checkpointCapturedAt.timeIntervalSinceReferenceDate.isFinite,
        checkpointCapturedAt >= startedAt, checkpointCapturedAt <= plan.deadline
      else { throw NapDomainError.invalidPlaybackTime }
    } else {
      guard checkpointCapturedAt == nil else { throw NapDomainError.invalidPlaybackTime }
      if case .partial(reason: .deadlineMissed, resumePoint: _) = outcome {
        throw NapDomainError.invalidPlaybackTime
      }
    }
    let evidenceEnd = checkpointCapturedAt ?? endedAt
    let precision =
      max(
        startedAt.timeIntervalSinceReferenceDate.ulp,
        evidenceEnd.timeIntervalSinceReferenceDate.ulp) * 2
    guard playedDuration <= evidenceEnd.timeIntervalSince(startedAt) + precision else {
      throw NapDomainError.invalidPlaybackTime
    }
    let plannedSession = plan.route[records.count]
    var acceptedOutcome = outcome
    if case .partial(let reason, let resume) = outcome {
      guard resume.matches(plannedSession.session),
        plannedSession.resumePoint.map({ resume.isAtOrAfter($0) }) ?? true
      else { throw NapDomainError.invalidResumePoint }
      guard reason != .deadlineReached || endedAt == plan.deadline else {
        throw NapDomainError.invalidPlaybackTime
      }
      if endedAt == plan.deadline {
        acceptedOutcome = .partial(reason: .deadlineReached, resumePoint: resume)
      }
    }
    let record = PlaybackRecord(
      id: .init(runID: runID, routeIndex: records.count), planID: plan.id,
      plannedSession: plannedSession, startedAt: startedAt, endedAt: endedAt,
      checkpointCapturedAt: checkpointCapturedAt, playedDuration: playedDuration,
      outcome: acceptedOutcome)
    records.append(record)
    endedPartially = !record.isCompleted
    return record
  }

  /// Available only after every approved session actually completed (or an empty route).
  func remainingRestSegments() throws -> [PlanSegment]? {
    guard !endedPartially, records.count == plan.route.count else { return nil }
    return try plan.restSegments(afterNarrationAt: records.last?.endedAt ?? plan.narrationStart)
  }
}

/// Append-only evidence. Choosing a start point, replaying, or restarting never clears it.
struct ListeningHistory: Equatable, Sendable {
  private(set) var records: [PlaybackRecord] = []

  mutating func append(_ record: PlaybackRecord) throws {
    guard !records.contains(where: { $0.id == record.id }) else {
      throw NapDomainError.duplicatePlaybackRecord
    }
    records.append(record)
  }

  func completedSessionIDs(in journeyID: Journey.ID) -> Set<Session.ID> {
    Set(
      records.filter {
        $0.plannedSession.journeyID == journeyID && $0.isCompleted
      }.map { $0.plannedSession.session.id })
  }

  /// Later completed sessions never hide an earlier incomplete gap in this journey.
  func nextSessionID(in journey: Journey) -> Session.ID? {
    let completed = completedSessionIDs(in: journey.id)
    return journey.sessionIDs.first { !completed.contains($0) }
  }

  /// Every partial record retains its own checkpoint, even after a replay completes.
  /// Callers choose the attempt to resume; history never guesses which path to replace.
  func resumeSelection(for recordID: PlaybackRecord.ID) -> SessionSelection? {
    guard let record = records.first(where: { $0.id == recordID }),
      let point = record.resumePoint
    else { return nil }
    return SessionSelection(
      journeyID: record.plannedSession.journeyID,
      sessionID: record.plannedSession.session.id, resumePoint: point)
  }
}
