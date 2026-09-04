import SwiftUI

struct FeasibilityConsoleView: View {
  @StateObject private var audio = AudioSpikeController()
  @StateObject private var alarm = AlarmSpikeService()

  @AppStorage("preferredRestMinutes")
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

  private let columns = [
    GridItem(.adaptive(minimum: 72), spacing: 8)
  ]

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 16) {
          introductionCard
          durationCard
          alarmCard
          playbackCard
          eventLogCard
        }
        .padding()
      }
      .background(Color(.systemGroupedBackground))
      .navigationTitle("Feasibility Lab")
      .onAppear {
        selectedMinutes = RestDurationPolicy.normalized(
          minutes: preferredRestMinutes
        )
        customMinutes = selectedMinutes
        exactWakeTime = RestDurationPolicy.wakeDate(
          startingAt: .now,
          minutes: selectedMinutes
        )
        alarm.refresh()
      }
    }
  }

  private var introductionCard: some View {
    SpikeCard(title: "Test session", systemImage: "car.side") {
      VStack(alignment: .leading, spacing: 8) {
        Text(SampleContent.journeyTitle)
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(SampleContent.sessionTitle)
          .font(.title3.weight(.semibold))
        Text(
          "This short provisional script tests system behavior. It is not the final researched session."
        )
        .font(.subheadline)
        .foregroundStyle(.secondary)
      }
    }
  }

  private var durationCard: some View {
    SpikeCard(title: "Rest window", systemImage: "timer") {
      VStack(alignment: .leading, spacing: 12) {
        Toggle("Choose an exact wake time", isOn: $usesExactWakeTime)

        if usesExactWakeTime {
          DatePicker(
            "Wake time",
            selection: $exactWakeTime,
            in: Date.now...,
            displayedComponents: [.date, .hourAndMinute]
          )
        } else {
          LazyVGrid(columns: columns, spacing: 8) {
            ForEach(RestDurationPolicy.recommendedMinutes, id: \.self) { minutes in
              DurationButton(
                minutes: minutes,
                selected: selectedMinutes == minutes
              ) {
                selectedMinutes = minutes
                customMinutes = minutes
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
          }
        }

        LabeledContent("Planned wake") {
          Text(wakeDate.formatted(date: .abbreviated, time: .shortened))
        }
        .font(.subheadline)

        Text(
          "This is a rest window, not an estimate or promise of actual sleep time."
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
      }
    }
  }

  private var alarmCard: some View {
    SpikeCard(title: "AlarmKit", systemImage: "alarm") {
      VStack(alignment: .leading, spacing: 12) {
        Toggle("Require a wake alarm", isOn: $alarmEnabled)

        LabeledContent("Authorization", value: authorizationText)

        if let scheduledDate = alarm.scheduledDate {
          LabeledContent("Scheduled") {
            Text(
              scheduledDate.formatted(
                date: .abbreviated,
                time: .standard
              )
            )
          }
        }

        Text(alarm.statusMessage)
          .font(.footnote)
          .foregroundStyle(.secondary)

        HStack {
          Button("Authorize") {
            Task { await alarm.requestAuthorization() }
          }
          .buttonStyle(.borderedProminent)

          Button("60-second test") {
            Task {
              _ = await alarm.schedule(
                at: Date.now.addingTimeInterval(60)
              )
            }
          }
          .buttonStyle(.bordered)
          .disabled(alarm.authorization != .authorized)
        }

        Button("Cancel Honkshool alarm", role: .destructive) {
          alarm.cancel()
        }
        .disabled(alarm.scheduledDate == nil)

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

        LabeledContent("Phase", value: audio.phase.rawValue.capitalized)

        Text(audio.statusMessage)
          .font(.subheadline)
        Text(runMessage)
          .font(.footnote)
          .foregroundStyle(.secondary)

        Button {
          Task { await startRun() }
        } label: {
          Label("Schedule and start test", systemImage: "play.fill")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)

        HStack {
          Button("Pause") { audio.pause() }
            .disabled(
              audio.phase != .narrating && audio.phase != .ambience
            )
          Button("Resume") { audio.resume() }
            .disabled(
              audio.phase != .paused && audio.phase != .interrupted
            )
          Button("Stop", role: .destructive) { audio.stop() }
            .disabled(audio.phase == .idle || audio.phase == .stopped)
        }
        .buttonStyle(.bordered)

        Text(
          "Starting activates an exclusive playback session, so existing music or podcasts should stop. Playback controls intentionally omit skipping and seeking."
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
      }
    }
  }

  private var eventLogCard: some View {
    SpikeCard(title: "Audio event log", systemImage: "list.bullet.rectangle") {
      if audio.eventLog.isEmpty {
        Text("Audio-session and interruption events will appear here.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      } else {
        VStack(alignment: .leading, spacing: 8) {
          ForEach(Array(audio.eventLog.enumerated()), id: \.offset) { _, event in
            Text(event)
              .font(.caption.monospaced())
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
    }
  }

  private var wakeDate: Date {
    if usesExactWakeTime {
      return exactWakeTime
    }
    return RestDurationPolicy.wakeDate(
      startingAt: .now,
      minutes: selectedMinutes
    )
  }

  private var authorizationText: String {
    switch alarm.authorization {
    case .notDetermined: "Not requested"
    case .denied: "Denied"
    case .authorized: "Authorized"
    }
  }

  private func startRun() async {
    let plannedWakeDate = wakeDate
    var schedule: AlarmScheduleSnapshot = .notScheduled

    if alarmEnabled {
      guard alarm.authorization == .authorized else {
        runMessage = blockedMessage(
          authorization: alarm.authorization,
          schedule: schedule,
          now: .now
        )
        return
      }

      let scheduled = await alarm.schedule(at: plannedWakeDate)
      schedule = scheduled ? .scheduled(plannedWakeDate) : .failed
    }

    switch FeasibilityRunGate.evaluate(
      alarmEnabled: alarmEnabled,
      authorization: alarm.authorization,
      schedule: schedule,
      now: .now
    ) {
    case .ready:
      runMessage =
        alarmEnabled
        ? "Alarm scheduled before playback. Lock the screen and observe the test."
        : "Alarm explicitly disabled. Lock the screen and observe the test."
      audio.startNarration(
        script: SampleContent.narration,
        title: SampleContent.sessionTitle,
        transitionToAmbience: ambienceEnabled
      )
    case .blocked(let reason):
      runMessage = reason
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

private struct SpikeCard<Content: View>: View {
  let title: String
  let systemImage: String
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Label(title, systemImage: systemImage)
        .font(.headline)
      content
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(.background, in: RoundedRectangle(cornerRadius: 18))
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
    .tint(selected ? .accentColor : .secondary)
  }
}
