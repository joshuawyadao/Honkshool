import Foundation

enum NapWindow: Equatable, Sendable {
  case duration(TimeInterval)
  case wakeTime(Date)
}

enum RestSound: Equatable, Sendable {
  case ambience(id: String)
  case silence
}

struct SessionSelection: Equatable, Sendable {
  let journeyID: Journey.ID
  let sessionID: Session.ID
  var resumePoint: ResumePoint? = nil
}

struct JourneyTransition: Equatable, Sendable {
  let from: Journey.ID
  let to: Journey.ID
}

struct NapRequest: Equatable, Sendable {
  let window: NapWindow
  let startingAt: SessionSelection
  /// Ordered pre-nap choices; used only if the main route cannot fit any narration.
  var shorterAlternatives: [SessionSelection] = []
  var approvedTransitions: [JourneyTransition] = []
  var settlingDuration: TimeInterval = 0
  var driftDuration: TimeInterval = 0
  var fallback: RestSound = .silence
  var alarmEnabled: Bool = false
}

struct PlannedSession: Equatable, Sendable {
  let journeyID: Journey.ID
  let session: Session
  let resumePoint: ResumePoint?
  let estimatedStart: Date
  let estimatedEnd: Date
}

struct PlanSegment: Equatable, Sendable {
  enum Kind: Equatable, Sendable {
    case settling(RestSound)
    case narration(routeIndex: Int)
    case drift(RestSound)
    case rest(RestSound)
  }

  let kind: Kind
  let start: Date
  let end: Date
  var duration: TimeInterval { end.timeIntervalSince(start) }
}

enum RouteEndReason: Equatable, Sendable {
  case windowFilled
  case nextSessionDoesNotFit
  case contentUnavailable
  case journeyEnded
}

/// A value snapshot produced only by NapPlanner, suitable for review before starting.
struct NapPlan: Equatable, Sendable {
  let id: String
  let start: Date
  let deadline: Date
  let wakeAlarm: Date?
  let route: [PlannedSession]
  let transitions: [JourneyTransition]
  let segments: [PlanSegment]
  let fallback: RestSound
  let usedShorterAlternative: Bool
  let routeEndReason: RouteEndReason
  let narrationStart: Date
  let driftDuration: TimeInterval

  fileprivate init(
    id: String, start: Date, deadline: Date, wakeAlarm: Date?, route: [PlannedSession],
    transitions: [JourneyTransition], segments: [PlanSegment], fallback: RestSound,
    usedShorterAlternative: Bool, routeEndReason: RouteEndReason, narrationStart: Date,
    driftDuration: TimeInterval
  ) {
    self.id = id
    self.start = start
    self.deadline = deadline
    self.wakeAlarm = wakeAlarm
    self.route = route
    self.transitions = transitions
    self.segments = segments
    self.fallback = fallback
    self.usedShorterAlternative = usedShorterAlternative
    self.routeEndReason = routeEndReason
    self.narrationStart = narrationStart
    self.driftDuration = driftDuration
  }

  /// Actual narration may finish early or consume the planned drift/rest budget.
  /// This changes only the remaining rest timing, never the route or wake deadline.
  func restSegments(afterNarrationAt date: Date) throws -> [PlanSegment] {
    guard date.timeIntervalSinceReferenceDate.isFinite, date >= narrationStart,
      date <= deadline
    else { throw NapDomainError.invalidPlaybackTime }
    let driftEnd = min(date.addingTimeInterval(driftDuration), deadline)
    var result: [PlanSegment] = []
    if driftEnd > date {
      result.append(PlanSegment(kind: .drift(fallback), start: date, end: driftEnd))
    }
    if deadline > driftEnd {
      result.append(PlanSegment(kind: .rest(fallback), start: driftEnd, end: deadline))
    }
    return result
  }
}

