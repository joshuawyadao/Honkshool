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
          Toggle("Rest until an exact time", isOn: $draft.usesExactWakeTime)
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
            RestDurationChoices(minutes: $draft.minutes)
            Stepper("Custom duration: \(draft.minutes) minutes", value: $draft.minutes, in: 1...180)
              .accessibilityIdentifier("napPlanCustomDuration")
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
  @Binding var minutes: Int
  var body: some View {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 54))], spacing: 8) {
      ForEach(RestDurationPolicy.recommendedMinutes, id: \.self) { value in
        Button {
          minutes = value
        } label: {
          Text("\(value)")
            .font(.body.weight(minutes == value ? .semibold : .regular))
            .frame(maxWidth: .infinity, minHeight: 44)
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
        .accessibilityIdentifier("napPlanPreset-\(value)")
        .accessibilityAddTraits(minutes == value ? .isSelected : [])
      }
    }
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
      }.frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
    }
    .accessibilityLabel(title)
    .accessibilityAddTraits(selection == id ? .isSelected : [])
  }
}
