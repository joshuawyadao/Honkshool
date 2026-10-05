import SwiftUI

struct RestTimeChoices: Equatable {
  var minutes: Int
  var usesExactWakeTime: Bool
  var wakeTime: Date
}

/// A local draft keeps Cancel and interactive dismissal from changing the plan.
struct RestTimeSheet: View {
  @Environment(\.dismiss) private var dismiss
  @State private var draft: RestTimeChoices
  let onApply: (RestTimeChoices) -> Void

  init(initial: RestTimeChoices, onApply: @escaping (RestTimeChoices) -> Void) {
    _draft = State(initialValue: initial)
    self.onApply = onApply
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        RestHeading("Make a little room.", subtitle: "Choose a duration or an exact ending time.")
        RestCard(title: "Time to rest") {
          Toggle(isOn: $draft.usesExactWakeTime) {
            HStack {
              Text("Rest until an exact time")
              Spacer(minLength: 8)
              Text(draft.usesExactWakeTime ? "On" : "Off")
                .foregroundStyle(RestStyle.secondary)
                .accessibilityHidden(true)
            }
          }
          .tint(RestStyle.accent)
          .accessibilityIdentifier("napPlanUseExactWakeTime")
          if draft.usesExactWakeTime {
            DatePicker(
              "Wake time", selection: $draft.wakeTime, displayedComponents: [.date, .hourAndMinute]
            )
            .accessibilityLabel("Wake time")
            .accessibilityIdentifier("napPlanExactWakeTime")
          } else {
            Picker("Rest for", selection: $draft.minutes) {
              ForEach([5, 10, 20, 30, 45, 60], id: \.self) { minutes in
                Text("\(minutes) minutes").tag(minutes)
              }
              if ![5, 10, 20, 30, 45, 60].contains(draft.minutes) {
                Text("\(draft.minutes) minutes").tag(draft.minutes)
              }
            }
            .accessibilityIdentifier("napPlanDuration")
            RestDurationChoices(minutes: $draft.minutes, identifierPrefix: "napTimePreset")
            RestDurationWheels(minutes: $draft.minutes, identifierPrefix: "napPlanCustomDuration")
          }
        }
        Text("Your final start and ending time appear in the review. The ending time stays fixed.")
          .foregroundStyle(RestStyle.secondary)
        Text("This is a rest window, not a promise of sleep time.")
          .font(.footnote).foregroundStyle(RestStyle.secondary)
      }.padding(RestStyle.pageInset)
    }
    .safeAreaInset(edge: .bottom) {
      Button("Use these choices") {
        onApply(draft)
        dismiss()
      }
      .buttonStyle(RestButtonStyle())
      .accessibilityIdentifier("applyNapTime")
      .padding(RestStyle.pageInset).background(RestStyle.background)
    }
    .restScreen()
    .navigationTitle("Time to rest")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") { dismiss() }.accessibilityIdentifier("cancelNapTime")
      }
    }
  }
}

struct RestDurationChoices: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Binding var minutes: Int
  var identifierPrefix = "napPlanPreset"
  var body: some View {
    // Four choices need no lazy loading. Eager rows keep every visible preset
    // in the accessibility tree, including an incomplete final row.
    ViewThatFits(in: .horizontal) {
      choices(columns: 4)
      choices(columns: 3)
      choices(columns: 2)
      choices(columns: 1)
    }
  }

  private func choices(columns: Int) -> some View {
    let values = RestDurationPolicy.recommendedMinutes
    return Grid(horizontalSpacing: 8, verticalSpacing: 8) {
      ForEach(0..<((values.count + columns - 1) / columns), id: \.self) { row in
        GridRow {
          ForEach(0..<columns, id: \.self) { column in
            let index = row * columns + column
            if values.indices.contains(index) {
              choice(values[index])
            } else {
              Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                .accessibilityHidden(true)
            }
          }
        }
      }
    }
  }

  private func choice(_ value: Int) -> some View {
    Button {
      minutes = value
    } label: {
      HStack(spacing: 4) {
        Text("\(value)")
        if minutes == value {
          Image(systemName: "checkmark")
            .font(.caption.weight(.semibold))
            .accessibilityHidden(true)
        }
      }
      .font(.body.weight(minutes == value ? .semibold : .regular))
      .frame(
        minWidth: dynamicTypeSize.isAccessibilitySize ? 120 : 54,
        maxWidth: .infinity, minHeight: 44
      )
      .background(
        minutes == value ? RestStyle.quiet : RestStyle.well,
        in: RoundedRectangle(cornerRadius: 12)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 12)
          .strokeBorder(minutes == value ? RestStyle.secondary : .clear, lineWidth: 1)
      }
    }
    .accessibilityLabel("\(value) minutes")
    .accessibilityIdentifier("\(identifierPrefix)-\(value)")
    .accessibilityAddTraits(minutes == value ? .isSelected : [])
    .buttonStyle(.plain)
  }

}

