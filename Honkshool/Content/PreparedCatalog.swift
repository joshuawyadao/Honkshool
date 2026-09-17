import Foundation

struct ContentSource: Decodable, Equatable, Sendable {
  let id: String
  let title: String
  let publisher: String
  let url: URL
}

struct NarrationParagraph: Decodable, Equatable, Sendable {
  let text: String
  let sourceIDs: [String]
}

/// Editorial guidance only. Applying substitutions later must preserve resume mapping.
struct PronunciationNote: Decodable, Equatable, Sendable {
  let term: String
  let guidance: String
}

struct PreparedSession: Equatable, Sendable {
  enum DetailLevel: String, Decodable, Sendable {
    case enthusiast
  }

  let session: Session
  let detailLevel: DetailLevel
  let language: String
  let summary: String
  let durationEstimateBasis: String
  let paragraphs: [NarrationParagraph]
  let sources: [ContentSource]
  let pronunciations: [PronunciationNote]
  /// Exact versioned script; citations and pronunciation notes never enter spoken text.
  let narration: String

  fileprivate init(_ content: SessionDocument) throws {
    session = try Session(
      id: content.id, revision: content.revision, title: content.title,
      estimatedDuration: content.estimatedDuration)
    detailLevel = content.detailLevel
    language = content.language
    summary = content.summary
    durationEstimateBasis = content.durationEstimateBasis
    paragraphs = content.paragraphs
    sources = content.sources
    pronunciations = content.pronunciations
    narration = paragraphs.map(\.text).joined(separator: "\n\n")

    guard validIdentifier(session.id), validIdentifier(session.revision),
      [session.title, language, summary, durationEstimateBasis].allSatisfy(hasText),
      !paragraphs.isEmpty, paragraphs.allSatisfy({ hasText($0.text) }), sources.count >= 2
    else { throw PreparedCatalogError.invalidContent(session.id) }

    let sourceIDs = Set(sources.map(\.id))
    guard sourceIDs.count == sources.count,
      Set(sources.map(\.url)).count == sources.count
    else { throw NapDomainError.duplicateIdentity }
    for source in sources {
      guard validIdentifier(source.id), hasText(source.title), hasText(source.publisher),
        source.url.scheme == "https", source.url.host?.isEmpty == false,
        source.url.user == nil, source.url.password == nil
      else { throw PreparedCatalogError.invalidContent("source: \(source.id)") }
    }
    for paragraph in paragraphs {
      guard Set(paragraph.sourceIDs).count == paragraph.sourceIDs.count,
        paragraph.sourceIDs.allSatisfy(sourceIDs.contains)
      else { throw PreparedCatalogError.invalidContent("citations: \(session.id)") }
    }
    guard Set(paragraphs.flatMap(\.sourceIDs)) == sourceIDs else {
      throw PreparedCatalogError.invalidContent("unused sources: \(session.id)")
    }
    for note in pronunciations {
      guard hasText(note.term), hasText(note.guidance),
        narration.range(of: note.term, options: .caseInsensitive) != nil
      else { throw PreparedCatalogError.invalidContent("pronunciation: \(session.id)") }
    }
  }

  /// Offsets refer to `narration`, never a display string with headings or citations.
  /// A checkpoint must start at an intact Character before the end of this revision.
  func narration(resumingAt point: ResumePoint) throws -> String {
    guard point.matches(session), point.utf16Offset >= 0,
      point.utf16Offset < narration.utf16.count
    else { throw NapDomainError.invalidResumePoint }
    let utf16Index = narration.utf16.index(
      narration.utf16.startIndex, offsetBy: point.utf16Offset)
    guard let index = String.Index(utf16Index, within: narration),
      narration.indices.contains(index)
    else { throw NapDomainError.invalidResumePoint }
    return String(narration[index...])
  }
}

/// Immutable, locally supplied content. Loading performs no network or clock reads.
struct PreparedCatalog: Equatable, Sendable {
  let journeys: [Journey]
  let sessions: [Session.ID: PreparedSession]
  let planningCatalog: NapCatalog

  init(data: Data) throws {
    let document = try JSONDecoder().decode(CatalogDocument.self, from: data)
    guard document.schemaVersion == 1 else {
      throw PreparedCatalogError.unsupportedSchema(document.schemaVersion)
    }
    guard !document.journeys.isEmpty, !document.sessions.isEmpty else {
      throw PreparedCatalogError.invalidContent("empty catalog")
    }
    let prepared = try document.sessions.map(PreparedSession.init)
    let journeys = try document.journeys.map { entry in
      guard validIdentifier(entry.id), hasText(entry.title), !entry.sessionIDs.isEmpty else {
        throw PreparedCatalogError.invalidContent("journey: \(entry.id)")
      }
      return try Journey(
        id: entry.id, title: entry.title, sessionIDs: entry.sessionIDs,
        nextJourneyIDs: entry.nextJourneyIDs)
    }
    let planningCatalog = try NapCatalog(journeys: journeys, sessions: prepared.map(\.session))
    // A published bundle is self-contained. Unprepared future content is omitted,
    // while the planning domain still supports missing content from other callers.
    for journey in journeys {
      guard journey.sessionIDs.allSatisfy({ planningCatalog.sessions[$0] != nil }),
        journey.nextJourneyIDs.allSatisfy({ planningCatalog.journeys[$0] != nil })
      else { throw PreparedCatalogError.invalidContent("references: \(journey.id)") }
    }
    guard Set(journeys.flatMap(\.sessionIDs)) == Set(planningCatalog.sessions.keys) else {
      throw PreparedCatalogError.invalidContent("unreachable sessions")
    }
    self.journeys = journeys
    sessions = Dictionary(uniqueKeysWithValues: prepared.map { ($0.session.id, $0) })
    self.planningCatalog = planningCatalog
  }

  static func load(bundle: Bundle = .main) throws -> PreparedCatalog {
    guard let url = bundle.url(forResource: "PreparedCatalog", withExtension: "json") else {
      throw PreparedCatalogError.missingBundledCatalog
    }
    return try PreparedCatalog(data: Data(contentsOf: url))
  }
}

enum PreparedCatalogError: Error, Equatable {
  case unsupportedSchema(Int)
  case invalidContent(String)
  case missingBundledCatalog
}

private func hasText(_ value: String) -> Bool {
  !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}

private func validIdentifier(_ value: String) -> Bool {
  hasText(value) && value == value.trimmingCharacters(in: .whitespacesAndNewlines)
}

private struct CatalogDocument: Decodable {
  let schemaVersion: Int
  let journeys: [JourneyDocument]
  let sessions: [SessionDocument]
}

private struct JourneyDocument: Decodable {
  let id: String
  let title: String
  let sessionIDs: [String]
  let nextJourneyIDs: [String]
}

private struct SessionDocument: Decodable {
  let id: String
  let revision: String
  let title: String
  let estimatedDuration: TimeInterval
  let detailLevel: PreparedSession.DetailLevel
  let language: String
  let summary: String
  let durationEstimateBasis: String
  let paragraphs: [NarrationParagraph]
  let sources: [ContentSource]
  let pronunciations: [PronunciationNote]
}
