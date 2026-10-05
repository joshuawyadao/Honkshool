import CryptoKit
import SwiftUI

struct RestDefaultsView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var draft = RestDefaults.initial
  @State private var rainAvailable = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        RestHeading("Rest defaults", subtitle: "Start your next plan with choices that feel right.")
        RestCard(title: "Rest time", systemImage: "clock") {
          Text("\(draft.durationMinutes) minutes")
            .font(.title3.monospacedDigit().weight(.medium))
          RestDurationChoices(
            minutes: $draft.durationMinutes, identifierPrefix: "defaultRestPreset")
          RestDurationWheels(
            minutes: $draft.durationMinutes, identifierPrefix: "defaultRestDuration")
          Text("Choose from 1 to 180 minutes. You can still change each plan before reviewing it.")
            .font(.footnote)
            .foregroundStyle(RestStyle.secondary)
        }
        RestCard(title: "Sound after narration", systemImage: "waveform") {
          Picker("Default sound", selection: $draft.soundID) {
            Text("Silence").tag(String?.none)
            if rainAvailable {
              Text("Gentle rain").tag(Optional(PreparedAmbience.gentleRainID))
            }
          }
          .pickerStyle(.menu)
          .accessibilityIdentifier("defaultRestSound")
          Text(
            rainAvailable
              ? "Gentle rain uses the prepared recording stored in the app."
              : "Gentle rain is unavailable on this installation. Silence remains available."
          )
          .font(.footnote)
          .foregroundStyle(RestStyle.secondary)
        }
        RestCard(title: "Wake alarm", systemImage: "alarm") {
          Toggle(isOn: $draft.wakeAlarm) {
            HStack {
              Text("Request a wake alarm for new plans")
              Spacer(minLength: 8)
              Text(draft.wakeAlarm ? "On" : "Off")
                .foregroundStyle(RestStyle.secondary)
                .accessibilityHidden(true)
            }
          }
          .tint(RestStyle.accent)
          .accessibilityIdentifier("defaultRestAlarm")
          Text(
            "Alarm availability is checked when you start a rest. An existing plan keeps its reviewed choice."
          )
          .font(.footnote)
          .foregroundStyle(RestStyle.secondary)
        }
        Button("Save defaults") {
          if !rainAvailable { draft.soundID = nil }
          RestPreferences.save(draft)
          dismiss()
        }
        .buttonStyle(RestButtonStyle())
        .accessibilityIdentifier("saveRestDefaults")
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, RestStyle.pageInset)
      .padding(.vertical, 24)
    }
    .restScreen()
    .navigationTitle("Rest defaults")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      let availableSounds = PreparedAmbience.availableIDs()
      rainAvailable = availableSounds.contains(PreparedAmbience.gentleRainID)
      draft = RestPreferences.load(availableAmbienceIDs: availableSounds)
    }
  }
}

struct BundledAudioView: View {
  let catalog: PreparedCatalog
  @State private var inventory: [AudioInventoryItem] = []
  @State private var scanRequestID = UUID()
  @State private var isChecking = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        RestHeading(
          "Ready on this phone",
          subtitle: "Prepared audio is included with Honkshool for offline rest.")
        if isChecking {
          Text("Checking bundled audio…")
            .font(.footnote)
            .foregroundStyle(RestStyle.secondary)
            .accessibilityIdentifier("inventoryChecking")
        }
        RestCard(title: "Narration", systemImage: "waveform") {
          ForEach(inventory.filter { $0.kind == .narration }) { item in
            inventoryRow(item)
          }
        }
        RestCard(title: "Sound", systemImage: "cloud.rain") {
          ForEach(inventory.filter { $0.kind == .ambience }) { item in
            inventoryRow(item)
          }
        }
        Button("Recheck bundled audio") { scanRequestID = UUID() }
          .buttonStyle(RestButtonStyle(secondary: true))
          .disabled(isChecking)
          .accessibilityIdentifier("recheckBundledAudio")
        Text("These recordings are part of the app. There is nothing to download or remove here.")
          .font(.footnote)
          .foregroundStyle(RestStyle.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, RestStyle.pageInset)
      .padding(.vertical, 24)
    }
    .restScreen()
    .navigationTitle("Bundled audio")
    .navigationBarTitleDisplayMode(.inline)
    .task(id: scanRequestID) {
      let requestID = scanRequestID
      isChecking = true
      let result = await AudioInventoryScanner.scanAsync(catalog: catalog)
      guard !Task.isCancelled, scanRequestID == requestID, let result else { return }
      inventory = result
      isChecking = false
    }
  }

  private func inventoryRow(_ item: AudioInventoryItem) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(item.title).font(.body.weight(.medium))
      Text(item.detail)
        .font(.footnote)
        .foregroundStyle(item.available ? RestStyle.secondary : RestStyle.error)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
  }
}

struct AudioInventoryItem: Identifiable, Equatable, Sendable {
  enum Kind: Equatable, Sendable { case narration, ambience }
  let id: String
  let title: String
  let kind: Kind
  let available: Bool
  let bytes: Int64?

  var detail: String {
    guard available else { return "Unavailable or could not be verified" }
    guard let bytes else { return "Ready offline" }
    return "Ready offline · \(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))"
  }
}