/// Two native wheels keep custom durations within the rest timer's 1...180 minute range.
struct RestDurationWheels: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Binding var minutes: Int
  let identifierPrefix: String

  private var hours: Int { minutes / 60 }
  private var remainingMinutes: Int { minutes % 60 }
  private var allowedMinuteValues: Range<Int> {
    hours == 0 ? 1..<60 : (hours == 3 ? 0..<1 : 0..<60)
  }

  var body: some View {
    HStack(alignment: .bottom, spacing: 8) {
      wheel(title: "Hours", identifier: "\(identifierPrefix)Hours") {
        Picker(
          "Hours",
          selection: Binding(
            get: { hours },
            set: { newHours in
              minutes = min(180, max(1, newHours * 60 + remainingMinutes))
            }
          )
        ) {
          ForEach(0...3, id: \.self) { hour in
            Text("\(hour)").tag(hour)
          }
        }
      }
      wheel(title: "Minutes", identifier: "\(identifierPrefix)Minutes") {
        Picker(
          "Minutes",
          selection: Binding(
            get: { remainingMinutes },
            set: { newMinutes in
              minutes = min(180, max(1, hours * 60 + newMinutes))
            }
          )
        ) {
          ForEach(allowedMinuteValues, id: \.self) { minute in
            Text("\(minute)").tag(minute)
          }
        }
      }
    }
  }

  private func wheel<Content: View>(
    title: String, identifier: String, @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(spacing: 0) {
      Text(title).font(.subheadline).foregroundStyle(RestStyle.secondary)
        .multilineTextAlignment(.center)
        .accessibilityHidden(true)
      content()
        .pickerStyle(.wheel)
        .labelsHidden()
        .accessibilityIdentifier(identifier)
        .frame(maxWidth: .infinity)
        .frame(height: dynamicTypeSize.isAccessibilitySize ? 180 : 150)
        .clipped()
    }
    .frame(maxWidth: .infinity)
  }
}

struct RestSoundSheet: View {
  @Environment(\.dismiss) private var dismiss
  @State private var selection: String?
  let availableIDs: Set<String>
  let onApply: (String?) -> Void

  init(selectedID: String?, availableIDs: Set<String>, onApply: @escaping (String?) -> Void) {
    _selection = State(initialValue: selectedID)
    self.availableIDs = availableIDs
    self.onApply = onApply
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        RestHeading(
          "Let the quiet stay.",
          subtitle: "For quiet parts of your plan, including after the last narration.")
        RestCard {
          choice("Silence", subtitle: "The default. Nothing more to hear.", id: nil)
          if availableIDs.contains(PreparedAmbience.gentleRainID) {
            Divider()
            choice(
              "Gentle rain", subtitle: "A soft, steady background.",
              id: PreparedAmbience.gentleRainID)
          }
        }
        ThoughtDots()
        Text(
          availableIDs.isEmpty
            ? "Gentle rain is unavailable on this device. This plan can still use silence."
            : "If rain becomes unavailable, rest continues in silence. Your ending time stays the same."
        )
        .foregroundStyle(RestStyle.secondary)
        .accessibilityIdentifier("soundAvailabilityNote")
      }.padding(RestStyle.pageInset)
    }
    .safeAreaInset(edge: .bottom) {
      Button("Done") {
        onApply(selection.flatMap { availableIDs.contains($0) ? $0 : nil })
        dismiss()
      }
      .buttonStyle(RestButtonStyle())
      .accessibilityIdentifier("applyNapSound")
      .padding(RestStyle.pageInset).background(RestStyle.background)
    }
    .restScreen()
    .navigationTitle("After narration")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") { dismiss() }.accessibilityIdentifier("cancelNapSound")
      }
    }
  }

  private func choice(_ title: String, subtitle: String, id: String?) -> some View {
    Button {
      selection = id
    } label: {
      HStack(spacing: 16) {
        VStack(alignment: .leading, spacing: 8) {
          Text(title).font(.headline.weight(.medium))
          Text(subtitle).font(.subheadline).foregroundStyle(RestStyle.secondary)
        }
        Spacer(minLength: 8)
        Image(systemName: selection == id ? "checkmark.circle.fill" : "circle")
          .foregroundStyle(selection == id ? RestStyle.ink : RestStyle.secondary)
          .accessibilityHidden(true)
      }.frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
    }
    .accessibilityLabel("\(title). \(subtitle)")
    .accessibilityIdentifier(title)
    .accessibilityAddTraits(selection == id ? .isSelected : [])
    .buttonStyle(.plain)
  }
}

