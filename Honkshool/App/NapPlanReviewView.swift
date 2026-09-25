import SwiftUI

/// Review remains immutable; a separate controller executes the confirmed snapshot on request.
struct NapPlanReviewView: View {
  private static let plannedStartLead: TimeInterval = 60
  @ObservedObject private var run: NapRunController
  @ObservedObject private var alarm: NapPlanAlarmService
  private let canStart: () -> Bool
  private let clock: () -> Date
  private let confirmationClock: () -> Date
  private let makeID: () -> String
  private let loadCatalog: () throws -> PreparedCatalog
  private let isNarrationAvailable: (PreparedSession) -> Bool
  private let availableAmbienceIDs: Set<String>

  @State private var catalog: PreparedCatalog?
  @State private var reviewCatalog: NapCatalog?
  @State private var loadError: String?
  @State private var selectionIndex = 0
  @State private var durationMinutes = 20
  @State private var usesExactWakeTime = false
  @State private var exactWakeTime: Date
  @State private var selectedSoundID: String?
  @State private var alarmEnabled = true
  @State private var shorterIndices: Set<Int> = []
  @State private var approvedNextJourney: [Journey.ID: Journey.ID] = [:]
  @State private var reviewState = NapPlanReviewState()
  @State private var reviewError: String?
  @State private var runError: String?
  @State private var isStarting = false
  @State private var isVisible = false

  init(
    run: NapRunController,
    alarm: NapPlanAlarmService,
    canStart: @escaping () -> Bool = { true },
    clock: @escaping () -> Date = { .now },
    confirmationClock: (() -> Date)? = nil,
    makeID: @escaping () -> String = { UUID().uuidString },
    loadCatalog: @escaping () throws -> PreparedCatalog = { try .load() },
    isNarrationAvailable: @escaping (PreparedSession) -> Bool = {
      (try? $0.narrationURL()) != nil
    },
    availableAmbienceIDs: Set<String> = []
  ) {
    self.run = run
    self.alarm = alarm
    self.canStart = canStart
    self.clock = clock
    self.confirmationClock = confirmationClock ?? clock
    self.makeID = makeID
    self.loadCatalog = loadCatalog
    self.isNarrationAvailable = isNarrationAvailable
    self.availableAmbienceIDs = availableAmbienceIDs
    let suggestedWake = clock().addingTimeInterval(20 * 60)
    _exactWakeTime = State(
      initialValue: Date(timeIntervalSince1970: ceil(suggestedWake.timeIntervalSince1970 / 60) * 60)
    )
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text(
          "Choose what you would like to hear, then review the entire route and fixed wake deadline before confirming."
        )
        .foregroundStyle(.secondary)

        if let loadError {
          ContentUnavailableView(
            "Content unavailable", systemImage: "book.closed", description: Text(loadError)
          )
          .accessibilityIdentifier("napPlanCatalogError")
        } else if let catalog, let reviewCatalog {
          if let confirmed = reviewState.confirmed {
            confirmedContent(confirmed)
          } else {
            choices(catalog, reviewCatalog: reviewCatalog)
            if let review = reviewState.reviewed {
              reviewContent(review)
            }
          }
        } else {
          ProgressView("Loading prepared content")
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
    }
    .background(Color(.systemGroupedBackground))
    .navigationTitle("Nap Plan")
    .onAppear { isVisible = true }
    .onDisappear { isVisible = false }
    .task {
      guard catalog == nil && loadError == nil else { return }
      do {
        let loaded = try loadCatalog()
        reviewCatalog = try loaded.reviewCatalog(isNarrationAvailable: isNarrationAvailable)
        catalog = loaded
      } catch {
        loadError = "The prepared catalog could not be loaded. \(error.localizedDescription)"
      }
    }
  }

