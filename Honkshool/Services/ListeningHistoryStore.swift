import Combine
import Foundation
import SwiftData

@MainActor
protocol NapHistoryRecording: AnyObject {
  func save(_ record: PlaybackRecord, isCheckpoint: Bool)
}

struct ListeningHistoryEntry: Identifiable, Equatable {
  let record: PlaybackRecord
  let isCheckpoint: Bool
  var id: PlaybackRecord.ID { record.id }
}

// Versioned independently of the Foundation domain so a future migration can read old evidence.
enum ListeningHistorySchemaV1: VersionedSchema {
  static var versionIdentifier: Schema.Version { .init(1, 0, 0) }
  static var models: [any PersistentModel.Type] { [StoredPlayback.self] }

  @Model final class StoredPlayback {
    @Attribute(.unique) var key: String
    var payload: Data
    var isCheckpoint: Bool
    var endedAt: Date

    init(key: String, payload: Data, isCheckpoint: Bool, endedAt: Date) {
      self.key = key
      self.payload = payload
      self.isCheckpoint = isCheckpoint
      self.endedAt = endedAt
    }
  }
}

enum ListeningHistoryMigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] { [ListeningHistorySchemaV1.self] }
  static var stages: [MigrationStage] { [] }
}

@MainActor
final class ListeningHistoryStore: ObservableObject, NapHistoryRecording {
  @Published private(set) var entries: [ListeningHistoryEntry] = []
  @Published private(set) var errorMessage: String?

  var history: ListeningHistory {
    var result = ListeningHistory()
    for entry in entries.reversed() {
      try? result.append(entry.record)
    }
    return result
  }

  private var container: ModelContainer?
  private var context: ModelContext?
  private let storeURL: URL?
  private let inMemoryOnly: Bool
  private var pending: [PlaybackRecord.ID: ListeningHistoryEntry] = [:]
  private var loadFailed = false
  // Test seam for an I/O failure between staging and the explicit transaction save.
  var beforeSave: (() throws -> Void)?
  private typealias StoredPlayback = ListeningHistorySchemaV1.StoredPlayback

  init(storeURL: URL? = nil, inMemoryOnly: Bool = false) {
    self.storeURL = storeURL ?? (inMemoryOnly ? nil : Self.defaultURL())
    self.inMemoryOnly = inMemoryOnly
    openStore()
  }

