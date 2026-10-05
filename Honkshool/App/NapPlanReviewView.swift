import SwiftUI

/// Review remains immutable; a separate controller executes the confirmed snapshot on request.
struct NapPlanReviewView: View {
  private static let plannedStartLead: TimeInterval = 60
  @Environment(\.openURL) private var openURL
  @Environment(\.dismiss) private var dismiss
  @Environment(\.scenePhase) private var scenePhase
  @ObservedObject private var run: NapRunController
  @ObservedObject private var alarm: NapPlanAlarmService
  @ObservedObject private var historyStore: ListeningHistoryStore
  private let isHome: Bool
  private let onShowHistory: () -> Void
  private let lockScreenTimerMessage: String?
  private let initialSelection: SessionSelection?
  private let canStart: () -> Bool
  private let clock: () -> Date
  private let confirmationClock: () -> Date
  private let makeID: () -> String
  private let loadCatalog: () throws -> PreparedCatalog
  private let isNarrationAvailable: (PreparedSession) -> Bool
  private let availableAmbienceIDs: Set<String>

  private enum SetupSheet: String, Identifiable {
    case sessions, detail, time, sound
    var id: String { rawValue }
  }
  @State private var activeSheet: SetupSheet?
  @State private var appliedDefaults: RestDefaults?
  @State private var dismissedCheckpointID: PlaybackRecord.ID?
  @State private var showsAlarmPrimer = false
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
  @State private var startFailure: NapRunError?
  @State private var startedPlanID: String?
  @State private var isStarting = false
  @State private var isVisible = false
  @State private var plansNarration = false
  @State private var timerStartID: UUID?
  @State private var pendingTimer: NapPlan?

