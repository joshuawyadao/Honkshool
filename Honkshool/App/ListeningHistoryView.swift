import SwiftUI

/// Navigation decisions use the current prepared catalog, never a historical title or duration.
enum ListeningHistoryNavigation {
  static func resume(
    _ record: PlaybackRecord, in catalog: PreparedCatalog,
    isNarrationAvailable: (PreparedSession) -> Bool
  ) -> SessionSelection? {
    guard let point = record.resumePoint,
      let selection = selection(
        for: record, in: catalog, isNarrationAvailable: isNarrationAvailable),
      let prepared = catalog.sessions[selection.sessionID],
      (try? prepared.validateAudioResumePoint(point)) != nil
    else { return nil }
    return SessionSelection(
      journeyID: selection.journeyID, sessionID: selection.sessionID, resumePoint: point)
  }

  static func replay(
    _ record: PlaybackRecord, in catalog: PreparedCatalog,
    isNarrationAvailable: (PreparedSession) -> Bool
  ) -> SessionSelection? {
    selection(for: record, in: catalog, isNarrationAvailable: isNarrationAvailable)
  }

  static func next(
    in catalog: PreparedCatalog, history: ListeningHistory,
    isNarrationAvailable: (PreparedSession) -> Bool
  ) -> SessionSelection? {
    for journey in catalog.journeys {
      guard let sessionID = history.nextSessionID(in: journey) else { continue }
      if let recentPartial = history.records.filter({ record in
        record.plannedSession.journeyID == journey.id
          && record.plannedSession.session.id == sessionID
          && resume(record, in: catalog, isNarrationAvailable: isNarrationAvailable) != nil
      }).max(by: { $0.endedAt < $1.endedAt }) {
        return resume(recentPartial, in: catalog, isNarrationAvailable: isNarrationAvailable)
      }
      guard let prepared = catalog.sessions[sessionID], isNarrationAvailable(prepared)
      else { continue }
      return SessionSelection(journeyID: journey.id, sessionID: sessionID)
    }
    return nil
  }

  static func allAvailableJourneysCompleted(
    in catalog: PreparedCatalog, history: ListeningHistory
  ) -> Bool {
    catalog.journeys.allSatisfy { history.nextSessionID(in: $0) == nil }
  }

  private static func selection(
    for record: PlaybackRecord, in catalog: PreparedCatalog,
    isNarrationAvailable: (PreparedSession) -> Bool
  ) -> SessionSelection? {
    let journeyID = record.plannedSession.journeyID
    let sessionID = record.plannedSession.session.id
    guard let journey = catalog.journeys.first(where: { $0.id == journeyID }),
      journey.sessionIDs.contains(sessionID), let prepared = catalog.sessions[sessionID],
      isNarrationAvailable(prepared)
    else { return nil }
    return SessionSelection(journeyID: journeyID, sessionID: sessionID)
  }
}

struct ListeningHistoryView: View {
  @ObservedObject var store: ListeningHistoryStore
  let canStart: Bool
  let isNarrationAvailable: (PreparedSession) -> Bool
  let reviewDestination: (SessionSelection) -> NapPlanReviewView

  @State private var catalog: PreparedCatalog?
  @State private var loadError: String?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        if let error = store.errorMessage {
          Label(error, systemImage: "exclamationmark.triangle")
            .foregroundStyle(.red)
            .accessibilityIdentifier("historySaveError")
          Button("Retry saving") { store.retrySave() }
            .accessibilityIdentifier("retryHistorySave")
        }
        if let loadError {
          ContentUnavailableView(
            "History unavailable", systemImage: "book.closed", description: Text(loadError)
          )
          .accessibilityIdentifier("historyCatalogError")
        } else if store.errorMessage != nil && store.entries.isEmpty {
          ContentUnavailableView(
            "Listening history unavailable", systemImage: "externaldrive.badge.exclamationmark",
            description: Text(
              "Saved progress could not be read. Try again before choosing where to continue.")
          )
          .accessibilityIdentifier("historyStoreUnavailable")
        } else if let catalog {
          if let next = ListeningHistoryNavigation.next(
            in: catalog, history: store.history, isNarrationAvailable: isNarrationAvailable)
          {
            NavigationLink {
              reviewDestination(next)
            } label: {
              Label("Continue listening", systemImage: "arrow.right.circle.fill")
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canStart)
            .accessibilityIdentifier("historyContinue")
          } else if ListeningHistoryNavigation.allAvailableJourneysCompleted(
            in: catalog, history: store.history)
          {
            Text(
              "Available journey complete. New prepared content will appear here when available."
            )
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("historyJourneyComplete")
          } else {
            Text("The next incomplete session is not currently available to play.")
              .foregroundStyle(.secondary)
              .accessibilityIdentifier("historyContinueUnavailable")
          }
          ForEach(catalog.journeys, id: \.id) { journey in
            Text(
              "\(journey.title): \(store.history.completedSessionIDs(in: journey.id).count) of \(journey.sessionIDs.count) completed"
            )
            .font(.subheadline)
            .accessibilityIdentifier("historyJourneyProgress")
          }
          if store.entries.isEmpty {
            ContentUnavailableView(
              "No listening history yet", systemImage: "clock.arrow.circlepath")
          } else {
            ForEach(store.entries) { entry in
              entryCard(entry, catalog: catalog)
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
    .navigationTitle("Listening History")
    .task {
      guard catalog == nil && loadError == nil else { return }
      do { catalog = try PreparedCatalog.load() } catch {
        loadError = "The prepared catalog could not be loaded. \(error.localizedDescription)"
      }
    }
  }

  private func entryCard(_ entry: ListeningHistoryEntry, catalog: PreparedCatalog) -> some View {
    let record = entry.record
    let resume = ListeningHistoryNavigation.resume(
      record, in: catalog, isNarrationAvailable: isNarrationAvailable)
    let replay = ListeningHistoryNavigation.replay(
      record, in: catalog, isNarrationAvailable: isNarrationAvailable)
    return VStack(alignment: .leading, spacing: 8) {
      Text(record.plannedSession.session.title).font(.headline)
      Text(
        entry.isCheckpoint
          ? "Last verified checkpoint" : record.isCompleted ? "Completed" : "Partial"
      )
      .accessibilityIdentifier("historyOutcome")
      Text(record.endedAt.formatted(date: .abbreviated, time: .shortened))
      Text("Actually played: \(Self.duration(record.playedDuration))")
        .accessibilityIdentifier("historyPlayedDuration")
      if let resume {
        NavigationLink("Resume from \(Self.position(resume.resumePoint))") {
          reviewDestination(resume)
        }
        .disabled(!canStart)
        .accessibilityIdentifier("historyResume")
      } else if record.resumePoint != nil {
        Text(
          "This checkpoint cannot resume because its content changed or is unavailable. You can start a new review when current audio is available."
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
        .accessibilityIdentifier("historyResumeUnavailable")
      }
      if let replay {
        NavigationLink("Replay from start") { reviewDestination(replay) }
          .disabled(!canStart)
          .accessibilityIdentifier("historyReplay")
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(.background, in: RoundedRectangle(cornerRadius: 18))
  }

  static func duration(_ seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds.rounded(.down)))
    return "\(total / 60)m \(total % 60)s"
  }

  static func position(_ point: ResumePoint?) -> String {
    guard let point else { return "start" }
    if let seconds = point.audioOffset { return duration(seconds) }
    return "saved script position"
  }
}
