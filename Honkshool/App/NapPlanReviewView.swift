import SwiftUI

/// Review remains immutable; a separate controller executes the confirmed snapshot on request.
struct NapPlanReviewView: View {
  private static let plannedStartLead: TimeInterval = 60
  @Environment(\.openURL) private var openURL
  @ObservedObject private var run: NapRunController
  @ObservedObject private var alarm: NapPlanAlarmService
  @ObservedObject private var historyStore: ListeningHistoryStore
  private let isHome: Bool
  private let initialSelection: SessionSelection?
  private let canStart: () -> Bool
  private let clock: () -> Date
  private let confirmationClock: () -> Date
  private let makeID: () -> String
  private let loadCatalog: () throws -> PreparedCatalog
  private let isNarrationAvailable: (PreparedSession) -> Bool
  private let availableAmbienceIDs: Set<String>

  @State private var showsTimeOptions = false
  @State private var showsSessionDetail = false
  @State private var catalog: PreparedCatalog?
  @State private var reviewCatalog: NapCatalog?
  @State private var loadError: String?
  @State private var selectionIndex = 0
  @State private var selectedResumePoint: ResumePoint?
  @State private var seedError: String?
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
  @State private var startedPlanID: String?
  @State private var isStarting = false
  @State private var isVisible = false