  init(
    run: NapRunController,
    alarm: NapPlanAlarmService,
    historyStore: ListeningHistoryStore,
    startingAt initialSelection: SessionSelection? = nil,
    isHome: Bool = false,
    onShowHistory: @escaping () -> Void = {},
    lockScreenTimerMessage: String? = nil,
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
    self.onShowHistory = onShowHistory
    self.lockScreenTimerMessage = lockScreenTimerMessage
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
          } else if isHome && alarm.hasTrackedAlarm && reviewState.confirmed == nil && !isStarting {
            existingAlarmPage
          } else if isHome, run.phase == .idle, reviewState.reviewed == nil,
            let entry = recoveryEntry
          {
            checkpointRecovery(entry)
          } else if isHome && !plansNarration {
            timerChoices
          } else if let loadError {
            ContentUnavailableView(
              "Content unavailable", systemImage: "book.closed", description: Text(loadError)
            )
            .accessibilityIdentifier("napPlanCatalogError")
          } else if let catalog, let reviewCatalog {
            if let confirmed = reviewState.confirmed {
              if showsAlarmPrimer {
                alarmAccessContent(confirmed)
              } else {
                confirmedContent(confirmed)
              }
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
        .id("planTop")
      }
      .onChange(of: reviewState.reviewed?.plan.id) { _, _ in proxy.scrollTo("planTop", anchor: .top)
      }
      .onChange(of: reviewState.confirmed?.plan.id) { _, _ in
        proxy.scrollTo("planTop", anchor: .top)
      }
      .onChange(of: run.phase) { _, _ in proxy.scrollTo("planTop", anchor: .top) }
      .onChange(of: plansNarration) { _, _ in proxy.scrollTo("planTop", anchor: .top) }
      .onChange(of: runError) { _, _ in proxy.scrollTo("planTop", anchor: .top) }
    }
    .safeAreaInset(edge: .bottom) {
      if isHome, !plansNarration, run.phase == .idle,
        !alarm.hasTrackedAlarm || isStarting, recoveryEntry == nil
      {
        timerStartAction
          .padding(.horizontal, RestStyle.pageInset)
          .padding(.vertical, 12)
          .background(RestStyle.background)
      } else if !run.hasActiveRun, !(isHome && run.phase != .idle), reviewState.reviewed == nil,
        reviewState.confirmed == nil, !alarm.hasTrackedAlarm, recoveryEntry == nil, let catalog,
        let reviewCatalog
      {
        reviewButton(catalog: catalog, reviewCatalog: reviewCatalog)
          .padding(.horizontal, RestStyle.pageInset)
          .padding(.vertical, 12)
          .background(RestStyle.background)
      } else if !run.hasActiveRun, !(isHome && run.phase != .idle),
        let confirmed = reviewState.confirmed, run.lastRunPlanID != confirmed.plan.id,
        runError == nil, !showsAlarmPrimer, !alarm.hasTrackedAlarm
      {
        startRestAction(confirmed)
          .padding(.horizontal, RestStyle.pageInset)
          .padding(.vertical, 12)
          .background(RestStyle.background)
      }
    }
    .restScreen()
    .labeledContentStyle(RestLabeledContentStyle())
    .navigationTitle(isHome ? "Honkshool" : "Nap Plan")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        if isHome, plansNarration, reviewState.reviewed == nil, run.phase == .idle {
          Button("Nap timer", systemImage: "chevron.left") {
            plansNarration = false
            runError = nil
          }
          .accessibilityIdentifier("showNapTimer")
        }
      }
    }
    .onAppear {
      isVisible = true
      clearConsumedReviewIfNeeded()
      applyChangedDefaults()
    }
    .onChange(of: run.lastRunPlanID) { _, _ in clearConsumedReviewIfNeeded() }
    .onDisappear {
      isVisible = false
      timerStartID = nil
    }
    .onChange(of: scenePhase) { _, phase in
      if phase == .background { timerStartID = nil }
    }
    .sheet(item: $activeSheet) { sheet in
      NavigationStack { setupSheet(sheet) }
        .presentationDragIndicator(.visible)
    }
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

  @ViewBuilder private func setupSheet(_ sheet: SetupSheet) -> some View {
    switch sheet {
    case .time:
      RestTimeSheet(
        initial: .init(
          minutes: durationMinutes, usesExactWakeTime: usesExactWakeTime, wakeTime: exactWakeTime)
      ) { choices in
        durationMinutes = choices.minutes
        usesExactWakeTime = choices.usesExactWakeTime
        exactWakeTime = choices.wakeTime
        invalidateReview()
      }
    case .sound:
      RestSoundSheet(selectedID: selectedSoundID, availableIDs: availableAmbienceIDs) { sound in
        selectedSoundID = sound
        invalidateReview()
      }
    case .sessions:
      if let catalog {
        RestSessionPickerView(
          catalog: catalog, historyStore: historyStore,
          isAvailable: isNarrationAvailable, onChoose: chooseSession
        )
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Done") { activeSheet = nil }.accessibilityIdentifier("dismissSessionPicker")
          }
        }
      }
    case .detail:
      if let catalog, let reviewCatalog {
        let options = sessionOptions(in: catalog, reviewCatalog: reviewCatalog)
        if options.indices.contains(selectionIndex),
          let prepared = catalog.sessions[options[selectionIndex].session.id]
        {
          RestSessionDetailView(
            prepared: prepared, journey: options[selectionIndex].journey,
            resumePoint: historyStore.errorMessage == nil ? selectedResumePoint : nil,
            isAvailable: isNarrationAvailable(prepared),
            onChoose: chooseSession
          )
          .toolbar {
            ToolbarItem(placement: .confirmationAction) {
              Button("Done") { activeSheet = nil }.accessibilityIdentifier("dismissSessionDetail")
            }
          }
        }
      }
    }
  }

  private func chooseSession(_ selection: SessionSelection) {
    guard selection.resumePoint == nil || historyStore.errorMessage == nil else { return }
    guard let catalog, let reviewCatalog else { return }
    let options = sessionOptions(in: catalog, reviewCatalog: reviewCatalog)
    guard
      let index = options.firstIndex(where: {
        $0.journey.id == selection.journeyID && $0.session.id == selection.sessionID
      }),
      let prepared = catalog.sessions[selection.sessionID], isNarrationAvailable(prepared)
    else { return }
    if let point = selection.resumePoint, (try? prepared.validateAudioResumePoint(point)) == nil {
      return
    }
    selectionIndex = index
    selectedResumePoint = selection.resumePoint
    seedError = nil
    shorterIndices.removeAll()
    approvedNextJourney.removeAll()
    invalidateReview()
    activeSheet = nil
  }

  private func applyChangedDefaults(force: Bool = false) {
    guard !run.hasActiveRun, reviewState.confirmed == nil, reviewState.reviewed == nil else {
      return
    }
    let defaults = RestPreferences.load(
      defaults: SpikePreferences.defaults, availableAmbienceIDs: availableAmbienceIDs)
    guard force || appliedDefaults != defaults else { return }
    appliedDefaults = defaults
    durationMinutes = defaults.durationMinutes
    selectedSoundID = defaults.soundID
    alarmEnabled = defaults.wakeAlarm
    usesExactWakeTime = false
  }

  private var timerChoices: some View {
    VStack(alignment: .leading, spacing: 20) {
      RestHeading("Time for a nap.")
      if let runError { errorLabel(runError, id: "timerStartError") }
      if alarm.authorization == .denied, alarmEnabled {
        Text("Allow alarms in iPhone Settings, or turn Wake alarm off to rest without one.")
          .foregroundStyle(RestStyle.secondary)
        Button("Open iPhone Settings") {
          if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
        }.frame(minHeight: 44).accessibilityIdentifier("openAlarmSettings")
      }
      RestTimerChoices(
        minutes: $durationMinutes, usesExactWakeTime: $usesExactWakeTime,
        wakeTime: $exactWakeTime, soundID: $selectedSoundID, alarmEnabled: $alarmEnabled,
        availableIDs: availableAmbienceIDs
      )
      .disabled(isStarting)
      if let pendingTimer, isStarting {
        RestTimingRow(title: "Rest ends at", date: pendingTimer.deadline)
          .accessibilityIdentifier("timerPendingDeadline")
      }
      if !canStart() {
        Text(
          "End the experimental audio and cancel its test alarm in Settings → Advanced → Feasibility Lab before starting a rest."
        )
        .foregroundStyle(RestStyle.secondary)
      }
      Button("Plan a narrated rest", systemImage: "book.closed") {
        plansNarration = true
        runError = nil
      }
      .frame(minHeight: 44)
      .disabled(isStarting)
      .accessibilityIdentifier("planNarratedRest")
    }
  }

  private var timerStartAction: some View {
    VStack(spacing: 8) {
      if isStarting {
        Text(pendingTimer == nil ? "Preparing your rest…" : "Verifying your wake alarm…")
          .font(.subheadline).foregroundStyle(RestStyle.secondary)
          .accessibilityIdentifier("timerPreparing")
      }
      Button("Start resting") { Task { await startTimer() } }
        .buttonStyle(RestButtonStyle())
        .disabled(isStarting || alarm.isScheduling || !canStart())
        .accessibilityIdentifier("startRestTimer")
    }
  }

  private func startTimer() async {
    guard !isStarting, !alarm.isScheduling, !alarm.hasTrackedAlarm, !run.hasActiveRun,
      canStart(), isVisible, scenePhase == .active
    else { return }
    // Snapshot the explicit choices before any system permission or scheduling await.
    let window: NapWindow =
      usesExactWakeTime
      ? .wakeTime(exactWakeTime) : .duration(TimeInterval(durationMinutes * 60))
    let sound = selectedSoundID.map(RestSound.ambience(id:)) ?? .silence
    let requestsAlarm = alarmEnabled
    let requestID = UUID()
    timerStartID = requestID
    isStarting = true
    runError = nil
    pendingTimer = nil
    defer {
      isStarting = false
      timerStartID = nil
    }
    if requestsAlarm, !(await alarm.authorize()) {
      runError = "Your wake alarm isn’t set. Playback hasn’t started. \(alarm.statusMessage)"
      return
    }
    guard timerStartIsCurrent(requestID) else {
      runError = "Rest hasn’t started. Return to this screen and tap Start resting when ready."
      return
    }
    do {
      // Permission time does not consume the requested duration. From here, the deadline is fixed.
      let plan = try NapPlanner.makeTimer(
        id: makeID(), window: window, sound: sound, alarmEnabled: requestsAlarm,
        now: .now, availableAmbienceIDs: availableAmbienceIDs)
      pendingTimer = plan
      var receipt: ScheduledNapAlarm?
      if requestsAlarm {
        guard let scheduled = await alarm.schedule(for: plan), alarm.isScheduled(scheduled) else {
          runError = "Playback hasn’t started. \(alarm.statusMessage)"
          return
        }
        receipt = scheduled
      }
      guard timerStartIsCurrent(requestID) else {
        runError =
          requestsAlarm
          ? "Playback hasn’t started. The wake alarm remains tracked; cancel it separately if needed."
          : "Rest hasn’t started. Tap Start resting when ready."
        return
      }
      try run.startTimer(plan: plan, scheduledAlarm: receipt)
      pendingTimer = nil
    } catch {
      let reason =
        (error as? NapRunError) == .staleStart
        ? "Setup took too long. Start a new timer when ready."
        : (error is NapDomainError)
          ? "Choose a duration or wake time in the future."
          : "Audio could not start. Check your output and try again."
      runError =
        "Rest hasn’t started. \(reason)"
        + (alarm.hasTrackedAlarm ? " Cancel the tracked wake alarm before trying again." : "")
    }
  }

  private func timerStartIsCurrent(_ id: UUID) -> Bool {
    timerStartID == id && isVisible && scenePhase == .active && canStart() && !run.hasActiveRun
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
      RestCard(title: selectedResumePoint == nil ? "Ready for a rest" : "Ready to continue") {
        if options.isEmpty {
          Text("No prepared sessions are available for planning.")
        } else if options.indices.contains(selectionIndex) {
          let selected = options[selectionIndex]
          VStack(alignment: .leading, spacing: 6) {
            Text(selected.session.title)
              .font(.system(.headline, design: .rounded).weight(.medium))
            Text(selected.journey.title)
              .font(.subheadline).foregroundStyle(RestStyle.secondary)
            if let selectedResumePoint {
              Text(
                "Resume at \(ListeningHistoryView.position(selectedResumePoint)) · About \(ListeningHistoryView.duration(selectedResumePoint.estimatedRemainingDuration)) left"
              )
              .font(.subheadline).foregroundStyle(RestStyle.secondary)
              .accessibilityIdentifier("napPlanResumePosition")
            }
          }
          HStack {
            Button("Change session") { activeSheet = .sessions }
              .frame(minHeight: 44).accessibilityIdentifier("napPlanContent")
            Spacer()
            Button {
              activeSheet = .detail
            } label: {
              Image(systemName: "info.circle").frame(width: 44, height: 44)
            }
            .accessibilityLabel("About this session")
            .accessibilityIdentifier("napPlanSessionDetail")
          }
          if selectedResumePoint != nil {
            Button("Start this session over") {
              selectedResumePoint = nil
              invalidateReview()
            }.frame(minHeight: 44).accessibilityIdentifier("napPlanStartOver")
          }
        }
        if let seedError {
          Label(seedError, systemImage: "exclamationmark.circle")
            .foregroundStyle(RestStyle.error).accessibilityIdentifier("napPlanSeedError")
          Button("Start current session from beginning") {
            selectedResumePoint = nil
            self.seedError = nil
            invalidateReview()
          }.frame(minHeight: 44).accessibilityIdentifier("napPlanClearSeedError")
        }
      }
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text(usesExactWakeTime ? "Rest until" : "Time to rest · minutes")
            .font(.subheadline).foregroundStyle(RestStyle.secondary)
          Spacer()
          Button("More options") { activeSheet = .time }
            .font(.subheadline).frame(minHeight: 44)
            .accessibilityIdentifier("napPlanTimeOptions")
        }
        if usesExactWakeTime {
          Text(exactWakeTime.formatted(date: .abbreviated, time: .shortened))
            .accessibilityIdentifier("napPlanTimeSummary")
        } else {
          RestDurationChoices(minutes: $durationMinutes)
          if !RestDurationPolicy.recommendedMinutes.contains(durationMinutes) {
            Text("\(durationMinutes) minutes").font(.subheadline)
              .accessibilityIdentifier("napPlanTimeSummary")
          }
        }
      }
      RestCard {
        Button {
          activeSheet = .sound
        } label: {
          HStack {
            Text("After narration")
            Spacer()
            Text(soundName(selectedSoundID.map(RestSound.ambience(id:)) ?? .silence))
              .foregroundStyle(RestStyle.secondary)
            Image(systemName: "chevron.right").font(.caption)
          }.frame(minHeight: 44)
        }.accessibilityIdentifier("napPlanSound")
        Divider()
        Toggle(isOn: $alarmEnabled) {
          HStack {
            Text("Wake alarm")
            Spacer(minLength: 8)
            Text(alarmEnabled ? "On" : "Off")
              .foregroundStyle(RestStyle.secondary)
              .accessibilityHidden(true)
          }
        }
        .tint(RestStyle.accent)
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
                  .tint(RestStyle.accent)
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
          "End the experimental audio and cancel its test alarm in Settings → Advanced → Feasibility Lab before starting a rest."
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
      RestHeading(review.route.isEmpty ? "A little quiet\nis enough." : "Your nap plan")
      RestCard(title: "Rest ends at") {
        Text(review.plan.deadline.formatted(date: .omitted, time: .shortened))
          .font(.system(.largeTitle, design: .rounded).weight(.medium))
        RestTimingRow(title: "Fixed wake deadline", date: review.plan.deadline)
          .font(.footnote).foregroundStyle(RestStyle.secondary)
          .accessibilityIdentifier("napPlanDeadline")
        RestTimingRow(title: "Planned rest start", date: review.plan.start)
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
      Button(review.route.isEmpty ? "Confirm quiet plan" : "Confirm this plan") { confirm() }
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

  @ViewBuilder private func confirmedContent(_ confirmed: NapPlanReview) -> some View {
    if let runError {
      blockedStartContent(confirmed, message: runError)
    } else {
      VStack(alignment: .leading, spacing: 24) {
        GooseMark(size: 84).frame(maxWidth: .infinity).padding(.vertical, 8)
        RestHeading("Ready when\nyou are.")
        Text("Your plan is ready. Start when you’re comfortable.")
          .foregroundStyle(RestStyle.secondary).accessibilityIdentifier("napPlanConfirmation")
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
        if alarm.hasTrackedAlarm {
          trackedAlarmContent
        } else {
          Text(
            confirmed.plan.route.isEmpty && confirmed.plan.fallback == .silence
              ? "Keep Honkshool open until the resting state begins at the planned start. Then you can lock your phone."
              : "Keep Honkshool open until playback begins. Then you can lock your phone."
          )
          .font(.subheadline).foregroundStyle(RestStyle.secondary)
        }
        Button("Change your plan") { resetPlan() }
          .frame(minHeight: 44).disabled(isStarting || alarm.isScheduling)
          .accessibilityIdentifier("reviewAnotherNapPlan")
      }
    }
  }

  private func startRestAction(_ confirmed: NapPlanReview) -> some View {
    VStack(spacing: 8) {
      Button("Start resting") {
        if confirmed.plan.wakeAlarm != nil && alarm.authorization == .notDetermined {
          showsAlarmPrimer = true
        } else {
          Task { await startConfirmed(confirmed) }
        }
      }
      .buttonStyle(RestButtonStyle())
      .disabled(isStarting || alarm.isScheduling).accessibilityIdentifier("startNapRun")
      if isStarting {
        ProgressView("Setting your wake alarm").accessibilityIdentifier("napRunScheduling")
      }
    }
  }

  private func alarmAccessContent(_ confirmed: NapPlanReview) -> some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("Before you settle in").font(.subheadline).foregroundStyle(RestStyle.secondary)
      RestHeading(
        "A wake-up\nyou’ve chosen.",
        subtitle:
          "Allow Honkshool to set the wake alarm in your plan. iPhone will ask for alarm access next."
      )
      RestCard(title: "Requested alarm") {
        deadlineText(confirmed.plan.deadline)
        Text("We’ll check that it’s set before narration starts.").foregroundStyle(
          RestStyle.secondary)
      }
      Button("Continue to alarm access") {
        showsAlarmPrimer = false
        Task { await startConfirmed(confirmed) }
      }
      .buttonStyle(RestButtonStyle()).accessibilityIdentifier("continueAlarmAccess")
      Button("Go back to your choices") { resetPlan() }
        .frame(minHeight: 44).accessibilityIdentifier("cancelAlarmAccess")
    }
  }

  private func blockedStartContent(_ confirmed: NapPlanReview, message: String) -> some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("Playback hasn’t started").font(.subheadline).foregroundStyle(RestStyle.secondary)
      RestHeading(
        startFailure == .staleStart
          ? "Let’s check the\ntiming again."
          : alarm.authorization == .denied
            ? "Your wake alarm\nisn’t set." : "A moment before\nyou rest.")
      RestCard {
        Text(message).accessibilityIdentifier("napRunError")
        if alarm.authorization == .denied {
          Text("Allow alarms for Honkshool in iPhone Settings, then try again.")
            .foregroundStyle(RestStyle.secondary)
          Button("Open iPhone Settings") {
            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
          }.buttonStyle(RestButtonStyle()).accessibilityIdentifier("openAlarmSettings")
        }
      }
      if alarm.hasTrackedAlarm {
        trackedAlarmContent
      } else if startFailure != .staleStart {
        Button("Try again") {
          runError = nil
          Task { await startConfirmed(confirmed) }
        }
        .buttonStyle(RestButtonStyle(secondary: true))
        .disabled(isStarting || alarm.isScheduling).accessibilityIdentifier("retryNapStart")
      }
      Button(startFailure == .staleStart ? "Update your nap plan" : "Change your plan") {
        resetPlan()
      }
      .buttonStyle(RestButtonStyle(secondary: true))
      .disabled(isStarting || alarm.isScheduling).accessibilityIdentifier("reviewAnotherNapPlan")
      Text("Changes to the route, timing, or wake alarm need a fresh review.")
        .font(.footnote).foregroundStyle(RestStyle.secondary)
    }
  }

  private var recoveryEntry: ListeningHistoryEntry? {
    guard isHome, run.phase == .idle, let latest = historyStore.entries.first,
      latest.isCheckpoint, latest.id != dismissedCheckpointID
    else { return nil }
    return latest
  }

  private func checkpointRecovery(_ entry: ListeningHistoryEntry) -> some View {
    VStack(alignment: .leading, spacing: 24) {
      RestHeading(
        "Welcome back.", subtitle: "A final listening update wasn’t saved. No audio has restarted.")
      RestCard(title: "Last verified checkpoint") {
        Text(entry.record.plannedSession.session.title).font(.system(.title2, design: .rounded))
        Text(ListeningHistoryView.position(entry.record.resumePoint)).font(.title.monospacedDigit())
        Text("Saved at \(entry.record.endedAt.formatted(date: .abbreviated, time: .shortened))")
          .foregroundStyle(RestStyle.secondary)
        Text(
          "Playback may have continued a little further. Your history keeps the verified position."
        )
        .font(.subheadline).foregroundStyle(RestStyle.secondary)
      }
      Button("Plan another rest") {
        dismissedCheckpointID = entry.id
        if let catalog, let reviewCatalog {
          seedSelection(in: catalog, reviewCatalog: reviewCatalog)
        }
      }.buttonStyle(RestButtonStyle()).accessibilityIdentifier("acknowledgeRecoveredRest")
      historyButton
    }
  }

  private var existingAlarmPage: some View {
    VStack(alignment: .leading, spacing: 24) {
      RestHeading(
        alarm.alarmStatus.phase == .unavailable
          ? "Check your\nwake alarm." : "Your alarm\nis still set.",
        subtitle: alarm.alarmStatus.phase == .unavailable
          ? "The alarm could not be verified. Cancel it before starting another rest."
          : "Your earlier wake alarm remains separate from playback.")
      if let runError { errorLabel(runError, id: "timerStartError") }
      trackedAlarmContent
      Text("Your listening history is ready for another time.").foregroundStyle(RestStyle.secondary)
      historyButton
    }
  }

  private var historyButton: some View {
    Button("View listening history") {
      if !isHome { dismiss() }
      onShowHistory()
    }.frame(minHeight: 44).accessibilityIdentifier("viewRestHistory")
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
          LabeledContent(
            plan.isTimer ? "Rest sound" : "After narration", value: soundName(plan.fallback)
          )
          .font(.subheadline)
          .accessibilityIdentifier("napPlanConfirmedSound")
          Text(plan.wakeAlarm == nil ? "No wake alarm was requested." : alarm.statusMessage)
            .font(.subheadline).foregroundStyle(RestStyle.secondary)
            .accessibilityIdentifier("napPlanAlarmStatus")
          if let lockScreenTimerMessage {
            Text(lockScreenTimerMessage)
              .font(.footnote).foregroundStyle(RestStyle.secondary)
              .accessibilityIdentifier("restActivityAvailability")
          }
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
          RestCard(title: "This rest") {
            ForEach(Array(run.records.enumerated()), id: \.offset) { _, record in
              VStack(alignment: .leading, spacing: 6) {
                Text(record.plannedSession.session.title).font(.headline.weight(.medium))
                Text(record.isCompleted ? "Played through" : "Partly played")
                  .foregroundStyle(RestStyle.secondary)
              }
            }
            Text(
              "Played through in this rest: \(run.records.filter(\.isCompleted).count) session(s)"
            )
            .font(.footnote).foregroundStyle(RestStyle.secondary)
            .accessibilityIdentifier("napRunCompletionCount")
          }
        }
        if alarm.hasTrackedAlarm { trackedAlarmContent }
        Button(alarm.hasTrackedAlarm ? "Keep alarm · return to Rest" : "Back to Rest") {
          resetPlan()
        }
        .buttonStyle(RestButtonStyle(secondary: true))
        .accessibilityIdentifier("reviewAnotherNapPlan")
        historyButton
      }
    }
  }

  private var runHeading: String {
    switch run.phase {
    case .waiting: "Get comfortable."
    case .narrating: run.currentNarrationTitle ?? "A thought to follow."
    case .paused, .interrupted: "A moment of quiet."
    case .ambience: "Let the rain stay."
    case .resting: "Nothing else to do."
    case .finished: "Take your time."
    case .stopped: "Pick it up\nanother time."
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
            if alarm.cancel() {
              if isHome && !plansNarration {
                runError = nil
                pendingTimer = nil
              }
            } else {
              runError = alarm.statusMessage
            }
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
      RestTimingRow(title: "Fixed wake deadline", date: plan.deadline)
        .accessibilityIdentifier("napPlanConfirmedDeadline")
      if !plan.isTimer {
        RestTimingRow(title: "Planned rest start", date: plan.start)
          .accessibilityIdentifier("napPlanConfirmedStart")
      }
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
    plansNarration = false
    pendingTimer = nil
    reviewState = NapPlanReviewState()
    startedPlanID = nil
    reviewError = nil
    runError = nil
    showsAlarmPrimer = false
    startFailure = nil
    applyChangedDefaults(force: true)
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
    startFailure = nil
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
      startFailure = error
      let message =
        switch error {
        case .staleStart: "The approved start passed. Review a new Nap Plan."
        case .alarmUnavailable: "The requested wake alarm is not verified for this plan."
        case .contentUnavailable: "The approved narration is unavailable. Review a new plan."
        case .invalidCheckpoint: "The approved audio checkpoint is unavailable. Review a new plan."
        case .audioUnavailable: "Audio could not start. Review a new plan after checking output."
        case .alreadyRunning: "A Nap Plan is already running."
        case .invalidTimerPlan: "This timer needs new choices before it can start."
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
