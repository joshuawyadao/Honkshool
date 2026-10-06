import SwiftUI

struct FeasibilityConsoleView: View {
  private enum Tab: Hashable { case rest, history }
  @Environment(\.scenePhase) private var scenePhase
  @StateObject private var audio = AudioSpikeController()
  @StateObject private var alarm = AlarmSpikeService()
  @StateObject private var napRun: NapRunController
  @StateObject private var napAlarm: NapPlanAlarmService
  @StateObject private var restActivity: RestActivityCoordinator
  @StateObject private var historyStore: ListeningHistoryStore

  init() {
    #if DEBUG
      let store = UITestFixtures.makeHistoryStore()
    #else
      let store = ListeningHistoryStore()
    #endif
    let run = NapRunController(history: store)
    let napAlarm = NapPlanAlarmService()
    _historyStore = StateObject(wrappedValue: store)
    _napRun = StateObject(wrappedValue: run)
    _napAlarm = StateObject(wrappedValue: napAlarm)
    _restActivity = StateObject(wrappedValue: RestActivityCoordinator(run: run, alarm: napAlarm))
  }

  @AppStorage("preferredRestMinutes", store: SpikePreferences.defaults)
  private var preferredRestMinutes = RestDurationPolicy.initialSavedMinutes

  @State private var selectedMinutes = RestDurationPolicy.initialSavedMinutes
  @State private var customMinutes = RestDurationPolicy.initialSavedMinutes
  @State private var exactWakeTime = Date.now.addingTimeInterval(
    TimeInterval(RestDurationPolicy.initialSavedMinutes * 60)
  )
  @State private var usesExactWakeTime = false
  @State private var alarmEnabled = true
  @State private var ambienceEnabled = true
  @State private var runMessage = "Configure the test, then start with the screen unlocked."
  @State private var blockedReason: String?
  @State private var isStarting = false
  @State private var runWakeDate: Date?
  @State private var loadedPreferences = false
  @State private var selectedTab: Tab = .rest
  @State private var showingSettings = false
  @State private var browsingCatalog: PreparedCatalog?
  @State private var browsingError: String?
  @State private var settingsDefaults = RestDefaults.initial
  @State private var showingWelcome = false
  @State private var evaluatedWelcome = false
  @AppStorage("hasSeenQuietWelcome", store: SpikePreferences.defaults)
  private var hasSeenQuietWelcome = false

  var body: some View {
    TabView(selection: $selectedTab) {
      NavigationStack {
        reviewView(startingAt: nil, isHome: true)
          .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
              Button {
                showingSettings = true
              } label: {
                Label("Settings", systemImage: "gearshape")
              }
              .accessibilityIdentifier("openSettings")
            }
          }
          .navigationDestination(isPresented: $showingSettings) {
            settingsScreen
          }
      }
      .tabItem { Label("Rest", systemImage: "moon") }
      .tag(Tab.rest)
      .accessibilityIdentifier("restTab")