  private func openStore() {
    do {
      let schema = Schema(versionedSchema: ListeningHistorySchemaV1.self)
      let configuration: ModelConfiguration
      if inMemoryOnly {
        configuration = ModelConfiguration(
          schema: schema, isStoredInMemoryOnly: true,
          cloudKitDatabase: .none)
      } else {
        let url = storeURL!
        try FileManager.default.createDirectory(
          at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
      }
      let container = try ModelContainer(
        for: schema, migrationPlan: ListeningHistoryMigrationPlan.self,
        configurations: [configuration])
      let context = ModelContext(container)
      context.autosaveEnabled = false
      self.container = container
      self.context = context
      try reload(from: context)
      loadFailed = false
      errorMessage = nil
    } catch {
      container = nil
      context = nil
      loadFailed = true
      errorMessage = "Listening history could not be opened: \(error.localizedDescription)"
    }
  }

  func save(_ record: PlaybackRecord, isCheckpoint: Bool) {
    guard !isCheckpoint || !record.isCompleted else {
      errorMessage = "Completed playback cannot be saved as a checkpoint."
      return
    }
    let entry = ListeningHistoryEntry(record: record, isCheckpoint: isCheckpoint)
    guard shouldAccept(entry, over: pending[record.id]) else { return }
    guard shouldAccept(entry, over: entries.first(where: { $0.id == record.id })) else {
      pending.removeValue(forKey: record.id)
      return
    }
    pending[record.id] = entry
    retrySave()
  }

  func retrySave() {
    if context == nil || loadFailed { openStore() }
    guard let context, !loadFailed else {
      if !pending.isEmpty && errorMessage == nil {
        errorMessage = "Listening history is unavailable; new progress has not been saved."
      }
      return
    }
    let queued = pending.values.sorted { $0.record.endedAt < $1.record.endedAt }
    for entry in queued {
      do {
        let key = Self.key(for: entry.id)
        let descriptor = FetchDescriptor<StoredPlayback>(predicate: #Predicate { $0.key == key })
        let matching = try context.fetch(descriptor)
        guard matching.count <= 1 else { throw StoreError.duplicateKey }
        if let stored = matching.first {
          let old = try decode(stored)
          guard shouldAccept(entry, over: old) else {
            pending.removeValue(forKey: entry.id)
            continue
          }
          stored.payload = try JSONEncoder().encode(Payload(entry.record))
          stored.isCheckpoint = entry.isCheckpoint
          stored.endedAt = entry.record.endedAt
        } else {
          context.insert(
            StoredPlayback(
              key: key, payload: try JSONEncoder().encode(Payload(entry.record)),
              isCheckpoint: entry.isCheckpoint, endedAt: entry.record.endedAt))
        }
        try beforeSave?()
        try context.save()
        pending.removeValue(forKey: entry.id)
      } catch {
        context.rollback()
        errorMessage = "Listening progress could not be saved: \(error.localizedDescription)"
        return
      }
    }
    do {
      try reload(from: context)
      errorMessage = nil
    } catch {
      errorMessage = "Listening history could not be read: \(error.localizedDescription)"
    }
  }

  private func reload(from context: ModelContext) throws {
    let stored = try context.fetch(FetchDescriptor<StoredPlayback>())
    var decoded: [ListeningHistoryEntry] = []
    var keys: Set<String> = []
    for row in stored {
      guard keys.insert(row.key).inserted else { throw StoreError.duplicateKey }
      decoded.append(try decode(row))
    }
    entries = decoded.sorted {
      if $0.record.endedAt == $1.record.endedAt {
        return Self.key(for: $0.id) > Self.key(for: $1.id)
      }
      return $0.record.endedAt > $1.record.endedAt
    }
  }

  private func decode(_ stored: StoredPlayback) throws -> ListeningHistoryEntry {
    let record = try JSONDecoder().decode(Payload.self, from: stored.payload).restore()
    guard stored.key == Self.key(for: record.id), stored.endedAt == record.endedAt,
      !stored.isCheckpoint || !record.isCompleted
    else { throw StoreError.invalidEvidence }
    return ListeningHistoryEntry(record: record, isCheckpoint: stored.isCheckpoint)
  }

  private func shouldAccept(_ next: ListeningHistoryEntry, over old: ListeningHistoryEntry?) -> Bool
  {
    guard let old else { return true }
    guard old.isCheckpoint else { return false }
    guard next.record.planID == old.record.planID,
      next.record.plannedSession == old.record.plannedSession,
      next.record.startedAt == old.record.startedAt,
      next.record.playedDuration >= old.record.playedDuration
    else { return false }
    if let priorPoint = old.record.resumePoint, let nextPoint = next.record.resumePoint {
      guard nextPoint.isAtOrAfter(priorPoint) else { return false }
    }
    if next.isCheckpoint {
      return next.record.endedAt > old.record.endedAt
    }
    return next.record.endedAt >= old.record.endedAt
  }

  private static func key(for id: PlaybackRecord.ID) -> String {
    "\(id.runID.utf8.count):\(id.runID):\(id.routeIndex)"
  }

  private static func defaultURL() -> URL {
    let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[
      0]
    return support.appendingPathComponent("Honkshool/ListeningHistory.store")
  }

  private enum StoreError: LocalizedError {
    case duplicateKey, invalidEvidence
    var errorDescription: String? {
      switch self {
      case .duplicateKey: "Duplicate playback evidence in local history."
      case .invalidEvidence: "Invalid playback evidence in local history."
      }
    }
  }
}

// Explicit storage DTO. All restored domain values pass through validating initializers.
private struct Payload: Codable {
  struct SessionValue: Codable {
    let id: String
    let revision: String
    let title: String
    let estimatedDuration: TimeInterval
    init(_ value: Session) {
      id = value.id
      revision = value.revision
      title = value.title
      estimatedDuration = value.estimatedDuration
    }
    func restore() throws -> Session {
      try Session(id: id, revision: revision, title: title, estimatedDuration: estimatedDuration)
    }
  }
  struct ResumeValue: Codable {
    let sessionID: String
    let revision: String
    let utf16Offset: Int?
    let audioOffset: TimeInterval?
    let audioAssetSHA256: String?
    let estimatedRemainingDuration: TimeInterval
    init(_ value: ResumePoint) {
      sessionID = value.sessionID
      revision = value.revision
      utf16Offset = value.utf16Offset
      audioOffset = value.audioOffset
      audioAssetSHA256 = value.audioAssetSHA256
      estimatedRemainingDuration = value.estimatedRemainingDuration
    }
    func restore(for session: Session) throws -> ResumePoint {
      guard session.id == sessionID, session.revision == revision else {
        throw NapDomainError.invalidResumePoint
      }
      if let utf16Offset, audioOffset == nil {
        return try ResumePoint(
          session: session, utf16Offset: utf16Offset,
          estimatedRemainingDuration: estimatedRemainingDuration)
      }
      if let audioOffset, utf16Offset == nil {
        return try ResumePoint(
          session: session, audioOffset: audioOffset,
          estimatedRemainingDuration: estimatedRemainingDuration,
          audioAssetSHA256: audioAssetSHA256)
      }
      throw NapDomainError.invalidResumePoint
    }
  }
  let runID: String
  let routeIndex: Int
  let planID: String
  let journeyID: String
  let session: SessionValue
  let plannedResume: ResumeValue?
  let estimatedStart: Date
  let estimatedEnd: Date
  let startedAt: Date
  let endedAt: Date
  let checkpointCapturedAt: Date?
  let playedDuration: TimeInterval
  let completed: Bool
  let partialReason: String?
  let finalResume: ResumeValue?

  init(_ record: PlaybackRecord) {
    runID = record.id.runID
    routeIndex = record.id.routeIndex
    planID = record.planID
    journeyID = record.plannedSession.journeyID
    session = SessionValue(record.plannedSession.session)
    plannedResume = record.plannedSession.resumePoint.map(ResumeValue.init)
    estimatedStart = record.plannedSession.estimatedStart
    estimatedEnd = record.plannedSession.estimatedEnd
    startedAt = record.startedAt
    endedAt = record.endedAt
    checkpointCapturedAt = record.checkpointCapturedAt
    playedDuration = record.playedDuration
    switch record.outcome {
    case .completed:
      completed = true
      partialReason = nil
      finalResume = nil
    case .partial(let reason, let point):
      completed = false
      switch reason {
      case .stopped: partialReason = "stopped"
      case .interrupted: partialReason = "interrupted"
      case .deadlineReached: partialReason = "deadlineReached"
      case .deadlineMissed: partialReason = "deadlineMissed"
      }
      finalResume = ResumeValue(point)
    }
  }

  func restore() throws -> PlaybackRecord {
    let restoredSession = try session.restore()
    let planned = PlannedSession(
      journeyID: journeyID, session: restoredSession,
      resumePoint: try plannedResume?.restore(for: restoredSession),
      estimatedStart: estimatedStart, estimatedEnd: estimatedEnd)
    let outcome: PlaybackOutcome
    if completed {
      guard partialReason == nil, finalResume == nil else {
        throw NapDomainError.invalidPlaybackTime
      }
      outcome = .completed
    } else {
      guard let finalResume, let partialReason else { throw NapDomainError.invalidPlaybackTime }
      let reason: PartialPlaybackReason
      switch partialReason {
      case "stopped": reason = .stopped
      case "interrupted": reason = .interrupted
      case "deadlineReached": reason = .deadlineReached
      case "deadlineMissed": reason = .deadlineMissed
      default: throw NapDomainError.invalidPlaybackTime
      }
      outcome = .partial(reason: reason, resumePoint: try finalResume.restore(for: restoredSession))
    }
    return try PlaybackRecord(
      restoringID: .init(runID: runID, routeIndex: routeIndex), planID: planID,
      plannedSession: planned, startedAt: startedAt, endedAt: endedAt,
      checkpointCapturedAt: checkpointCapturedAt, playedDuration: playedDuration,
      outcome: outcome)
  }
}