enum AudioInventoryScanner {
  /// Only the final immutable inventory crosses back to the view actor.
  static func scanAsync(
    catalog: PreparedCatalog,
    using scan: @escaping @Sendable (PreparedCatalog) -> [AudioInventoryItem] = {
      AudioInventoryScanner.scan(catalog: $0)
    }
  ) async -> [AudioInventoryItem]? {
    let worker = Task.detached(priority: .utility) { scan(catalog) }
    return await withTaskCancellationHandler {
      let result = await worker.value
      return Task<Never, Never>.isCancelled ? nil : result
    } onCancel: {
      worker.cancel()
    }
  }

  nonisolated static func scan(catalog: PreparedCatalog) -> [AudioInventoryItem] {
    let sessionIDs = catalog.journeys.flatMap(\.sessionIDs)
    var seen: Set<Session.ID> = []
    var result: [AudioInventoryItem] = []
    for id in sessionIDs where seen.insert(id).inserted {
      guard !Task<Never, Never>.isCancelled else { return result }
      guard let prepared = catalog.sessions[id] else { continue }
      let url = try? prepared.narrationURL()
      let verified: Bool
      if let url, let expected = prepared.narrationAsset?.sha256,
        let bytes = try? Data(contentsOf: url, options: .mappedIfSafe)
      {
        let hash = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
        verified = hash == expected
      } else {
        verified = false
      }
      guard !Task<Never, Never>.isCancelled else { return result }
      result.append(
        AudioInventoryItem(
          id: id, title: prepared.session.title, kind: .narration,
          available: verified, bytes: verified ? url.flatMap(fileSize) : nil))
    }
    guard !Task<Never, Never>.isCancelled else { return result }
    let rainURL = try? PreparedAmbience.resolve(id: PreparedAmbience.gentleRainID)
    guard !Task<Never, Never>.isCancelled else { return result }
    result.append(
      AudioInventoryItem(
        id: PreparedAmbience.gentleRainID, title: "Gentle rain", kind: .ambience,
        available: rainURL != nil, bytes: rainURL.flatMap(fileSize)))
    return result
  }

  private nonisolated static func fileSize(_ url: URL) -> Int64? {
    (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize.map(Int64.init)
  }
}

struct CurrentDetailView: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        RestHeading(
          "Current detail", subtitle: "A little more of how things work, told at a restful pace.")
        RestCard(title: "Prepared detail", systemImage: "checkmark.circle") {
          Text("Enthusiast")
            .font(.title3.weight(.medium))
          Text(
            "Both current sessions are prepared at Enthusiast detail. Their scripts and timing are fixed before you review a rest plan."
          )
          .foregroundStyle(RestStyle.secondary)
        }
        RestCard(title: "For another day", systemImage: "book.closed") {
          Text(
            "Other detail levels need their own prepared recordings. There is no detail choice to save yet."
          )
          .foregroundStyle(RestStyle.secondary)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, RestStyle.pageInset)
      .padding(.vertical, 24)
    }
    .restScreen()
    .navigationTitle("Current detail")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct NarrationVoiceView: View {
  let catalog: PreparedCatalog
  let canPreview: Bool
  @StateObject private var preview = NarrationPreviewController()

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        RestHeading(
          "A voice to settle with",
          subtitle: "Listen before your next rest. The sample plays only when you tap.")
        RestCard(title: "Current voice", systemImage: "checkmark.circle") {
          Text("George")
            .font(.title3.weight(.medium))
          Text("George reads the prepared narration in a warm, unhurried voice.")
            .foregroundStyle(RestStyle.secondary)
          if preview.isPreparing {
            Button("Cancel preview") { preview.stop() }
              .buttonStyle(RestButtonStyle(secondary: true))
              .accessibilityIdentifier("cancelVoicePreview")
          } else if preview.isPlaying {
            Button("Stop preview") { preview.stop() }
              .buttonStyle(RestButtonStyle(secondary: true))
              .accessibilityIdentifier("stopVoicePreview")
          } else {
            Button("Preview George") { preview.start(catalog: catalog, canPreview: canPreview) }
              .buttonStyle(RestButtonStyle(secondary: true))
              .disabled(!canPreview)
              .accessibilityIdentifier("previewGeorge")
          }
          Text(preview.status)
            .font(.footnote)
            .foregroundStyle(RestStyle.secondary)
            .accessibilityIdentifier("voicePreviewStatus")
        }
        if !canPreview {
          RestCard {
            Text("Finish the current rest or Feasibility Lab audio before previewing.")
              .foregroundStyle(RestStyle.secondary)
          }
        }
        Text(
          "George is the only prepared voice. Previewing does not change a plan or listening history."
        )
        .font(.footnote)
        .foregroundStyle(RestStyle.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, RestStyle.pageInset)
      .padding(.vertical, 24)
    }
    .restScreen()
    .navigationTitle("Narration voice")
    .navigationBarTitleDisplayMode(.inline)
    .onChange(of: canPreview) { _, allowed in
      if !allowed { preview.stop(reason: "Preview stopped because another audio session began.") }
    }
    .onDisappear { preview.stop() }
  }
}
