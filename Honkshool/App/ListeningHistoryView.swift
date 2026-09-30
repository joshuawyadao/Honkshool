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
      VStack(alignment: .leading, spacing: 20) {
        RestHeading("At your own pace.", subtitle: "Return to what played, whenever you like.")
        if let error = store.errorMessage {
          RestCard(title: "Listening history", systemImage: "exclamationmark.triangle") {
            Text(error)
              .foregroundStyle(RestStyle.error)
              .accessibilityIdentifier("historySaveError")
            Button("Retry saving") { store.retrySave() }
              .accessibilityIdentifier("retryHistorySave")
          }
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
            RestCard(title: "Ready to continue", systemImage: "play.circle") {
              if let title = catalog.sessions[next.sessionID]?.session.title {
                Text("Up next: \(title)")
                  .font(.subheadline)
                  .foregroundStyle(RestStyle.secondary)
                  .accessibilityIdentifier("historyNextSession")
              }
              NavigationLink {
                reviewDestination(next)
              } label: {
                Label("Continue listening", systemImage: "arrow.right.circle.fill")
                  .frame(maxWidth: .infinity)
              }
              .buttonStyle(RestButtonStyle())
              .disabled(!canStart)
              .accessibilityIdentifier("historyContinue")
            }
          } else if ListeningHistoryNavigation.allAvailableJourneysCompleted(
            in: catalog, history: store.history)
          {
            RestCard(title: "Available journey played through", systemImage: "checkmark.circle") {
              Text("New prepared content will appear here when available.")
                .foregroundStyle(RestStyle.secondary)
                .accessibilityIdentifier("historyJourneyComplete")
            }
          } else {
            Text("The next incomplete session is not currently available to play.")
              .foregroundStyle(RestStyle.secondary)
              .accessibilityIdentifier("historyContinueUnavailable")
          }
          ForEach(catalog.journeys, id: \.id) { journey in
            RestCard(title: journey.title, systemImage: "book") {
              Text(
                "\(store.history.completedSessionIDs(in: journey.id).count) of \(journey.sessionIDs.count) played through"
              )
              .font(.subheadline)
              .foregroundStyle(RestStyle.secondary)
              .accessibilityIdentifier("historyJourneyProgress")
            }
          }
          if store.entries.isEmpty {
            RestCard(title: "Nothing played yet", systemImage: "moon") {
              Text("After a rest, you can return to what you heard here.")
                .foregroundStyle(RestStyle.secondary)
            }
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
      .padding(.horizontal, RestStyle.pageInset)
      .padding(.vertical, 24)
    }
    .restScreen()
    .navigationTitle("History")
    .navigationBarTitleDisplayMode(.inline)
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
    return RestCard {
      Text(record.plannedSession.session.title)
        .font(.system(.title2, design: .rounded).weight(.medium))
      Text(
        entry.isCheckpoint
          ? "Last verified checkpoint" : record.isCompleted ? "Played through" : "Partly played"
      )
      .accessibilityIdentifier("historyOutcome")
      Text(
        (entry.isCheckpoint ? "Saved at " : "")
          + record.endedAt.formatted(date: .abbreviated, time: .shortened)
      )
      .foregroundStyle(RestStyle.secondary)
      if let captured = record.checkpointCapturedAt {
        Text("Position verified at \(captured.formatted(date: .abbreviated, time: .shortened))")
          .font(.footnote).foregroundStyle(RestStyle.secondary)
      }
      Text("Actually played: \(Self.duration(record.playedDuration))")
        .accessibilityIdentifier("historyPlayedDuration")
      if let resume {
        NavigationLink("Resume from \(Self.position(resume.resumePoint))") {
          reviewDestination(resume)
        }
        .buttonStyle(RestButtonStyle(secondary: true))
        .disabled(!canStart)
        .accessibilityIdentifier("historyResume")
      } else if record.resumePoint != nil {
        Text(
          "This checkpoint cannot resume because its content changed or is unavailable. You can start a new review when current audio is available."
        )
        .font(.footnote)
        .foregroundStyle(RestStyle.secondary)
        .accessibilityIdentifier("historyResumeUnavailable")
      }
      if let replay {
        NavigationLink("Replay from start") { reviewDestination(replay) }
          .buttonStyle(RestButtonStyle(secondary: true))
          .disabled(!canStart)
          .accessibilityIdentifier("historyReplay")
      }
    }
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