      NavigationStack {
        historyScreen
      }
      .tabItem { Label("History", systemImage: "book.closed") }
      .tag(Tab.history)
      .accessibilityIdentifier("historyTab")
    }
    .tint(RestStyle.ink)
    .fullScreenCover(isPresented: $showingWelcome) {
      welcomeScreen
    }
    .task { await alarm.observeUpdates() }
    .task { await napAlarm.observeUpdates() }
    .task(id: scenePhase) {
      guard scenePhase == .active else { return }
      alarm.refresh()
      napAlarm.refresh()
      restActivity.reconcile()
    }
    .onChange(of: scenePhase) { _, next in
      napRun.scenePhaseChanged(isActive: next == .active)
    }
    .task(id: scenePhase == .active && alarm.needsCountdownReconciliation) {
      guard scenePhase == .active && alarm.needsCountdownReconciliation else { return }
      await alarm.reconcileCountdown()
    }
    .task(id: scenePhase == .active && napAlarm.needsCountdownReconciliation) {
      guard scenePhase == .active && napAlarm.needsCountdownReconciliation else { return }
      await napAlarm.reconcileCountdown()
    }
    .onAppear {
      napRun.scenePhaseChanged(isActive: scenePhase == .active)
      alarm.refresh()
      napAlarm.refresh()
      restActivity.reconcile()
      if !evaluatedWelcome {
        evaluatedWelcome = true
        #if DEBUG
          showingWelcome =
            !hasSeenQuietWelcome
            && (!UITestFixtures.isEnabled
              || ProcessInfo.processInfo.environment["HONKSHOOL_UI_TEST_SHOW_WELCOME"] == "1")
        #else
          showingWelcome = !hasSeenQuietWelcome
        #endif
      }
      guard !loadedPreferences else { return }
      loadedPreferences = true
      let savedMinutes = RestDurationPolicy.normalized(minutes: preferredRestMinutes)
      if savedMinutes != preferredRestMinutes {
        preferredRestMinutes = savedMinutes
      }
      selectedMinutes = savedMinutes
      customMinutes = selectedMinutes
      exactWakeTime = RestDurationPolicy.wakeDate(startingAt: .now, minutes: selectedMinutes)
    }
  }

  private var historyScreen: some View {
    ListeningHistoryView(
      store: historyStore,
      canStart: !napRun.hasActiveRun && !napAlarm.hasTrackedAlarm && !napAlarm.isScheduling,
      isNarrationAvailable: historyNarrationAvailable,
      reviewDestination: { selection in reviewView(startingAt: selection) })
  }

  private var settingsScreen: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        RestHeading("Settings", subtitle: "A few choices to make rest feel familiar.")
        RestCard(title: "Rest") {
          NavigationLink {
            RestDefaultsView()
          } label: {
            settingsRow("Rest defaults", value: "\(settingsDefaults.durationMinutes) min")
          }.accessibilityIdentifier("openRestDefaults")
          LabeledContent(
            "Rest sound",
            value: settingsDefaults.soundID.map(PreparedAmbience.displayName) ?? "Silence"
          )
          .accessibilityIdentifier("settingsRestSound")
          .font(.subheadline).foregroundStyle(RestStyle.secondary)
          LabeledContent(
            "Wake alarm",
            value: settingsDefaults.wakeAlarm ? "On for new plans" : "Off for new plans"
          )
          .font(.subheadline).foregroundStyle(RestStyle.secondary)
          Text(
            "Changes here apply to your next timer or unreviewed narrated plan."
          )
          .font(.footnote).foregroundStyle(RestStyle.secondary)
        }
        if let catalog = browsingCatalog {
          preparedSettings(catalog)
        } else if let browsingError {
          RestCard(title: "Prepared content") {
            Text(browsingError).foregroundStyle(RestStyle.secondary)
            Button("Try loading again") { loadBrowsingCatalog() }.frame(minHeight: 44)
          }
        } else {
          ProgressView("Loading prepared content")
        }
        RestCard(title: "About") {
          Text("Listening history stays on this iPhone. Honkshool works without an account.")
            .foregroundStyle(RestStyle.secondary)
          Text("Appearance and text size follow your iPhone settings.")
            .font(.subheadline).foregroundStyle(RestStyle.secondary)
        }
        RestCard(title: "Advanced") {
          NavigationLink {
            labScreen
          } label: {
            settingsRow("Feasibility Lab")
          }.accessibilityIdentifier("openFeasibilityLab")
          Text("Experimental alarm and audio controls for testing this iPhone.")
            .font(.footnote).foregroundStyle(RestStyle.secondary)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(RestStyle.pageInset)
    }
    .restScreen().navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
    .task { if browsingCatalog == nil { loadBrowsingCatalog() } }
    .onAppear {
      #if DEBUG
        let availableSounds = UITestFixtures.planReviewAmbienceIDs
      #else
        let availableSounds = PreparedAmbience.availableIDs()
      #endif
      settingsDefaults = RestPreferences.load(availableAmbienceIDs: availableSounds)
    }
  }

  private func preparedSettings(_ catalog: PreparedCatalog) -> some View {
    RestCard(title: "Prepare ahead") {
      NavigationLink {
        RestLibraryView(
          catalog: catalog, historyStore: historyStore,
          isAvailable: historyNarrationAvailable,
          canPlan: !napRun.hasActiveRun && !napAlarm.hasTrackedAlarm && !napAlarm.isScheduling
            && audio.canStartNewRun && !alarm.hasTrackedAlarm,
          reviewDestination: { reviewView(startingAt: $0) })
      } label: {
        settingsRow("Journeys and sessions")
      }
      .accessibilityIdentifier("openJourneyLibrary")
      Divider()
      NavigationLink {
        BundledAudioView(catalog: catalog)
      } label: {
        settingsRow("Offline library")
      }
      .accessibilityIdentifier("openOfflineLibrary")
      Divider()
      NavigationLink {
        NarrationVoiceView(
          catalog: catalog,
          canPreview: !napRun.hasActiveRun && audio.canStartNewRun
            && !napAlarm.isScheduling && !alarm.isScheduling && !isStarting)
      } label: {
        settingsRow("Narration voice", value: "George")
      }
      .accessibilityIdentifier("openNarrationVoice")
      Divider()
      NavigationLink {
        CurrentDetailView()
      } label: {
        settingsRow("Session detail", value: "Enthusiast")
      }
      .accessibilityIdentifier("openCurrentDetail")
    }
  }

  private func settingsRow(_ title: String, value: String? = nil) -> some View {
    HStack {
      Text(title)
      Spacer(minLength: 8)
      if let value { Text(value).foregroundStyle(RestStyle.secondary) }
      Image(systemName: "chevron.right").font(.caption).foregroundStyle(RestStyle.secondary)
    }.frame(minHeight: 44)
  }

  private func loadBrowsingCatalog() {
    do {
      browsingCatalog = try PreparedCatalog.load()
      browsingError = nil
    } catch {
      browsingError = "The prepared library could not be loaded. \(error.localizedDescription)"
    }
  }

  private func showHistory() {
    showingSettings = false
    selectedTab = .history
  }

  private var welcomeScreen: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        Spacer(minLength: 24)
        GooseMark(size: 84)
          .accessibilityHidden(true)
        Text("Room to rest.\nA thought to follow.")
          .font(.system(.largeTitle, design: .rounded).weight(.medium))
          .foregroundStyle(RestStyle.ink)
        Text(
          "Set a nap timer with gentle rain or silence. Add a narrated session when you want a thought to follow."
        )
        .font(.body)
        .foregroundStyle(RestStyle.secondary)
        Spacer()
        Button("Choose your first rest") {
          hasSeenQuietWelcome = true
          showingWelcome = false
        }
        .buttonStyle(RestButtonStyle())
        .accessibilityIdentifier("dismissQuietWelcome")
        Text("No account needed. Your listening stays on this iPhone.")
          .font(.footnote)
          .foregroundStyle(RestStyle.secondary)
      }
      .padding(RestStyle.pageInset)
      .frame(maxWidth: .infinity, alignment: .leading)
      .restScreen()
    }
    .restScreen()
  }

  private var labScreen: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        RestHeading(
          "Feasibility Lab", subtitle: "Experimental controls for testing on this iPhone.")
        introductionCard
        if napRun.phase != .idle {
          napRunCard
        }
        if napAlarm.hasTrackedAlarm {
          napPlanAlarmCard
        }
        if let error = historyStore.errorMessage {
          SpikeCard(title: "Listening history", systemImage: "exclamationmark.triangle") {
            Text(error)
              .foregroundStyle(.red)
              .accessibilityIdentifier("parentHistorySaveError")
            Button("Retry saving") { historyStore.retrySave() }
              .accessibilityIdentifier("parentRetryHistorySave")
          }
        }
        durationCard
          .disabled(isStarting || alarm.isScheduling || napRun.hasActiveRun)
        alarmCard
          .disabled(isStarting || alarm.isScheduling || napRun.hasActiveRun)
        playbackCard
          .disabled(napRun.hasActiveRun)
        NavigationLink("Audio event log") {
          AudioEventLogView(audio: audio)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("audioEventLog")
        NavigationLink {
          reviewView(startingAt: nil)
        } label: {
          Label("Choose and review a Nap Plan", systemImage: "checklist")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(RestButtonStyle(secondary: true))
        .controlSize(.large)
        .accessibilityIdentifier("openNapPlanReview")
        .disabled(napRun.hasActiveRun)
        NavigationLink {
          historyScreen
        } label: {
          Label("Listening history and Continue", systemImage: "clock.arrow.circlepath")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("openListeningHistory")
      }
      .padding(.horizontal, RestStyle.pageInset)
      .padding(.vertical, 24)
    }
    .restScreen()
    .navigationTitle("Feasibility Lab")
    .alert(
      "Test cannot start",
      isPresented: Binding(
        get: { blockedReason != nil },
        set: { if !$0 { blockedReason = nil } }
      )
    ) {
      Button("OK", role: .cancel) { blockedReason = nil }
    } message: {
      Text(blockedReason ?? "")
    }
  }

  private var historyNarrationAvailable: (PreparedSession) -> Bool {
    #if DEBUG
      UITestFixtures.planReviewNarrationAvailable
    #else
      { (try? $0.narrationURL()) != nil }
    #endif
  }

  private func reviewView(
    startingAt selection: SessionSelection?, isHome: Bool = false
  ) -> NapPlanReviewView {
    #if DEBUG
      NapPlanReviewView(
        run: napRun, alarm: napAlarm, historyStore: historyStore, startingAt: selection,
        isHome: isHome, onShowHistory: showHistory,
        lockScreenTimerMessage: restActivity.availabilityMessage,
        canStart: {
          (audio.phase == .idle || audio.phase == .stopped || audio.phase == .failed)
            && !alarm.hasTrackedAlarm
        },
        clock: UITestFixtures.planReviewNow,
        confirmationClock: UITestFixtures.planReviewConfirmationNow,
        isNarrationAvailable: UITestFixtures.planReviewNarrationAvailable,
        availableAmbienceIDs: UITestFixtures.planReviewAmbienceIDs)
    #else
      NapPlanReviewView(
        run: napRun, alarm: napAlarm, historyStore: historyStore, startingAt: selection,
        isHome: isHome, onShowHistory: showHistory,
        lockScreenTimerMessage: restActivity.availabilityMessage,
        canStart: {
          (audio.phase == .idle || audio.phase == .stopped || audio.phase == .failed)
            && !alarm.hasTrackedAlarm
        })
    #endif
  }

  private var napRunCard: some View {
    SpikeCard(title: "Nap Plan", systemImage: "waveform") {
      VStack(alignment: .leading, spacing: 12) {
        Text(napRun.statusMessage)
          .accessibilityIdentifier("activeNapRunStatus")
        HStack {
          if napRun.canPause {
            Button("Pause playback") { napRun.pause() }
              .accessibilityIdentifier("parentPauseNapRun")
          } else if napRun.canResume {
            Button("Resume playback") { napRun.resume() }
              .accessibilityIdentifier("parentResumeNapRun")
          }
          if napRun.hasActiveRun {
            Button(
              napRun.presentationPlan?.isTimer == true ? "Stop rest" : "Stop playback",
              role: .destructive
            ) { napRun.stop() }
            .accessibilityIdentifier("parentStopNapRun")
          }
        }
        if !napRun.records.isEmpty {
          Text("Completed sessions in this run: \(napRun.records.filter(\.isCompleted).count)")
            .accessibilityIdentifier("parentNapRunCompletionCount")
        }
      }
    }
  }

  private var napPlanAlarmCard: some View {
    SpikeCard(title: "Nap Plan wake alarm", systemImage: "alarm") {
      VStack(alignment: .leading, spacing: 10) {
        Text(napAlarm.statusMessage)
          .accessibilityIdentifier("parentNapPlanAlarmStatus")
        if let nextAlert = napAlarm.alarmStatus.nextAlertDate {
          wakeTimeRow("Next system alert", date: nextAlert)
        }
        if !napRun.hasActiveRun && napAlarm.canCancelTrackedAlarm {
          Button("Cancel Nap Plan wake alarm", role: .destructive) {
            _ = napAlarm.cancel()
          }
          .disabled(napAlarm.isScheduling)
          .accessibilityIdentifier("parentCancelNapPlanAlarm")
        }
      }
    }
  }

  private var introductionCard: some View {
    SpikeCard(title: "Test session", systemImage: "car.side") {
      VStack(alignment: .leading, spacing: 8) {
        Text(SampleContent.journeyTitle)
          .font(.caption)
          .foregroundStyle(RestStyle.secondary)
        Text(SampleContent.sessionTitle)
          .font(.title3.weight(.semibold))
        Text(
          "The complete prepared session uses Kokoro George at the accepted calm-documentary cadence."
        )
        .font(.subheadline)
        .foregroundStyle(RestStyle.secondary)
      }
    }
  }

  private var durationCard: some View {
    SpikeCard(title: "Rest window", systemImage: "timer") {
      VStack(alignment: .leading, spacing: 12) {
        Toggle("Choose an exact wake time", isOn: $usesExactWakeTime)
          .accessibilityIdentifier("useExactWakeTime")

        if usesExactWakeTime {
          DatePicker(
            "Wake time",
            selection: $exactWakeTime,
            in: Date.now...,
            displayedComponents: [.date, .hourAndMinute]
          )
          .accessibilityIdentifier("exactWakeTime")
        } else {
          HStack(spacing: 8) {
            ForEach(RestDurationPolicy.recommendedMinutes, id: \.self) { minutes in
              DurationButton(
                minutes: minutes,
                selected: selectedMinutes == minutes
              ) {
                selectedMinutes = minutes
                customMinutes = minutes
              }
            }

          }
          if !RestDurationPolicy.recommendedMinutes.contains(
            preferredRestMinutes
          ) {
            DurationButton(
              minutes: preferredRestMinutes,
              selected: selectedMinutes == preferredRestMinutes,
              labelPrefix: "Saved"
            ) {
              selectedMinutes = preferredRestMinutes
              customMinutes = preferredRestMinutes
            }
          }
          Stepper(
            "Custom: \(customMinutes) minutes",
            value: $customMinutes,
            in: RestDurationPolicy.allowedMinutes,
            step: 5
          )

          HStack {
            Button("Use custom") {
              selectedMinutes = customMinutes
            }
            .buttonStyle(.bordered)

            Button("Save as default") {
              let normalized = RestDurationPolicy.normalized(
                minutes: customMinutes
              )
              preferredRestMinutes = normalized
              selectedMinutes = normalized
              runMessage = "Saved a reusable \(normalized)-minute default."
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("saveDefaultDuration")
          }
        }

        if let runWakeDate, isStarting || !audio.canStartNewRun {
          wakeTimeRow("Run wake", date: runWakeDate)
        } else if usesExactWakeTime {
          wakeTimeRow("Selected wake", date: exactWakeTime)
        } else {
          TimelineView(.periodic(from: .now, by: 1)) { context in
            wakeTimeRow(
              "Wake if started now",
              date: RestDurationPolicy.wakeDate(
                startingAt: context.date, minutes: selectedMinutes
              )
            )
          }
        }

        Text(
          "This is a rest window, not an estimate or promise of actual sleep time."
        )
        .font(.footnote)
        .foregroundStyle(RestStyle.secondary)
      }
    }
  }

  private var alarmCard: some View {
    SpikeCard(title: "AlarmKit", systemImage: "alarm") {
      VStack(alignment: .leading, spacing: 12) {
        Toggle("Require a wake alarm", isOn: $alarmEnabled)
          .accessibilityIdentifier("requireAlarm")

        LabeledContent("Authorization", value: authorizationText)
          .accessibilityIdentifier("alarmAuthorization")
        LabeledContent("Alarm status", value: alarm.alarmStatus.phase.rawValue)
          .accessibilityIdentifier("alarmStatus")

        if let scheduledDate = alarm.scheduledDate {
          LabeledContent("Next alert") {
            Text(
              scheduledDate.formatted(
                date: .abbreviated,
                time: .standard
              )
            )
          }
          .accessibilityIdentifier("nextAlertTime")
          if alarm.alarmStatus.phase == .snoozed {
            LabeledContent("Snooze remaining") {
              Text(timerInterval: Date.distantPast...scheduledDate, countsDown: true)
                .monospacedDigit()
            }
            .accessibilityIdentifier("snoozeRemaining")
          }
        }

        Text(alarm.statusMessage)
          .font(.footnote)
          .foregroundStyle(RestStyle.secondary)
          .accessibilityIdentifier("alarmMessage")

        HStack {
          Button("Authorize") {
            Task { await alarm.requestAuthorization() }
          }
          .buttonStyle(RestButtonStyle(secondary: true))
          .accessibilityIdentifier("authorizeAlarm")

          Button("60-second test") {
            Task {
              _ = await alarm.schedule(
                at: Date.now.addingTimeInterval(60)
              )
            }
          }
          .buttonStyle(.bordered)
          .accessibilityIdentifier("shortAlarmTest")
          .disabled(alarm.authorization != .authorized || alarm.isScheduling || isStarting)
        }

        Button("Cancel Honkshool alarm", role: .destructive) {
          alarm.cancel()
        }
        .accessibilityIdentifier("cancelAlarm")
        .disabled(!alarm.hasTrackedAlarm || alarm.isScheduling)

        if alarmEnabled && alarm.authorization != .authorized {
          Label(
            "Playback is blocked until AlarmKit is authorized and the alarm schedules successfully.",
            systemImage: "exclamationmark.lock"
          )
          .font(.footnote.weight(.medium))
          .foregroundStyle(.orange)
        }
      }
    }
  }

  private var playbackCard: some View {
    SpikeCard(title: "Background audio", systemImage: "waveform") {
      VStack(alignment: .leading, spacing: 12) {
        Toggle(
          "Transition to generated ambience",
          isOn: $ambienceEnabled
        )
        .accessibilityIdentifier("ambienceEnabled")
        .disabled(isStarting || alarm.isScheduling)

        LabeledContent("Phase", value: audio.phase.rawValue.capitalized)
          .accessibilityIdentifier("playbackPhase")

        Text(audio.statusMessage)
          .font(.subheadline)
          .accessibilityIdentifier("playbackMessage")
        Text(runMessage)
          .font(.footnote)
          .foregroundStyle(RestStyle.secondary)
          .accessibilityIdentifier("runMessage")

        Button {
          Task { await startRun() }
        } label: {
          Label("Schedule and start test", systemImage: "play.fill")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(RestButtonStyle())
        .controlSize(.large)
        .disabled(isStarting || alarm.isScheduling || !audio.canStartNewRun)
        .accessibilityIdentifier("startTest")

        HStack {
          Button("Pause") { audio.pause() }
            .disabled(
              audio.phase != .narrating && audio.phase != .ambience
            )
            .accessibilityIdentifier("pausePlayback")
          Button("Resume") { audio.resume() }
            .disabled(!audio.canResume)
            .accessibilityIdentifier("resumePlayback")
          Button("Stop", role: .destructive) { audio.stop() }
            .disabled(audio.phase == .idle || audio.phase == .stopped)
            .accessibilityIdentifier("stopPlayback")
        }
        .buttonStyle(.bordered)

        Text(
          "Starting plays the bundled George narration and activates an exclusive playback session, so existing music or podcasts should stop. Skipping and seeking are disabled; iOS may still display their controls."
        )
        .font(.footnote)
        .foregroundStyle(RestStyle.secondary)
      }
    }
  }

  private func wakeTimeRow(_ title: String, date: Date) -> some View {
    LabeledContent(title) {
      Text(date.formatted(date: .abbreviated, time: .shortened))
    }
    .font(.subheadline)
    .accessibilityIdentifier("wakePreview")
  }

  private var authorizationText: String {
    switch alarm.authorization {
    case .notDetermined: "Not requested"
    case .denied: "Denied"
    case .authorized: "Authorized"
    }
  }

  private func startRun() async {
    guard !isStarting && audio.canStartNewRun else { return }
    guard !napAlarm.hasTrackedAlarm else {
      blockedReason = "Cancel the tracked Nap Plan wake alarm before starting a feasibility test."
      return
    }
    isStarting = true
    defer { isStarting = false }
    let runAlarmEnabled = alarmEnabled
    let runAmbienceEnabled = ambienceEnabled
    alarm.refresh()
    let plannedWakeDate =
      usesExactWakeTime
      ? exactWakeTime
      : RestDurationPolicy.wakeDate(startingAt: .now, minutes: selectedMinutes)
    runWakeDate = plannedWakeDate
    var schedule: AlarmScheduleSnapshot = .notScheduled

    if runAlarmEnabled {
      guard alarm.authorization == .authorized else {
        runMessage = blockedMessage(
          authorization: alarm.authorization,
          schedule: schedule,
          now: .now
        )
        blockedReason = runMessage
        return
      }

      let scheduled = await alarm.schedule(at: plannedWakeDate)
      schedule = scheduled ? .scheduled(plannedWakeDate) : .failed
    } else if !alarm.cancel() {
      runMessage =
        "The previous alarm could not be cancelled. Playback is blocked; retry cancellation."
      blockedReason = runMessage
      return
    }

    switch FeasibilityRunGate.evaluate(
      alarmEnabled: runAlarmEnabled,
      authorization: alarm.authorization,
      schedule: schedule,
      now: .now
    ) {
    case .ready:
      do {
        #if DEBUG
          try UITestFixtures.failPreparedCatalogLoadIfRequested()
        #endif
        let catalog = try PreparedCatalog.load()
        guard let prepared = catalog.sessions["turning-fuel-into-motion"] else {
          throw PreparedCatalogError.invalidContent("turning-fuel-into-motion")
        }
        audio.startPreparedNarration(
          url: try prepared.narrationURL(),
          title: prepared.session.title,
          transitionToAmbience: runAmbienceEnabled,
          wakeDeadline: plannedWakeDate
        )
      } catch {
        runMessage = "Prepared George narration is unavailable: \(error.localizedDescription)"
        if alarm.hasTrackedAlarm {
          runMessage += " The wake alarm remains active; cancel it separately if no longer needed."
        }
        blockedReason = runMessage
        return
      }
      guard audio.phase == .narrating else {
        runMessage = "Playback did not start. \(audio.statusMessage)"
        if alarm.hasTrackedAlarm {
          runMessage += " The wake alarm remains active; cancel it separately if no longer needed."
        }
        blockedReason = runMessage
        return
      }
      runMessage =
        runAlarmEnabled
        ? "Alarm scheduled before playback. Lock the screen and observe the test."
        : "Alarm explicitly disabled. Lock the screen and observe the test."
    case .blocked(let reason):
      runMessage = reason
      blockedReason = reason
    }
  }

  private func blockedMessage(
    authorization: AlarmAuthorizationSnapshot,
    schedule: AlarmScheduleSnapshot,
    now: Date
  ) -> String {
    switch FeasibilityRunGate.evaluate(
      alarmEnabled: true,
      authorization: authorization,
      schedule: schedule,
      now: now
    ) {
    case .ready: "Ready"
    case .blocked(let reason): reason
    }
  }
}

private struct AudioEventLogView: View {
  @ObservedObject var audio: AudioSpikeController

  var body: some View {
    List(audio.eventLog) { event in
      Text(event.message)
        .font(.caption.monospaced())
    }
    .overlay {
      if audio.eventLog.isEmpty {
        ContentUnavailableView("No audio events yet", systemImage: "waveform")
      }
    }
    .navigationTitle("Audio event log")
    .scrollContentBackground(.hidden)
    .restScreen()
  }
}

private struct SpikeCard<Content: View>: View {
  let title: String
  let systemImage: String
  @ViewBuilder let content: Content

  var body: some View {
    RestCard(title: title, systemImage: systemImage) {
      content
    }
  }
}

private struct DurationButton: View {
  let minutes: Int
  let selected: Bool
  var labelPrefix: String?
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 2) {
        if let labelPrefix {
          Text(labelPrefix)
            .font(.caption2)
        }
        Text("\(minutes) min")
          .font(.subheadline.weight(.semibold))
      }
      .frame(maxWidth: .infinity)
    }
    .buttonStyle(.bordered)
    .tint(selected ? RestStyle.ink : RestStyle.secondary)
  }
}