enum NapPlanner {
  static func makePlan(
    id: String, request: NapRequest, startingAt start: Date, now: Date,
    catalog: NapCatalog, availableAmbienceIDs: Set<String> = []
  ) throws -> NapPlan {
    guard !id.isEmpty else { throw NapDomainError.invalidIdentity }
    guard start.timeIntervalSinceReferenceDate.isFinite,
      now.timeIntervalSinceReferenceDate.isFinite, start >= now
    else { throw NapDomainError.invalidDeadline }
    let deadline: Date
    switch request.window {
    case .duration(let duration):
      guard duration.isFinite, duration > 0 else { throw NapDomainError.invalidDuration }
      deadline = start.addingTimeInterval(duration)
    case .wakeTime(let date):
      deadline = date
    }
    let duration = deadline.timeIntervalSince(start)
    guard deadline.timeIntervalSinceReferenceDate.isFinite, duration.isFinite, duration > 0 else {
      throw NapDomainError.invalidDeadline
    }
    guard request.settlingDuration.isFinite, request.settlingDuration >= 0,
      request.driftDuration.isFinite, request.driftDuration >= 0
    else { throw NapDomainError.invalidDuration }
    try validateTransitions(request.approvedTransitions, catalog: catalog)

    let fallback: RestSound
    if case .ambience(let id) = request.fallback, availableAmbienceIDs.contains(id) {
      fallback = request.fallback
    } else {
      fallback = .silence
    }
    let settling = min(request.settlingDuration, duration)
    let drift = min(request.driftDuration, duration - settling)
    let narrationStart = start.addingTimeInterval(settling)
    let narrationEnd = deadline.addingTimeInterval(-drift)
    var selection = try selectRoute(
      from: request.startingAt, transitions: request.approvedTransitions,
      start: narrationStart, end: narrationEnd, catalog: catalog)
    var usedAlternative = false
    if selection.route.isEmpty {
      for alternative in request.shorterAlternatives {
        let candidate = try selectRoute(
          from: alternative, transitions: request.approvedTransitions,
          start: narrationStart, end: narrationEnd, catalog: catalog)
        if !candidate.route.isEmpty {
          selection = candidate
          usedAlternative = true
          break
        }
      }
    }

    var segments: [PlanSegment] = []
    if settling > 0 {
      segments.append(PlanSegment(kind: .settling(fallback), start: start, end: narrationStart))
    }
    for (index, item) in selection.route.enumerated() {
      segments.append(
        PlanSegment(
          kind: .narration(routeIndex: index), start: item.estimatedStart, end: item.estimatedEnd))
    }
    let narrationFinished = selection.route.last?.estimatedEnd ?? narrationStart
    let driftEnd = min(narrationFinished.addingTimeInterval(drift), deadline)
    if drift > 0 {
      segments.append(PlanSegment(kind: .drift(fallback), start: narrationFinished, end: driftEnd))
    }
    if deadline > driftEnd {
      segments.append(PlanSegment(kind: .rest(fallback), start: driftEnd, end: deadline))
    }
    let transitions = zip(selection.route, selection.route.dropFirst()).compactMap { first, next in
      first.journeyID == next.journeyID
        ? nil
        : JourneyTransition(from: first.journeyID, to: next.journeyID)
    }
    return NapPlan(
      id: id, start: start, deadline: deadline, wakeAlarm: request.alarmEnabled ? deadline : nil,
      route: selection.route, transitions: transitions, segments: segments, fallback: fallback,
      usedShorterAlternative: usedAlternative, routeEndReason: selection.reason,
      narrationStart: narrationStart, driftDuration: drift)
  }

  private static func validateTransitions(
    _ transitions: [JourneyTransition], catalog: NapCatalog
  ) throws {
    guard Set(transitions.map(\.from)).count == transitions.count else {
      throw NapDomainError.invalidTransition
    }
    for transition in transitions {
      guard catalog.journeys[transition.from]?.nextJourneyIDs.contains(transition.to) == true else {
        throw NapDomainError.invalidTransition
      }
      var visited: Set<Journey.ID> = [transition.from]
      var next: Journey.ID? = transition.to
      while let current = next {
        guard visited.insert(current).inserted else { throw NapDomainError.cyclicRoute }
        next = transitions.first { $0.from == current }?.to
      }
    }
  }

  private static func selectRoute(
    from selection: SessionSelection, transitions: [JourneyTransition],
    start: Date, end: Date, catalog: NapCatalog
  ) throws -> (route: [PlannedSession], reason: RouteEndReason) {
    guard var journey = catalog.journeys[selection.journeyID],
      var index = journey.sessionIDs.firstIndex(of: selection.sessionID)
    else { throw NapDomainError.invalidStartingPoint }
    var route: [PlannedSession] = []
    var cursor = start
    var elapsed: TimeInterval = 0
    let budget = end.timeIntervalSince(start)
    // Date stores absolute seconds as Double. Admit representational rounding only,
    // accumulate relative estimates, and never move a segment beyond the deadline.
    let precision =
      max(start.timeIntervalSinceReferenceDate.ulp, end.timeIntervalSinceReferenceDate.ulp) * 2
    while true {
      guard index < journey.sessionIDs.count else {
        guard let transition = transitions.first(where: { $0.from == journey.id }) else {
          return (route, .journeyEnded)
        }
        guard let next = catalog.journeys[transition.to], !next.sessionIDs.isEmpty else {
          return (route, .contentUnavailable)
        }
        journey = next
        index = 0
        continue
      }
      guard let session = catalog.sessions[journey.sessionIDs[index]] else {
        return (route, .contentUnavailable)
      }
      let resume = route.isEmpty ? selection.resumePoint : nil
      if let resume, !resume.matches(session) { throw NapDomainError.invalidResumePoint }
      let estimate = resume?.estimatedRemainingDuration ?? session.estimatedDuration
      guard cursor < end, estimate <= budget - elapsed + precision else {
        return (route, cursor == end ? .windowFilled : .nextSessionDoesNotFit)
      }
      elapsed += estimate
      let next = min(start.addingTimeInterval(elapsed), end)
      guard next > cursor else { throw NapDomainError.invalidDuration }
      route.append(
        PlannedSession(
          journeyID: journey.id, session: session, resumePoint: resume,
          estimatedStart: cursor, estimatedEnd: next))
      cursor = next
      index += 1
      if cursor == end { return (route, .windowFilled) }
    }
  }
}