  init(
    run: NapRunController,
    alarm: NapPlanAlarmService,
    historyStore: ListeningHistoryStore,
    startingAt initialSelection: SessionSelection? = nil,
    isHome: Bool = false,
    canStart: @escaping () -> Bool = { true },
    clock: @escaping () -> Date = { .now },
    confirmationClock: (() -> Date)? = nil,
    makeID: @escaping () -> String = { UUID().uuidString },
    loadCatalog: @escaping () throws -> PreparedCatalog = { try .load() },
    isNarrationAvailable: @escaping (PreparedSession) -> Bool = {
      (try? $0.narrationURL()) != nil
    },
    availableAmbienceIDs: Set<String> = PreparedAmbience.availableIDs(bundle: .main)
  ) {
    self.isHome = isHome
    self.run = run
    self.alarm = alarm
    self.historyStore = historyStore
    self.initialSelection = initialSelection
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
    ScrollViewReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          Color.clear.frame(height: 0).id("planTop")
          if let error = historyStore.errorMessage {
            errorLabel(error, id: "napHistorySaveError")
            Button("Retry saving") { historyStore.retrySave() }
              .frame(minHeight: 44)
              .accessibilityIdentifier("retryNapHistorySave")
          }
          if run.hasActiveRun
            || (run.phase != .idle
              && (isHome || run.lastRunPlanID == reviewState.confirmed?.plan.id))
          {
            runContent(run.presentationPlan)
          } else if let loadError {
            ContentUnavailableView(
              "Content unavailable", systemImage: "book.closed", description: Text(loadError)
            )
            .accessibilityIdentifier("napPlanCatalogError")
          } else if let catalog, let reviewCatalog {
            if let confirmed = reviewState.confirmed {
              confirmedContent(confirmed)
            } else if let reviewed = reviewState.reviewed {
              reviewContent(reviewed)
            } else {
              choices(catalog, reviewCatalog: reviewCatalog)
            }
          } else {
            ProgressView("Loading prepared content")
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RestStyle.pageInset)
      }
      .onChange(of: reviewState.reviewed?.plan.id) { _, _ in proxy.scrollTo("planTop", anchor: .top)
      }
      .onChange(of: reviewState.confirmed?.plan.id) { _, _ in
        proxy.scrollTo("planTop", anchor: .top)
      }
      .onChange(of: run.phase) { _, _ in proxy.scrollTo("planTop", anchor: .top) }
    }
    .safeAreaInset(edge: .bottom) {
      if !run.hasActiveRun, !(isHome && run.phase != .idle), reviewState.reviewed == nil,
        reviewState.confirmed == nil, let catalog, let reviewCatalog
      {
        reviewButton(catalog: catalog, reviewCatalog: reviewCatalog)
          .padding(.horizontal, RestStyle.pageInset)
          .padding(.vertical, 12)
          .background(RestStyle.background)
      }
    }
    .restScreen()
    .navigationTitle(isHome ? "Honkshool" : "Nap Plan")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      isVisible = true
      clearConsumedReviewIfNeeded()
    }
    .onChange(of: run.lastRunPlanID) { _, _ in clearConsumedReviewIfNeeded() }
    .onDisappear { isVisible = false }
    .task {
      guard catalog == nil && loadError == nil else { return }
      do {
        let loaded = try loadCatalog()
        let playable = try loaded.reviewCatalog(isNarrationAvailable: isNarrationAvailable)
        reviewCatalog = playable
        catalog = loaded
        seedSelection(in: loaded, reviewCatalog: playable)
      } catch {
        loadError = "The prepared catalog could not be loaded. \(error.localizedDescription)"
      }
    }
  }

  private func choices(_ catalog: PreparedCatalog, reviewCatalog: NapCatalog) -> some View {
    let options = sessionOptions(in: catalog, reviewCatalog: reviewCatalog)
    return VStack(alignment: .leading, spacing: 20) {
      HStack(alignment: .top) {
        RestHeading("A little time\nto drift.")
        Spacer(minLength: 12)
        GooseMark()
      }
      if alarm.hasTrackedAlarm { trackedAlarmContent }
      RestCard(title: selectedResumePoint == nil ? "Your selected session" : "Ready to continue") {
        if options.isEmpty {
          Text("No prepared sessions are available for planning.")
        } else if options.indices.contains(selectionIndex) {
          let selected = options[selectionIndex]
          Text(selected.session.title)
            .font(.system(.title2, design: .rounded).weight(.medium))
          Text(selected.journey.title)
            .foregroundStyle(RestStyle.secondary)
          if let selectedResumePoint {
            Text(
              "Resume at \(ListeningHistoryView.position(selectedResumePoint)); about \(ListeningHistoryView.duration(selectedResumePoint.estimatedRemainingDuration)) of narration remains."
            )
            .font(.subheadline)
            .accessibilityIdentifier("napPlanResumePosition")
            Button("Start this session over") {
              self.selectedResumePoint = nil
              invalidateReview()
            }
            .frame(minHeight: 44)
            .accessibilityIdentifier("napPlanStartOver")
          }
          Menu {
            Picker(
              "Change session",
              selection: Binding(
                get: { selectionIndex },
                set: { index in
                  selectionIndex = index
                  selectedResumePoint = nil
                  seedError = nil
                  shorterIndices.removeAll()
                  invalidateReview()
                })
            ) {
              ForEach(options.indices, id: \.self) { index in
                Text("\(options[index].journey.title) · \(options[index].session.title)").tag(index)
              }
            }

          } label: {
            Label("Change session", systemImage: "chevron.down")
              .frame(minHeight: 44)
          }
          .accessibilityIdentifier("napPlanContent")
          Button("About this session") { showsSessionDetail = true }
            .frame(minHeight: 44)
            .accessibilityIdentifier("napPlanSessionDetail")
            .sheet(isPresented: $showsSessionDetail) {
              if let prepared = catalog.sessions[selected.session.id] {
                SessionDetailView(prepared: prepared, journey: selected.journey)
              }
            }
        }
        if let seedError {
          Label(seedError, systemImage: "exclamationmark.circle")
            .foregroundStyle(RestStyle.error)
            .accessibilityIdentifier("napPlanSeedError")
          Button("Start current session from beginning") {
            selectedResumePoint = nil
            self.seedError = nil
            invalidateReview()
          }
          .frame(minHeight: 44)
          .accessibilityIdentifier("napPlanClearSeedError")
        }
      }

      RestCard {
        if !usesExactWakeTime {
          Picker("Time to rest", selection: $durationMinutes) {
            ForEach([5, 10, 20, 30, 45, 60], id: \.self) { minutes in
              Text("\(minutes) minutes").tag(minutes)
            }
            if ![5, 10, 20, 30, 45, 60].contains(durationMinutes) {
              Text("\(durationMinutes) minutes").tag(durationMinutes)
            }
          }
          .pickerStyle(.menu)
          .accessibilityIdentifier("napPlanDuration")
          LazyVGrid(columns: [GridItem(.adaptive(minimum: 54))], spacing: 8) {
            ForEach(RestDurationPolicy.recommendedMinutes, id: \.self) { minutes in
              Button {
                durationMinutes = minutes
              } label: {
                Text("\(minutes)")
                  .frame(maxWidth: .infinity, minHeight: 44)
                  .background(
                    durationMinutes == minutes ? RestStyle.quiet : RestStyle.well,
                    in: RoundedRectangle(cornerRadius: 12))
              }
              .accessibilityLabel("\(minutes) minutes")
              .accessibilityIdentifier("napPlanPreset-\(minutes)")
              .accessibilityAddTraits(durationMinutes == minutes ? .isSelected : [])
            }
          }
        }
        Button {
          showsTimeOptions.toggle()
        } label: {
          HStack {
            Text("More time options")
            Spacer()
            Image(systemName: showsTimeOptions ? "chevron.up" : "chevron.down")
          }.frame(minHeight: 44)
        }
        .accessibilityValue(showsTimeOptions ? "Expanded" : "Collapsed")
        .accessibilityIdentifier("napPlanTimeOptions")
        if showsTimeOptions {
          VStack(alignment: .leading, spacing: 16) {
            Toggle("Choose an exact wake time", isOn: $usesExactWakeTime)
              .accessibilityIdentifier("napPlanUseExactWakeTime")
            if usesExactWakeTime {
              DatePicker(
                "Wake time", selection: $exactWakeTime,
                displayedComponents: [.date, .hourAndMinute]
              )
              .accessibilityLabel("Wake time")
              .accessibilityIdentifier("napPlanExactWakeTime")
            } else {
              Stepper("\(durationMinutes) minutes", value: $durationMinutes, in: 1...180)
                .accessibilityIdentifier("napPlanCustomDuration")
            }
            Text("This is a rest window, not a promise of sleep time.")
              .font(.footnote)
              .foregroundStyle(RestStyle.secondary)
          }
          .padding(.top, 12)
        }
      }

      RestCard {
        Picker("After narration", selection: $selectedSoundID) {
          Text("Silence").tag(String?.none)
          ForEach(availableAmbienceIDs.sorted(), id: \.self) { id in
            Text(PreparedAmbience.displayName(for: id)).tag(Optional(id))
          }
        }
        .pickerStyle(.menu)
        .accessibilityIdentifier("napPlanSound")
        Divider()
        Toggle("Wake alarm", isOn: $alarmEnabled)
          .accessibilityIdentifier("napPlanAlarm")
        if availableAmbienceIDs.isEmpty {
          Text("Gentle rain is unavailable on this device. This plan can still use silence.")
            .font(.footnote).foregroundStyle(RestStyle.secondary)
            .accessibilityIdentifier("napPlanSoundUnavailable")
        } else if selectedSoundID == PreparedAmbience.gentleRainID {
          Text(
            "Rain fills quiet parts of your plan. If it becomes unavailable, rest continues in silence."
          )
          .font(.footnote).foregroundStyle(RestStyle.secondary)
          .accessibilityIdentifier("napPlanSoundFallbackDisclosure")
        }
      }

      if let selected = options.indices.contains(selectionIndex) ? options[selectionIndex] : nil {
        let shorter = options.indices.filter {
          $0 != selectionIndex
            && options[$0].session.estimatedDuration
              < (selectedResumePoint?.estimatedRemainingDuration
                ?? selected.session.estimatedDuration)
        }
        if !shorter.isEmpty {
          RestCard {
            DisclosureGroup("Shorter alternatives") {
              VStack(alignment: .leading, spacing: 12) {
                Text("Only if your selected session won’t fit. Tried in this order.")
                  .font(.footnote).foregroundStyle(RestStyle.secondary)
                ForEach(shorter, id: \.self) { index in
                  Toggle(
                    options[index].session.title,
                    isOn: Binding(
                      get: { shorterIndices.contains(index) },
                      set: { enabled in
                        if enabled {
                          shorterIndices.insert(index)
                        } else {
                          shorterIndices.remove(index)
                        }
                        invalidateReview()
                      })
                  )
                  .accessibilityIdentifier("napPlanShorterOption-\(index)")
                }
              }.padding(.top, 12)
            }
          }
        }
      }
      let branching = catalog.journeys.filter { !$0.nextJourneyIDs.isEmpty }
      if !branching.isEmpty {
        RestCard(title: "Journey transitions") {
          Text("Only a transition approved here may follow a completed journey.")
            .font(.footnote).foregroundStyle(RestStyle.secondary)
          ForEach(branching, id: \.id) { journey in
            Picker(
              "After \(journey.title)",
              selection: Binding(
                get: { approvedNextJourney[journey.id] },
                set: {
                  approvedNextJourney[journey.id] = $0
                  invalidateReview()
                })
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
      if let reviewError { errorLabel(reviewError, id: "napPlanError") }
      if !canStart() {
        Text(
          "End the experimental audio and cancel its test alarm in Settings → Feasibility Lab before starting a rest."
        )
        .font(.footnote).foregroundStyle(RestStyle.secondary)
      }
    }
    .onChange(of: durationMinutes) { _, _ in invalidateReview() }
    .onChange(of: usesExactWakeTime) { _, _ in invalidateReview() }
    .onChange(of: exactWakeTime) { _, _ in invalidateReview() }
    .onChange(of: selectedSoundID) { _, _ in invalidateReview() }
    .onChange(of: alarmEnabled) { _, _ in invalidateReview() }
  }

  private func reviewButton(catalog: PreparedCatalog, reviewCatalog: NapCatalog) -> some View {
    let options = sessionOptions(in: catalog, reviewCatalog: reviewCatalog)
    return Button("Review nap plan") {
      review(catalog, reviewCatalog: reviewCatalog, options: options)
    }
    .buttonStyle(RestButtonStyle())
    .disabled(
      options.isEmpty || seedError != nil || alarm.hasTrackedAlarm || alarm.isScheduling
        || !canStart()
    )
    .accessibilityIdentifier("reviewNapPlan")
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
      startingAt: SessionSelection(
        journeyID: selected.journey.id, sessionID: selected.session.id,
        resumePoint: selectedResumePoint),
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
    VStack(alignment: .leading, spacing: 20) {
      Button {
        invalidateReview()
      } label: {
        Label("Your choices", systemImage: "chevron.left").frame(minHeight: 44)
      }
      .accessibilityIdentifier("editNapPlanChoices")
      RestHeading("Your nap plan")
      RestCard(title: "Rest ends at") {
        Text(review.plan.deadline.formatted(date: .omitted, time: .shortened))
          .font(.system(.largeTitle, design: .rounded).weight(.medium))
        LabeledContent("Fixed wake deadline") {
          Text(review.plan.deadline.formatted(date: .abbreviated, time: .standard))
        }
        .font(.footnote).foregroundStyle(RestStyle.secondary)
        .accessibilityIdentifier("napPlanDeadline")
        LabeledContent("Planned rest start") {
          Text(review.plan.start.formatted(date: .abbreviated, time: .standard))
        }
        .font(.subheadline)
        .accessibilityIdentifier("napPlanPlannedStart")
        LabeledContent(
          "Wake alarm",
          value: review.plan.wakeAlarm == nil ? "Not requested" : "Requested at deadline"
        )
        .font(.subheadline)
        .accessibilityIdentifier("napPlanAlarmChoice")
      }
      RestCard(title: "Your narration route") {
        if let point = review.route.first?.planned.resumePoint {
          Text(
            "Narration resumes at \(ListeningHistoryView.position(point)); about \(ListeningHistoryView.duration(point.estimatedRemainingDuration)) remains."
          )
          .font(.subheadline).foregroundStyle(RestStyle.secondary)
          .accessibilityIdentifier("napPlanReviewedResume")
        }
        if review.route.isEmpty {
          Text(
            "No narration fits this rest window. Rest continues with the selected sound through the fixed deadline."
          )
          .accessibilityIdentifier("napPlanNoContent")
        } else {
          ForEach(Array(review.route.enumerated()), id: \.offset) { index, item in
            HStack(alignment: .top, spacing: 12) {
              Text("\(index + 1)")
                .font(.caption).frame(width: 24, height: 24)
                .background(RestStyle.well, in: Circle())
              VStack(alignment: .leading, spacing: 6) {
                Text(item.planned.session.title)
                  .font(.system(.headline, design: .rounded).weight(.medium))
                Text(item.journeyTitle).font(.subheadline)
                Text(
                  "Estimated \(item.planned.estimatedStart.formatted(date: .omitted, time: .shortened))–\(item.planned.estimatedEnd.formatted(date: .omitted, time: .shortened))"
                )
                .font(.footnote)
              }
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("napPlanRouteItem-\(index)")
          }
        }
        if review.plan.usedShorterAlternative {
          Text("The selected session did not fit. A preapproved shorter session was chosen.")
            .font(.subheadline).accessibilityIdentifier("napPlanShorterSelection")
        }
        Text(endExplanation(review.plan))
          .font(.footnote).foregroundStyle(RestStyle.secondary)
          .accessibilityIdentifier("napPlanRouteEnd")
        Divider()
        LabeledContent("After narration", value: soundName(review.plan.fallback))
          .accessibilityIdentifier("napPlanPostNarrationSound")
        if review.plan.fallback == .ambience(id: PreparedAmbience.gentleRainID) {
          Text(
            "If rain becomes unavailable, rest continues in silence. Before playback starts, keep Honkshool open. A scheduled wake alarm stays active."
          )
          .font(.footnote).foregroundStyle(RestStyle.secondary)
          .accessibilityIdentifier("napPlanReviewedSoundFallback")
        }
        if review.requestedSound != review.plan.fallback {
          Text("Requested sound is unavailable; this plan uses silence.")
            .font(.footnote).accessibilityIdentifier("napPlanSoundFallback")
        }
        if !review.approvedTransitions.isEmpty {
          Text("Approved journey transitions").font(.subheadline.weight(.medium))
          ForEach(review.approvedTransitions.sorted { $0.from < $1.from }, id: \.from) { approval in
            let fromTitle = catalog?.planningCatalog.journeys[approval.from]?.title ?? approval.from
            let toTitle = catalog?.planningCatalog.journeys[approval.to]?.title ?? approval.to
            Text("\(fromTitle) → \(toTitle)").font(.subheadline)
          }
        }
      }
      Text(
        "Your ending time stays fixed. If playback stops early, we’ll save a verified position when possible."
      )
      .font(.subheadline)
      .padding(16).frame(maxWidth: .infinity, alignment: .leading)
      .background(RestStyle.quiet, in: RoundedRectangle(cornerRadius: 16))
      if let reviewError { errorLabel(reviewError, id: "napPlanError") }
      Button("Confirm this plan") { confirm() }
        .buttonStyle(RestButtonStyle())
        .accessibilityIdentifier("confirmNapPlan")
      Text("If the planned start passes, we’ll refresh the timing for another review.")
        .font(.footnote).foregroundStyle(RestStyle.secondary)
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
    VStack(alignment: .leading, spacing: 24) {
      GooseMark(size: 108).frame(maxWidth: .infinity).padding(.top, 24)
      RestHeading("Ready when\nyou are.")
      Text("Your approved route and fixed deadline are ready for a start request.")
        .foregroundStyle(RestStyle.secondary)
        .accessibilityIdentifier("napPlanConfirmation")
      RestCard(title: "Rest ends at") {
        deadlineText(confirmed.plan.deadline)
        confirmedTiming(confirmed.plan)
        LabeledContent("After narration", value: soundName(confirmed.plan.fallback))
          .accessibilityIdentifier("napPlanConfirmedSound")
        Text(
          confirmed.plan.wakeAlarm == nil
            ? "No wake alarm requested." : "We’ll verify your wake alarm before starting."
        )
        .font(.subheadline).foregroundStyle(RestStyle.secondary)
      }
      if let runError {
        errorLabel(runError, id: "napRunError")
        if alarm.authorization == .denied {
          Button("Open iPhone Settings") {
            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
          }
          .buttonStyle(RestButtonStyle(secondary: true))
          .accessibilityIdentifier("openAlarmSettings")
        }
      }
      if alarm.hasTrackedAlarm {
        trackedAlarmContent
      } else if runError == nil {
        Text(
          confirmed.plan.route.isEmpty && confirmed.plan.fallback == .silence
            ? "Keep Honkshool open until the resting state begins at the planned start. Then you can lock your phone."
            : "Keep Honkshool open until playback begins. Then you can lock your phone."
        )
        .font(.subheadline).foregroundStyle(RestStyle.secondary)
        Button("Start resting") { Task { await startConfirmed(confirmed) } }
          .buttonStyle(RestButtonStyle())
          .disabled(isStarting || alarm.isScheduling)
          .accessibilityIdentifier("startNapRun")
        if isStarting {
          ProgressView("Setting your wake alarm")
            .accessibilityIdentifier("napRunScheduling")
        }
      }
      Button("Review another plan") { resetPlan() }
        .frame(minHeight: 44)
        .disabled(isStarting || alarm.isScheduling)
        .accessibilityIdentifier("reviewAnotherNapPlan")
    }
  }

  private func runContent(_ plan: NapPlan?) -> some View {
    VStack(alignment: .leading, spacing: 24) {
      HStack {
        Text("Your rest").font(.headline.weight(.medium))
        Spacer()
        GooseMark()
      }
      VStack(alignment: .leading, spacing: 16) {
        RestHeading(runHeading)
        Text(run.statusMessage)
          .foregroundStyle(RestStyle.secondary)
          .accessibilityIdentifier("napRunStatus")
        if run.phase == .resting || run.phase == .ambience { ThoughtDots() }
      }
      .padding(.vertical, 24)
      if let plan {
        RestCard(title: run.hasActiveRun ? "Rest ends at" : "Planned ending time") {
          deadlineText(plan.deadline)
          confirmedTiming(plan)
          LabeledContent("After narration", value: soundName(plan.fallback))
            .font(.subheadline)
            .accessibilityIdentifier("napPlanConfirmedSound")
          Text(plan.wakeAlarm == nil ? "No wake alarm was requested." : alarm.statusMessage)
            .font(.subheadline).foregroundStyle(RestStyle.secondary)
            .accessibilityIdentifier("napPlanAlarmStatus")
        }
      }
      if run.canPause {
        Button("Pause playback", systemImage: "pause") { run.pause() }
          .buttonStyle(RestButtonStyle(secondary: true))
          .accessibilityIdentifier("pauseNapRun")
      } else if run.canResume {
        Button("Resume playback", systemImage: "play") { run.resume() }
          .buttonStyle(RestButtonStyle(secondary: true))
          .accessibilityIdentifier("resumeNapRun")
      }
      if run.hasActiveRun {
        Button("Stop playback") { run.stop() }
          .frame(minHeight: 44)
          .accessibilityIdentifier("stopNapRun")
        if plan?.wakeAlarm != nil {
          Text("Stopping playback does not cancel the wake alarm.")
            .font(.footnote).foregroundStyle(RestStyle.secondary)
        }
      } else {
        if !run.records.isEmpty {
          Text("Played through in this rest: \(run.records.filter(\.isCompleted).count) session(s)")
            .font(.subheadline).foregroundStyle(RestStyle.secondary)
            .accessibilityIdentifier("napRunCompletionCount")
        }
        if alarm.hasTrackedAlarm { trackedAlarmContent }
        Button("Plan another rest") { resetPlan() }
          .buttonStyle(RestButtonStyle(secondary: true))
          .accessibilityIdentifier("reviewAnotherNapPlan")
      }
    }
  }

  private var runHeading: String {
    switch run.phase {
    case .waiting: "Get comfortable."
    case .narrating: run.currentNarrationTitle ?? "A thought to follow."
    case .paused, .interrupted: "Take your time."
    case .ambience: "Let the rain stay."
    case .resting: "Nothing else to do."
    case .finished: "Take your time."
    case .stopped: "Another time is fine."
    case .failed: "A moment to reset."
    case .idle: "A little time to drift."
    }
  }

  private var trackedAlarmContent: some View {
    RestCard(title: "Your wake alarm", systemImage: "alarm") {
      Text(alarm.statusMessage)
        .accessibilityIdentifier("trackedNapPlanAlarmStatus")
      if let alert = alarm.alarmStatus.nextAlertDate {
        Text(alert.formatted(date: .abbreviated, time: .shortened))
          .font(.system(.title2, design: .rounded).weight(.medium))
      }
      if !run.hasActiveRun {
        Text("Cancel the existing alarm before making another plan.")
          .font(.subheadline).foregroundStyle(RestStyle.secondary)
          .accessibilityIdentifier("napRunPreviousAlarmGate")
        if alarm.canCancelTrackedAlarm {
          Button("Cancel wake alarm") {
            if !alarm.cancel() { runError = alarm.statusMessage }
          }
          .buttonStyle(RestButtonStyle(secondary: true))
          .disabled(alarm.isScheduling)
          .accessibilityIdentifier("cancelNapPlanAlarm")
        }
      }
    }
  }

  private func confirmedTiming(_ plan: NapPlan) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      LabeledContent("Fixed wake deadline") {
        Text(plan.deadline.formatted(date: .abbreviated, time: .standard))
      }
      .accessibilityIdentifier("napPlanConfirmedDeadline")
      LabeledContent("Planned rest start") {
        Text(plan.start.formatted(date: .abbreviated, time: .standard))
      }
      .accessibilityIdentifier("napPlanConfirmedStart")
    }
    .font(.footnote).foregroundStyle(RestStyle.secondary)
  }

  private func deadlineText(_ date: Date) -> some View {
    Text(date.formatted(date: .omitted, time: .shortened))
      .font(.system(.largeTitle, design: .rounded).weight(.medium))
      .monospacedDigit()
  }

  private func errorLabel(_ text: String, id: String) -> some View {
    Label(text, systemImage: "exclamationmark.circle")
      .foregroundStyle(RestStyle.error)
      .fixedSize(horizontal: false, vertical: true)
      .accessibilityIdentifier(id)
  }

  private func resetPlan() {
    run.resetPresentation()
    reviewState = NapPlanReviewState()
    startedPlanID = nil
    reviewError = nil
    runError = nil
    if isHome, let catalog, let reviewCatalog {
      seedSelection(in: catalog, reviewCatalog: reviewCatalog)
    }
  }

  private func clearConsumedReviewIfNeeded() {
    guard let startedPlanID, startedPlanID != run.lastRunPlanID else { return }
    // A different tab may reset a finished run. Its consumed confirmation must
    // never become a second Start request when this destination reappears.
    reviewState = NapPlanReviewState()
    self.startedPlanID = nil
    reviewError = nil
    runError = nil
  }

  private func seedSelection(in loaded: PreparedCatalog, reviewCatalog: NapCatalog) {
    let seed =
      initialSelection
      ?? (isHome
        ? ListeningHistoryNavigation.next(
          in: loaded, history: historyStore.history, isNarrationAvailable: isNarrationAvailable)
        : nil)
    guard let seed else { return }
    let options = sessionOptions(in: loaded, reviewCatalog: reviewCatalog)
    if let index = options.firstIndex(where: {
      $0.journey.id == seed.journeyID && $0.session.id == seed.sessionID
    }) {
      selectionIndex = index
      selectedResumePoint = nil
      seedError = nil
      if let point = seed.resumePoint {
        if let prepared = loaded.sessions[seed.sessionID],
          (try? prepared.validateAudioResumePoint(point)) != nil
        {
          selectedResumePoint = point
        } else {
          seedError =
            "The saved position no longer matches available audio. Choose current content and review a new plan."
        }
      }
    } else {
      seedError =
        "The requested session is no longer prepared or its audio is unavailable. Choose current content and review a new plan."
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
      startedPlanID = confirmed.plan.id
      runError = nil
    } catch let error as NapRunError {
      let message =
        switch error {
        case .staleStart: "The approved start passed. Review a new Nap Plan."
        case .alarmUnavailable: "The requested wake alarm is not verified for this plan."
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
    case .ambience(let id): PreparedAmbience.displayName(for: id)
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

}

private struct SessionOption {
  let journey: Journey
  let session: Session
}

/// Only the bundled, validated session metadata is presented here.
private struct SessionDetailView: View {
  let prepared: PreparedSession
  let journey: Journey
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          Text(journey.title).font(.subheadline).foregroundStyle(RestStyle.secondary)
          RestHeading(prepared.session.title, subtitle: prepared.summary)
          RestCard(title: "This session") {
            LabeledContent(
              "Narration", value: ListeningHistoryView.duration(prepared.session.estimatedDuration))
            LabeledContent("Detail", value: "Enthusiast")
            Label("Ready offline", systemImage: "checkmark")
          }
          RestCard(title: "Sources · for when you’re awake") {
            ForEach(prepared.sources, id: \.id) { source in
              Link(destination: source.url) {
                VStack(alignment: .leading, spacing: 6) {
                  Text(source.title).font(.headline.weight(.medium))
                  Label(source.publisher, systemImage: "arrow.up.right")
                    .font(.subheadline).foregroundStyle(RestStyle.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
              }
              .accessibilityHint("Opens this source in your browser")
            }
          }
          Text("You can leave this for tomorrow.")
            .font(.footnote).foregroundStyle(RestStyle.secondary)
        }
        .padding(RestStyle.pageInset)
      }
      .restScreen()
      .navigationTitle("About this session")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }.accessibilityIdentifier("dismissSessionDetail")
        }
      }
    }
  }
}
