import SwiftUI

/// Browsing a prepared session never begins playback. The caller reviews the selection first.
struct RestSessionPickerView: View {
  let catalog: PreparedCatalog
  @ObservedObject var historyStore: ListeningHistoryStore
  let isAvailable: (PreparedSession) -> Bool
  let onChoose: (SessionSelection) -> Void

  init(
    catalog: PreparedCatalog, historyStore: ListeningHistoryStore,
    isAvailable: @escaping (PreparedSession) -> Bool,
    onChoose: @escaping (SessionSelection) -> Void
  ) {
    self.catalog = catalog
    self.historyStore = historyStore
    self.isAvailable = isAvailable
    self.onChoose = onChoose
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        RestHeading(
          "What to hear", subtitle: catalog.journeys.map(\.title).joined(separator: " · "))
        if let error = historyStore.errorMessage {
          Text("Saved progress is unavailable. \(error)")
            .font(.footnote)
            .foregroundStyle(RestStyle.secondary)
        }
        ForEach(catalog.journeys, id: \.id) { journey in
          ForEach(Array(journey.sessionIDs.enumerated()), id: \.element) { index, sessionID in
            if let prepared = catalog.sessions[sessionID] {
              sessionCard(prepared, journey: journey, number: index + 1)
            }
          }
        }
        Text("Your choice is reviewed before anything plays.")
          .font(.footnote)
          .foregroundStyle(RestStyle.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, RestStyle.pageInset)
      .padding(.vertical, 24)
    }
    .restScreen()
    .navigationTitle("Sessions")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func sessionCard(
    _ prepared: PreparedSession, journey: Journey, number: Int
  ) -> some View {
    let available = isAvailable(prepared)
    let latest = RestContentHistory.latestEntry(
      for: prepared.session.id, in: journey.id, entries: historyStore.entries)
    let saved =
      available && historyStore.errorMessage == nil
      ? latest.flatMap {
        ListeningHistoryNavigation.resume(
          $0.record, in: catalog, isNarrationAvailable: isAvailable)
      }
      : nil
    return RestCard {
      Text("Session \(number)")
        .font(.subheadline.weight(.medium))
        .foregroundStyle(RestStyle.secondary)
      Text(prepared.session.title)
        .font(.system(.title2, design: .rounded).weight(.medium))
        .fixedSize(horizontal: false, vertical: true)
      Text(
        "\(RestContentHistory.duration(prepared.session.estimatedDuration)) · \(RestContentHistory.status(latest, saved: saved, available: available))"
      )
      .foregroundStyle(RestStyle.secondary)
      .fixedSize(horizontal: false, vertical: true)
      if let saved {
        Button("Continue from \(ListeningHistoryView.position(saved.resumePoint))") {
          onChoose(saved)
        }
        .buttonStyle(RestButtonStyle())
        .accessibilityIdentifier("chooseSession-\(prepared.session.id)")
        Button("Choose from the beginning") {
          onChoose(SessionSelection(journeyID: journey.id, sessionID: prepared.session.id))
        }
        .buttonStyle(RestButtonStyle(secondary: true))
      } else {
        Button("Choose this session") {
          onChoose(SessionSelection(journeyID: journey.id, sessionID: prepared.session.id))
        }
        .buttonStyle(RestButtonStyle())
        .disabled(!available)
        .accessibilityIdentifier("chooseSession-\(prepared.session.id)")
      }
      NavigationLink {
        RestSessionDetailView(
          prepared: prepared, journey: journey, resumePoint: saved?.resumePoint,
          isAvailable: available, onChoose: onChoose)
      } label: {
        Label("About this session", systemImage: "arrow.right")
          .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
      }
      .accessibilityIdentifier("sessionDetails-\(prepared.session.id)")
    }
  }
}

struct RestSessionDetailView: View {
  let prepared: PreparedSession
  let journey: Journey
  let resumePoint: ResumePoint?
  let isAvailable: Bool
  let canChoose: Bool
  let onChoose: (SessionSelection) -> Void

  init(
    prepared: PreparedSession, journey: Journey, resumePoint: ResumePoint?,
    isAvailable: Bool, canChoose: Bool = true, onChoose: @escaping (SessionSelection) -> Void
  ) {
    self.prepared = prepared
    self.journey = journey
    self.resumePoint = resumePoint
    self.isAvailable = isAvailable
    self.canChoose = canChoose
    self.onChoose = onChoose
  }