/// Everyday timer choices stay inline; only optional custom timing expands.
struct RestTimerChoices: View {
  @Binding var minutes: Int
  @Binding var usesExactWakeTime: Bool
  @Binding var wakeTime: Date
  @Binding var soundID: String?
  @Binding var alarmEnabled: Bool
  let availableIDs: Set<String>

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      RestCard(title: "Time to rest · minutes") {
        if usesExactWakeTime {
          RestTimingRow(title: "Rest until", date: wakeTime)
        } else {
          RestDurationChoices(minutes: $minutes, identifierPrefix: "timerPreset")
          if !RestDurationPolicy.recommendedMinutes.contains(minutes) {
            Text("\(minutes) minutes").accessibilityIdentifier("timerCustomSummary")
          }
        }
        DisclosureGroup {
          VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $usesExactWakeTime) {
              HStack {
                Text("Rest until an exact time")
                Spacer(minLength: 8)
                Text(usesExactWakeTime ? "On" : "Off")
                  .foregroundStyle(RestStyle.secondary)
                  .accessibilityHidden(true)
              }
            }
            .tint(RestStyle.accent)
            .accessibilityIdentifier("timerExactTime")
            if usesExactWakeTime {
              DatePicker(
                "Wake time", selection: $wakeTime, displayedComponents: [.date, .hourAndMinute]
              )
              .accessibilityIdentifier("timerWakeTime")
            } else {
              RestDurationWheels(minutes: $minutes, identifierPrefix: "timerCustomDuration")
            }
          }.padding(.top, 12)
        } label: {
          Text("Custom duration or wake time")
            .accessibilityIdentifier("timerMoreOptions")
        }
      }
      RestCard(title: "Rest sound") {
        soundChoice("Silence", description: "Nothing more to hear.", id: nil)
        if availableIDs.contains(PreparedAmbience.gentleRainID) {
          soundChoice(
            "Gentle rain", description: "A soft, steady background.",
            id: PreparedAmbience.gentleRainID)
        } else {
          Text("Gentle rain is unavailable. You can still rest in silence.")
            .font(.subheadline).foregroundStyle(RestStyle.secondary)
        }
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
        .accessibilityIdentifier("timerWakeAlarm")
      }
      Text(
        alarmEnabled
          ? "Your wake alarm is verified before rest begins. Keep this screen open until then."
          : "No alarm will sound. Rest quietly until the displayed ending time."
      )
      .font(.subheadline).foregroundStyle(RestStyle.secondary)
      if soundID != nil {
        Text("Rain starts with your timer. If it becomes unavailable, rest continues in silence.")
          .font(.footnote).foregroundStyle(RestStyle.secondary)
      }
    }
  }

  private func soundChoice(_ title: String, description: String, id: String?) -> some View {
    Button {
      soundID = id
    } label: {
      HStack {
        Text(title)
        Spacer(minLength: 8)
        Image(systemName: soundID == id ? "checkmark.circle.fill" : "circle")
          .foregroundStyle(soundID == id ? RestStyle.ink : RestStyle.secondary)
          .accessibilityHidden(true)
      }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }
    .accessibilityLabel("\(title). \(description)")
    .accessibilityIdentifier(id == nil ? "timerSilence" : "timerRain")
    .accessibilityAddTraits(soundID == id ? .isSelected : [])
    .buttonStyle(.plain)
  }
}