  private func choices(_ catalog: PreparedCatalog, reviewCatalog: NapCatalog) -> some View {
    let options = sessionOptions(in: catalog, reviewCatalog: reviewCatalog)
    return Group {
      card("Available content", systemImage: "book") {
        if options.isEmpty {
          Text("No prepared sessions are available for planning.")
        } else {
          Picker("Start with", selection: $selectionIndex) {
            ForEach(options.indices, id: \.self) { index in
              Text("\(options[index].journey.title) · \(options[index].session.title)")
                .tag(index)
            }
          }
          .accessibilityIdentifier("napPlanContent")
          Text(
            "Only prepared content can be selected. The plan never searches for new content during rest."
          )
          .font(.footnote)
          .foregroundStyle(.secondary)
        }
      }

      card("Rest window", systemImage: "timer") {
        Toggle("Choose an exact wake time", isOn: $usesExactWakeTime)
          .accessibilityIdentifier("napPlanUseExactWakeTime")
        if usesExactWakeTime {
          DatePicker(
            "Wake time", selection: $exactWakeTime, displayedComponents: [.date, .hourAndMinute]
          )
          .accessibilityLabel("Wake time")
          .accessibilityIdentifier("napPlanExactWakeTime")
        } else {
          Picker("Rest duration", selection: $durationMinutes) {
            ForEach([5, 10, 20, 30, 45, 60], id: \.self) { minutes in
              Text("\(minutes) minutes").tag(minutes)
            }
          }
          .accessibilityIdentifier("napPlanDuration")
          Stepper("\(durationMinutes) minutes", value: $durationMinutes, in: 1...180)
            .accessibilityIdentifier("napPlanCustomDuration")
        }
        Text("This is a rest window, not a promise of sleep time.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }

      card("After narration", systemImage: "speaker.wave.2") {
        Picker("Sound", selection: $selectedSoundID) {
          Text("Silence").tag(String?.none)
          ForEach(availableAmbienceIDs.sorted(), id: \.self) { id in
            Text(id).tag(Optional(id))
          }
        }
        .accessibilityIdentifier("napPlanSound")
        if availableAmbienceIDs.isEmpty {
          Text(
            "Silence is currently the only available sound. The rain candidate is still under review."
          )
          .font(.footnote)
          .foregroundStyle(.secondary)
        }
      }

      card("Wake alarm", systemImage: "alarm") {
        Toggle("Request a wake alarm", isOn: $alarmEnabled)
          .accessibilityIdentifier("napPlanAlarm")
        Text(
          "If requested, a system wake alarm must be scheduled for the fixed deadline before playback can start."
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
      }

      if let selected = options.indices.contains(selectionIndex) ? options[selectionIndex] : nil {
        let shorter = options.indices.filter {
          $0 != selectionIndex
            && options[$0].session.estimatedDuration < selected.session.estimatedDuration
        }
        card("Shorter options", systemImage: "text.line.first.and.arrowtriangle.forward") {
          if shorter.isEmpty {
            Text(
              "No shorter prepared sessions are available. A short window may use silence throughout."
            )
            .font(.footnote)
          } else {
            Text(
              "Approve these only if the selected session cannot fit. They are tried in the order shown."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            ForEach(shorter, id: \.self) { index in
              Toggle(
                "\(options[index].journey.title) · \(options[index].session.title)",
                isOn: Binding(
                  get: { shorterIndices.contains(index) },
                  set: { enabled in
                    if enabled {
                      shorterIndices.insert(index)
                    } else {
                      shorterIndices.remove(index)
                    }
                    invalidateReview()
                  }
                )
              )
              .accessibilityIdentifier("napPlanShorterOption-\(index)")
            }
          }
        }
      }

      let branching = catalog.journeys.filter { !$0.nextJourneyIDs.isEmpty }
      if !branching.isEmpty {
        card("Journey transitions", systemImage: "arrow.triangle.branch") {
          Text("Only a transition approved here may follow a completed journey.")
            .font(.footnote)
            .foregroundStyle(.secondary)
          ForEach(branching, id: \.id) { journey in
            Picker(
              "After \(journey.title)",
              selection: Binding(
                get: { approvedNextJourney[journey.id] },
                set: {
                  approvedNextJourney[journey.id] = $0
                  invalidateReview()
                }
              )
            ) {
              Text("Stop narration").tag(String?.none)
              ForEach(journey.nextJourneyIDs, id: \.self) { id in
                if let next = catalog.planningCatalog.journeys[id] {
                  Text(next.title).tag(Optional(id))
                }
              }
            }
            .accessibilityIdentifier("napPlanTransition-\(journey.id)")
          }
        }
      }

      if let reviewError {
        Label(reviewError, systemImage: "exclamationmark.circle")
          .foregroundStyle(.red)
          .accessibilityIdentifier("napPlanError")
      }
      Button("Review Nap Plan") {
        review(catalog, reviewCatalog: reviewCatalog, options: options)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .disabled(options.isEmpty)
      .accessibilityIdentifier("reviewNapPlan")
    }
    .onChange(of: selectionIndex) { _, _ in
      shorterIndices.removeAll()
      invalidateReview()
    }
    .onChange(of: durationMinutes) { _, _ in invalidateReview() }
    .onChange(of: usesExactWakeTime) { _, _ in invalidateReview() }
    .onChange(of: exactWakeTime) { _, _ in invalidateReview() }
    .onChange(of: selectedSoundID) { _, _ in invalidateReview() }
    .onChange(of: alarmEnabled) { _, _ in invalidateReview() }
  }

  private func review(
    _ catalog: PreparedCatalog, reviewCatalog: NapCatalog, options: [SessionOption],
    at reviewTime: Date? = nil
  ) {
    guard options.indices.contains(selectionIndex) else { return }
    let selected = options[selectionIndex]
    let now = reviewTime ?? clock()
    let window: NapWindow =
      usesExactWakeTime
      ? .wakeTime(exactWakeTime)
      : .duration(TimeInterval(durationMinutes * 60))
    let plannedStart = Self.plannedStart(for: window, reviewedAt: now)
    let alternatives = options.indices.filter { shorterIndices.contains($0) }.map {
      SessionSelection(journeyID: options[$0].journey.id, sessionID: options[$0].session.id)
    }
    let transitions = catalog.journeys.compactMap { journey -> JourneyTransition? in
      guard let next = approvedNextJourney[journey.id] else { return nil }
      return JourneyTransition(from: journey.id, to: next)
    }
    let request = NapRequest(
      window: window,
      startingAt: SessionSelection(journeyID: selected.journey.id, sessionID: selected.session.id),
      shorterAlternatives: alternatives,
      approvedTransitions: transitions,
      fallback: selectedSoundID.map(RestSound.ambience(id:)) ?? .silence,
      alarmEnabled: alarmEnabled
    )
    do {
      try reviewState.review(
        id: makeID(), request: request, startingAt: plannedStart, now: now,
        catalog: reviewCatalog, availableAmbienceIDs: availableAmbienceIDs
      )
      reviewError = nil
    } catch {
      reviewState.clearReview()
      reviewError = message(for: error)
    }
  }

  private func reviewContent(_ review: NapPlanReview) -> some View {
    Group {
      card("Review before confirming", systemImage: "checklist") {
        LabeledContent("Planned rest start") {
          Text(review.plan.start.formatted(date: .abbreviated, time: .standard))
        }
        .accessibilityIdentifier("napPlanPlannedStart")
        LabeledContent("Fixed wake deadline") {
          Text(review.plan.deadline.formatted(date: .abbreviated, time: .standard))
        }
        .accessibilityIdentifier("napPlanDeadline")
        LabeledContent(
          "Wake alarm",
          value: review.plan.wakeAlarm == nil ? "Not requested" : "Requested at deadline"
        )
        .accessibilityIdentifier("napPlanAlarmChoice")
        LabeledContent("After narration", value: soundName(review.plan.fallback))
          .accessibilityIdentifier("napPlanPostNarrationSound")
        if review.requestedSound != review.plan.fallback {
          Text("Requested sound is unavailable; this plan uses silence.")
            .font(.footnote)
            .accessibilityIdentifier("napPlanSoundFallback")
        }
        if review.plan.usedShorterAlternative {
          Text("The selected session did not fit. A preapproved shorter session was chosen.")
            .accessibilityIdentifier("napPlanShorterSelection")
        }
        Text(endExplanation(review.plan))
          .font(.footnote)
          .accessibilityIdentifier("napPlanRouteEnd")
      }

      card("Complete approved narration route", systemImage: "list.number") {
        if review.route.isEmpty {
          Text(
            "No narration fits this rest window. The plan remains quiet through the fixed deadline."
          )
          .accessibilityIdentifier("napPlanNoContent")
        } else {
          ForEach(Array(review.route.enumerated()), id: \.offset) { index, item in
            VStack(alignment: .leading, spacing: 2) {
              Text("\(index + 1). \(item.planned.session.title)")
                .font(.subheadline.weight(.semibold))
              Text(item.journeyTitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
              Text(
                "Estimated \(item.planned.estimatedStart.formatted(date: .omitted, time: .shortened))–\(item.planned.estimatedEnd.formatted(date: .omitted, time: .shortened))"
              )
              .font(.footnote)
              .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("napPlanRouteItem-\(index)")
          }
        }
      }

      card("Approved journey transitions", systemImage: "arrow.triangle.branch") {
        let approvals = review.approvedTransitions.sorted { $0.from < $1.from }
        if approvals.isEmpty {
          Text("None")
        } else {
          ForEach(approvals, id: \.from) { approval in
            let fromTitle = catalog?.planningCatalog.journeys[approval.from]?.title ?? approval.from
            let toTitle = catalog?.planningCatalog.journeys[approval.to]?.title ?? approval.to
            Text("\(fromTitle) → \(toTitle)")
          }
        }
        if !review.plan.transitions.isEmpty {
          Text("The reviewed route uses \(review.plan.transitions.count) approved transition(s).")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }

      Text(
        "Confirm by the planned rest start. Short exact wake windows allow less review time. If the start passes, the deadline and route will refresh for another review."
      )
      .font(.footnote)
      .foregroundStyle(.secondary)
      Button("Confirm reviewed plan") { confirm() }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .accessibilityIdentifier("confirmNapPlan")
    }
  }

  private func confirm() {
    let now = confirmationClock()
    do {
      try reviewState.confirm(at: now)
      reviewError = nil
    } catch {
      guard let catalog, let reviewCatalog else {
        reviewState.clearReview()
        reviewError = "The reviewed plan is no longer available. Review your choices again."
        return
      }
      review(
        catalog, reviewCatalog: reviewCatalog,
        options: sessionOptions(in: catalog, reviewCatalog: reviewCatalog), at: now)
      if reviewState.reviewed != nil {
        reviewError =
          "Time passed since review. Check the updated deadline and route, then confirm again."
      }
    }
  }

  private func confirmedContent(_ confirmed: NapPlanReview) -> some View {
    card("Plan confirmed", systemImage: "checkmark.circle") {
      Text("Your approved route and fixed deadline are ready for a start request.")
        .accessibilityIdentifier("napPlanConfirmation")
      LabeledContent("Planned rest start") {
        Text(confirmed.plan.start.formatted(date: .abbreviated, time: .standard))
      }
      .accessibilityIdentifier("napPlanConfirmedStart")
      LabeledContent("Fixed wake deadline") {
        Text(confirmed.plan.deadline.formatted(date: .abbreviated, time: .standard))
      }
      .accessibilityIdentifier("napPlanConfirmedDeadline")
      LabeledContent("Approved narration", value: "\(confirmed.route.count) session(s)")
      LabeledContent(
        "Wake alarm",
        value: confirmed.plan.wakeAlarm == nil ? "Not requested" : "Requested at fixed deadline")
      if let runError {
        Label(runError, systemImage: "exclamationmark.circle")
          .foregroundStyle(.red)
          .accessibilityIdentifier("napRunError")
      }
      if run.hasActiveRun {
        Label(run.statusMessage, systemImage: "waveform")
          .accessibilityIdentifier("napRunStatus")
        if run.phase == .narrating {
          Button("Pause narration") { run.pause() }
            .accessibilityIdentifier("pauseNapRun")
        } else if run.phase == .paused || run.phase == .interrupted {
          Button("Resume narration") { run.resume() }
            .accessibilityIdentifier("resumeNapRun")
        }
        Button("Stop playback", role: .destructive) { run.stop() }
          .accessibilityIdentifier("stopNapRun")
        if confirmed.plan.wakeAlarm != nil {
          Text("Stopping playback does not cancel the wake alarm.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      } else if run.lastRunPlanID != confirmed.plan.id && runError == nil {
        if alarm.hasTrackedAlarm {
          Text("A Honkshool wake alarm is still tracked. Cancel it before starting another plan.")
            .accessibilityIdentifier("napRunPreviousAlarmGate")
        } else {
          Text(
            confirmed.plan.wakeAlarm == nil
              ? "This run has no wake alarm. Keep Honkshool open until narration begins, then you can lock the phone. Set another alarm if you need one."
              : "Honkshool will request alarm access if needed, schedule the wake alarm, then start the approved route. Keep the app open until narration begins."
          )
          .font(.footnote)
          .foregroundStyle(.secondary)
          Button("Start resting") {
            Task { await startConfirmed(confirmed) }
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.large)
          .disabled(isStarting || alarm.isScheduling)
          .accessibilityIdentifier("startNapRun")
          if isStarting {
            ProgressView("Scheduling the wake alarm")
              .accessibilityIdentifier("napRunScheduling")
          }
        }
      } else if run.phase != .idle {
        Label(run.statusMessage, systemImage: "info.circle")
          .accessibilityIdentifier("napRunStatus")
      }
      if run.lastRunPlanID == confirmed.plan.id && !run.records.isEmpty {
        Text("Completed sessions in this run: \(run.records.filter(\.isCompleted).count)")
          .accessibilityIdentifier("napRunCompletionCount")
      }
      if run.lastRunPlanID == confirmed.plan.id
        && (run.latestVerifiedCheckpoint != nil || !run.records.isEmpty)
      {
        Text("Playback evidence is in memory until local history is connected.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
      if !run.hasActiveRun {
        if alarm.hasTrackedAlarm {
          Label(alarm.statusMessage, systemImage: "alarm")
            .accessibilityIdentifier("napPlanAlarmStatus")
          if alarm.canCancelTrackedAlarm {
            Button("Cancel wake alarm", role: .destructive) {
              if !alarm.cancel() { runError = alarm.statusMessage }
            }
            .disabled(alarm.isScheduling)
            .accessibilityIdentifier("cancelNapPlanAlarm")
          }
        }
        Button("Review another plan") {
          run.resetPresentation()
          reviewState = NapPlanReviewState()
          reviewError = nil
          runError = nil
        }
        .disabled(isStarting)
        .accessibilityIdentifier("reviewAnotherNapPlan")
      }
    }
  }

  private func startConfirmed(_ confirmed: NapPlanReview) async {
    guard !isStarting else { return }
    isStarting = true
    defer { isStarting = false }
    guard canStart() else {
      runError = "Stop the feasibility audio and cancel its test alarm before starting a Nap Plan."
      return
    }
    guard let catalog else {
      runError = "The prepared catalog is unavailable. Review a new plan."
      return
    }
    do {
      try run.preflight(review: confirmed, catalog: catalog)
      guard !alarm.hasTrackedAlarm else {
        runError = "Cancel the previous Honkshool wake alarm before starting another plan."
        return
      }
      var scheduledAlarm: ScheduledNapAlarm?
      if confirmed.plan.wakeAlarm != nil {
        guard let scheduled = await alarm.schedule(for: confirmed.plan) else {
          runError = alarm.statusMessage
          return
        }
        guard alarm.isScheduled(scheduled) else {
          runError = alarm.statusMessage
          return
        }
        guard isVisible, reviewState.confirmed?.plan.id == confirmed.plan.id else {
          runError =
            "The review closed while scheduling. The wake alarm remains tracked; cancel it separately if needed."
          return
        }
        scheduledAlarm = scheduled
      }
      try run.start(review: confirmed, catalog: catalog, scheduledAlarm: scheduledAlarm)
      runError = nil
    } catch let error as NapRunError {
      let message =
        switch error {
        case .staleStart: "The approved start passed. Review a new Nap Plan."
        case .alarmUnavailable: "The requested wake alarm is not verified for this plan."
        case .ambienceUnavailable: "The approved rest sound is unavailable. Review a new plan."
        case .contentUnavailable: "The approved narration is unavailable. Review a new plan."
        case .invalidCheckpoint: "The approved audio checkpoint is unavailable. Review a new plan."
        case .audioUnavailable: "Audio could not start. Review a new plan after checking output."
        case .alreadyRunning: "A Nap Plan is already running."
        }
      runError =
        alarm.hasTrackedAlarm
        ? "\(message) The wake alarm remains tracked; cancel it separately if needed."
        : message
    } catch {
      runError = "The Nap Plan could not start: \(error.localizedDescription)"
    }
  }

  private func sessionOptions(
    in catalog: PreparedCatalog, reviewCatalog: NapCatalog
  ) -> [SessionOption] {
    catalog.journeys.flatMap { journey in
      journey.sessionIDs.compactMap { id in
        guard reviewCatalog.sessions[id] != nil else { return nil }
        return catalog.sessions[id].map { SessionOption(journey: journey, session: $0.session) }
      }
    }
  }

  private func invalidateReview() {
    reviewState.clearReview()
    reviewError = nil
  }

  static func plannedStart(for window: NapWindow, reviewedAt now: Date) -> Date {
    let lead: TimeInterval
    switch window {
    case .duration:
      lead = plannedStartLead
    case .wakeTime(let wake):
      lead = min(plannedStartLead, max(0, wake.timeIntervalSince(now) / 2))
    }
    return now.addingTimeInterval(lead)
  }

  private func soundName(_ sound: RestSound) -> String {
    switch sound {
    case .silence: "Silence"
    case .ambience(let id): id
    }
  }

  private func endExplanation(_ plan: NapPlan) -> String {
    switch plan.routeEndReason {
    case .windowFilled: "The narration allocation reaches its planned limit."
    case .nextSessionDoesNotFit:
      "The next full session does not fit; rest continues with the selected sound."
    case .contentUnavailable:
      "Subsequent content is unavailable; rest continues with the selected sound."
    case .journeyEnded:
      "The approved journey route ends here; rest continues with the selected sound."
    }
  }

  private func message(for error: Error) -> String {
    guard let domainError = error as? NapDomainError else { return error.localizedDescription }
    return switch domainError {
    case .invalidDeadline: "Choose a wake time later than the plan start."
    case .invalidDuration: "Choose a positive rest duration."
    case .invalidStartingPoint: "The selected content is no longer available."
    case .invalidTransition, .cyclicRoute: "These journey transitions cannot form a valid route."
    default: "This plan could not be reviewed: \(domainError)."
    }
  }

  private func card<Content: View>(
    _ title: String, systemImage: String, @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Label(title, systemImage: systemImage)
        .font(.headline)
      content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(.background, in: RoundedRectangle(cornerRadius: 18))
  }
}

private struct SessionOption {
  let journey: Journey
  let session: Session
}
