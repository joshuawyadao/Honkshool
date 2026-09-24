import Foundation

/// The journey name is copied at review time, alongside the planner's session snapshot.
struct NapPlanReviewRouteItem: Equatable, Sendable {
  let planned: PlannedSession
  let journeyTitle: String
}

/// Everything the listener approves before a future playback adapter can start a run.
struct NapPlanReview: Equatable, Sendable {
  let plan: NapPlan
  let reviewedAt: Date
  let requestedSound: RestSound
  let selectedWindow: NapWindow
  let selectedSession: SessionSelection
  let approvedTransitions: [JourneyTransition]
  let route: [NapPlanReviewRouteItem]
}

enum NapPlanReviewError: Error, Equatable {
  case alreadyConfirmed
  case staleReview
  case deadlineReached
}

/// Keeps the confirmed review as a value snapshot. Editing choices creates a new review;
/// confirmation never recalculates against a later clock or catalog.
struct NapPlanReviewState {
  private(set) var reviewed: NapPlanReview?
  private(set) var confirmed: NapPlanReview?

  mutating func review(
    id: String, request: NapRequest, startingAt start: Date, now: Date,
    catalog: NapCatalog, availableAmbienceIDs: Set<String> = []
  ) throws {
    guard confirmed == nil else { throw NapPlanReviewError.alreadyConfirmed }
    reviewed = nil
    let plan = try NapPlanner.makePlan(
      id: id, request: request, startingAt: start, now: now,
      catalog: catalog, availableAmbienceIDs: availableAmbienceIDs)
    let route = plan.route.map { planned in
      NapPlanReviewRouteItem(
        planned: planned,
        journeyTitle: catalog.journeys[planned.journeyID]?.title ?? planned.journeyID)
    }
    reviewed = NapPlanReview(
      plan: plan, reviewedAt: now, requestedSound: request.fallback, selectedWindow: request.window,
      selectedSession: request.startingAt, approvedTransitions: request.approvedTransitions,
      route: route)
  }

  mutating func clearReview() {
    guard confirmed == nil else { return }
    reviewed = nil
  }

  mutating func confirm(at now: Date) throws {
    guard confirmed == nil, let reviewed else { return }
    guard now.timeIntervalSinceReferenceDate.isFinite, now < reviewed.plan.deadline else {
      throw NapPlanReviewError.deadlineReached
    }
    guard now >= reviewed.reviewedAt, now <= reviewed.plan.start else {
      throw NapPlanReviewError.staleReview
    }
    confirmed = reviewed
  }
}