  private var validResumePoint: ResumePoint? {
    guard isAvailable, let resumePoint,
      (try? prepared.validateAudioResumePoint(resumePoint)) != nil
    else { return nil }
    return resumePoint
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text(journey.title)
          .font(.subheadline.weight(.medium))
          .foregroundStyle(RestStyle.secondary)
        RestHeading(prepared.session.title, subtitle: prepared.summary)
        RestCard {
          detailRow(
            "Full narration", RestContentHistory.duration(prepared.session.estimatedDuration))
          detailRow(
            "Your place",
            validResumePoint.map { ListeningHistoryView.position($0) }
              ?? (resumePoint == nil ? "Beginning" : "Saved place unavailable"))
          detailRow("Prepared audio", isAvailable ? "Ready offline" : "Unavailable")
        }
        if !canChoose {
          Text(
            "Finish current playback and handle any active wake alarm before making another plan."
          )
          .foregroundStyle(RestStyle.secondary).accessibilityIdentifier("sessionPlanningBlocked")
        }
        if let validResumePoint {
          Button("Use your saved place") {
            onChoose(
              SessionSelection(
                journeyID: journey.id, sessionID: prepared.session.id,
                resumePoint: validResumePoint))
          }
          .buttonStyle(RestButtonStyle())
          .disabled(!canChoose)
          .accessibilityIdentifier("sessionUseSavedPlace")
        }
        Button("Choose from the beginning") {
          onChoose(SessionSelection(journeyID: journey.id, sessionID: prepared.session.id))
        }
        .buttonStyle(RestButtonStyle(secondary: validResumePoint != nil))
        .disabled(!isAvailable || !canChoose)
        .accessibilityIdentifier("sessionChooseBeginning")
        NavigationLink {
          RestSessionNotesView(prepared: prepared)
        } label: {
          Label("Notes and sources", systemImage: "text.book.closed")
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
        .accessibilityIdentifier("openSessionNotes")
        Text("Nothing plays until you approve your nap plan.")
          .font(.footnote)
          .foregroundStyle(RestStyle.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, RestStyle.pageInset)
      .padding(.vertical, 24)
    }
    .restScreen()
    .navigationTitle("Session")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func detailRow(_ title: String, _ value: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title).font(.subheadline).foregroundStyle(RestStyle.secondary)
      Text(value).font(.body.weight(.medium))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// The source associations are the catalog's editorial metadata, not spoken narration.
private struct RestSessionNotesView: View {
  let prepared: PreparedSession

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        RestHeading(prepared.session.title, subtitle: "Notes and sources to revisit while awake.")
        RestCard(title: "The idea") {
          Text(prepared.summary)
            .fixedSize(horizontal: false, vertical: true)
        }
        RestCard(title: "In this session") {
          ForEach(Array(prepared.paragraphs.enumerated()), id: \.offset) { _, paragraph in
            VStack(alignment: .leading, spacing: 8) {
              Text(paragraph.text)
                .fixedSize(horizontal: false, vertical: true)
              ForEach(paragraph.sourceIDs, id: \.self) { sourceID in
                if let source = prepared.sources.first(where: { $0.id == sourceID }) {
                  Link(destination: source.url) {
                    Label("\(source.title) · \(source.publisher)", systemImage: "arrow.up.right")
                      .font(.footnote)
                      .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                  }
                }
              }
            }
            .padding(.vertical, 8)
          }
        }
        RestCard(title: "Sources") {
          ForEach(prepared.sources, id: \.id) { source in
            Link(destination: source.url) {
              Label {
                VStack(alignment: .leading, spacing: 4) {
                  Text(source.title).font(.body.weight(.medium))
                  Text(source.publisher).font(.footnote).foregroundStyle(RestStyle.secondary)
                }
              } icon: {
                Image(systemName: "arrow.up.right")
              }
              .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, RestStyle.pageInset)
      .padding(.vertical, 24)
    }
    .restScreen()
    .navigationTitle("Notes and sources")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct RestLibraryView: View {
  let catalog: PreparedCatalog
  @ObservedObject var historyStore: ListeningHistoryStore
  let isAvailable: (PreparedSession) -> Bool
  let canPlan: Bool
  let reviewDestination: (SessionSelection) -> NapPlanReviewView

  @State private var reviewSelection: SessionSelection?

  init(
    catalog: PreparedCatalog, historyStore: ListeningHistoryStore,
    isAvailable: @escaping (PreparedSession) -> Bool, canPlan: Bool,
    reviewDestination: @escaping (SessionSelection) -> NapPlanReviewView
  ) {
    self.catalog = catalog
    self.historyStore = historyStore
    self.isAvailable = isAvailable
    self.canPlan = canPlan
    self.reviewDestination = reviewDestination
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        RestHeading("Quiet journeys", subtitle: "Choose a prepared session, then make a nap plan.")
        if let error = historyStore.errorMessage {
          Text("Saved progress is unavailable. \(error)")
            .font(.footnote)
            .foregroundStyle(RestStyle.secondary)
        }
        ForEach(catalog.journeys, id: \.id) { journey in
          RestCard {
            Text(journey.title)
              .font(.system(.title2, design: .rounded).weight(.medium))
            Text(
              "\(historyStore.history.completedSessionIDs(in: journey.id).count) of \(journey.sessionIDs.count) played through"
            )
            .foregroundStyle(RestStyle.secondary)
            NavigationLink {
              journeyDetail(journey)
            } label: {
              Label("View journey", systemImage: "arrow.right")
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, RestStyle.pageInset)
      .padding(.vertical, 24)
    }
    .restScreen()
    .navigationTitle("Journeys")
    .navigationBarTitleDisplayMode(.inline)
    .navigationDestination(
      isPresented: Binding(
        get: { reviewSelection != nil },
        set: { if !$0 { reviewSelection = nil } }
      )
    ) {
      if let reviewSelection { reviewDestination(reviewSelection) }
    }
  }

  private func journeyDetail(_ journey: Journey) -> some View {
    let completed = historyStore.history.completedSessionIDs(in: journey.id)
    let nextID = historyStore.history.nextSessionID(in: journey)
    return ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        RestHeading(
          journey.title,
          subtitle:
            "Follow the ideas in order, one restful session at a time. There is no pace to keep.")
        RestCard(title: "Your place") {
          Text("\(completed.count) of \(journey.sessionIDs.count) played through")
            .foregroundStyle(RestStyle.secondary)
          ForEach(Array(journey.sessionIDs.enumerated()), id: \.element) { index, sessionID in
            if let prepared = catalog.sessions[sessionID] {
              let latest = RestContentHistory.latestEntry(
                for: sessionID, in: journey.id, entries: historyStore.entries)
              let saved =
                historyStore.errorMessage == nil
                ? latest.flatMap {
                  ListeningHistoryNavigation.resume(
                    $0.record, in: catalog, isNarrationAvailable: isAvailable)
                }
                : nil
              VStack(alignment: .leading, spacing: 8) {
                Text("\(index + 1). \(prepared.session.title)")
                  .font(.body.weight(.medium))
                Text(
                  completed.contains(sessionID)
                    ? "Played"
                    : RestContentHistory.status(
                      latest, saved: saved, available: isAvailable(prepared))
                      + (sessionID == nextID ? " · Next" : "")
                )
                .font(.subheadline)
                .foregroundStyle(RestStyle.secondary)
                NavigationLink {
                  RestSessionDetailView(
                    prepared: prepared, journey: journey, resumePoint: saved?.resumePoint,
                    isAvailable: isAvailable(prepared), canChoose: canPlan, onChoose: choose)
                } label: {
                  Label("About \(prepared.session.title)", systemImage: "arrow.right")
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
              }
              .padding(.vertical, 8)
            }
          }
        }
        if let nextID, let prepared = catalog.sessions[nextID] {
          let latest = RestContentHistory.latestEntry(
            for: nextID, in: journey.id, entries: historyStore.entries)
          let saved =
            historyStore.errorMessage == nil
            ? latest.flatMap {
              ListeningHistoryNavigation.resume(
                $0.record, in: catalog, isNarrationAvailable: isAvailable)
            }
            : nil
          Button("Plan your next rest") {
            choose(saved ?? SessionSelection(journeyID: journey.id, sessionID: nextID))
          }
          .buttonStyle(RestButtonStyle())
          .disabled(!canPlan || !isAvailable(prepared))
        }
        Text("Your selection opens a fresh plan review before anything plays.")
          .font(.footnote)
          .foregroundStyle(RestStyle.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, RestStyle.pageInset)
      .padding(.vertical, 24)
    }
    .restScreen()
    .navigationTitle(journey.title)
    .navigationBarTitleDisplayMode(.inline)
  }

  private func choose(_ selection: SessionSelection) {
    guard canPlan, let prepared = catalog.sessions[selection.sessionID],
      isAvailable(prepared)
    else { return }
    reviewSelection = selection
  }
}

private enum RestContentHistory {
  static func latestEntry(
    for sessionID: Session.ID, in journeyID: Journey.ID,
    entries: [ListeningHistoryEntry]
  ) -> ListeningHistoryEntry? {
    entries.filter {
      $0.record.plannedSession.journeyID == journeyID
        && $0.record.plannedSession.session.id == sessionID
    }.max { $0.record.endedAt < $1.record.endedAt }
  }

  static func duration(_ seconds: TimeInterval) -> String {
    "About \(Int((seconds / 60).rounded(.up))) min"
  }

  static func status(
    _ entry: ListeningHistoryEntry?, saved: SessionSelection?, available: Bool
  ) -> String {
    guard available else { return "Audio unavailable" }
    guard let entry else { return "Ready offline · Not played yet" }
    if entry.record.isCompleted { return "Played" }
    if saved != nil { return "Your place is saved" }
    if entry.record.resumePoint != nil { return "Saved place unavailable" }
    return "Partly played"
  }
}
