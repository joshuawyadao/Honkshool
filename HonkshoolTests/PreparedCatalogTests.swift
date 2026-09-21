import AVFoundation
import CryptoKit
import XCTest

@testable import Honkshool

final class PreparedCatalogTests: XCTestCase {
  func testGeorgeNarrationAndProvenanceAreBundledAndMatchCatalog() throws {
    let catalog = try PreparedCatalog.load()
    let prepared = try XCTUnwrap(catalog.sessions["turning-fuel-into-motion"])
    let metadata = try XCTUnwrap(prepared.narrationAsset)
    let url = try prepared.narrationURL()
    let provenanceURL = try XCTUnwrap(
      Bundle.main.url(forResource: "GeorgeNarration-Provenance", withExtension: "json"))
    let provenance = try XCTUnwrap(
      JSONSerialization.jsonObject(with: Data(contentsOf: provenanceURL)) as? [String: Any])

    let hash = SHA256.hash(data: try Data(contentsOf: url)).map { String(format: "%02x", $0) }
      .joined()
    XCTAssertEqual(url.lastPathComponent, "\(metadata.resource).\(metadata.fileExtension)")
    XCTAssertEqual(metadata.sha256, hash)
    XCTAssertEqual(provenance["outputSHA256"] as? String, hash)
    XCTAssertEqual(provenance["voice"] as? String, "bm_george")
    XCTAssertEqual((provenance["speed"] as? NSNumber)?.doubleValue, 0.86)

    let audio = try AVAudioFile(forReading: url)
    XCTAssertEqual(audio.processingFormat.channelCount, 1)
    XCTAssertEqual(audio.processingFormat.sampleRate, 24_000)
    XCTAssertEqual(audio.length, (provenance["frames"] as? NSNumber)?.int64Value)
    XCTAssertEqual(metadata.duration, Double(audio.length) / audio.processingFormat.sampleRate)
    XCTAssertEqual(prepared.session.estimatedDuration, 730)
    XCTAssertLessThan(metadata.duration, prepared.session.estimatedDuration)
    XCTAssertLessThan(prepared.session.estimatedDuration - metadata.duration, 5)
  }

  func testRainCandidateAndProvenanceAreBundledAndDecodable() throws {
    let url = try XCTUnwrap(Bundle.main.url(forResource: "GentleRain", withExtension: "wav"))
    let provenanceURL = try XCTUnwrap(
      Bundle.main.url(forResource: "GentleRain-Provenance", withExtension: "json"))
    let provenance = try XCTUnwrap(
      JSONSerialization.jsonObject(with: Data(contentsOf: provenanceURL)) as? [String: Any])
    let hash = SHA256.hash(data: try Data(contentsOf: url)).map { String(format: "%02x", $0) }
      .joined()
    XCTAssertEqual(provenance["preparedSHA256"] as? String, hash)
    XCTAssertEqual(provenance["license"] as? String, "CC0-1.0")
    XCTAssertEqual(provenance["status"] as? String, "prepared-candidate-awaiting-listening")

    let audio = try AVAudioFile(forReading: url)
    let metadata = try XCTUnwrap(provenance["validation"] as? [String: Any])
    XCTAssertEqual(audio.processingFormat.channelCount, 1)
    XCTAssertEqual(audio.processingFormat.sampleRate, 44_100)
    XCTAssertEqual(audio.length, (metadata["frameCount"] as? NSNumber)?.int64Value)
    let buffer = try XCTUnwrap(
      AVAudioPCMBuffer(
        pcmFormat: audio.processingFormat, frameCapacity: AVAudioFrameCount(audio.length)))
    try audio.read(into: buffer)
    XCTAssertEqual(Int64(buffer.frameLength), audio.length)
    XCTAssertGreaterThan(buffer.frameLength, 0)
  }

  func testBundledCatalogLoadsPreparedJourneyAndSourceBackedNarration() throws {
    let catalog = try PreparedCatalog.load()
    let journey = try XCTUnwrap(catalog.journeys.first { $0.id == "how-a-car-works" })
    let prepared = try XCTUnwrap(catalog.sessions["turning-fuel-into-motion"])

    XCTAssertEqual(journey.sessionIDs.first, prepared.session.id)
    XCTAssertEqual(catalog.planningCatalog.sessions[prepared.session.id], prepared.session)
    XCTAssertEqual(prepared.detailLevel, .enthusiast)
    XCTAssertFalse(prepared.session.revision.isEmpty)
    XCTAssertFalse(prepared.summary.isEmpty)
    XCTAssertFalse(prepared.durationEstimateBasis.isEmpty)
    XCTAssertGreaterThan(prepared.session.estimatedDuration, 0)
    XCTAssertGreaterThanOrEqual(prepared.sources.count, 2)
    XCTAssertEqual(prepared.narration, prepared.paragraphs.map(\.text).joined(separator: "\n\n"))
    XCTAssertEqual(Set(prepared.paragraphs.flatMap(\.sourceIDs)), Set(prepared.sources.map(\.id)))
    for source in prepared.sources {
      XCTAssertEqual(source.url.scheme, "https")
      XCTAssertFalse(source.title.isEmpty)
      XCTAssertFalse(source.publisher.isEmpty)
      XCTAssertFalse(prepared.narration.contains(source.url.absoluteString))
    }
  }

  func testCitationsAndPronunciationGuidanceStayOutOfSpokenText() throws {
    let prepared = try preparedSession()

    XCTAssertEqual(
      prepared.narration,
      "A piston moves inside a cylinder.\n\nA crankshaft converts a push into rotation.")
    XCTAssertEqual(prepared.paragraphs[0].sourceIDs, ["engine-reference"])
    XCTAssertEqual(prepared.sources[0].publisher, "Engine reference publisher")
    XCTAssertEqual(prepared.pronunciations[0].guidance, "Keep the first syllable clear.")
    XCTAssertFalse(prepared.narration.contains("engine-reference"))
    XCTAssertFalse(prepared.narration.contains("Engine reference publisher"))
    XCTAssertFalse(prepared.narration.contains("Keep the first syllable clear."))
  }

  func testLoadingBundleWithoutPreparedCatalogReportsMissingResource() {
    XCTAssertThrowsError(try PreparedCatalog.load(bundle: Bundle(for: Self.self))) {
      XCTAssertEqual($0 as? PreparedCatalogError, .missingBundledCatalog)
    }
  }

  func testNarrationAssetLookupReportsAbsentMetadataAndMissingBundleFile() throws {
    let withoutAsset = try preparedSession()
    XCTAssertThrowsError(try withoutAsset.narrationURL()) {
      XCTAssertEqual($0 as? PreparedCatalogError, .missingNarrationAsset("session"))
    }

    let withAsset = try preparedSession(overrides: ["narrationAsset": narrationAssetDocument()])
    XCTAssertThrowsError(try withAsset.narrationURL(bundle: Bundle(for: Self.self))) {
      XCTAssertEqual(
        $0 as? PreparedCatalogError, .missingBundledNarration("Prepared-Narration"))
    }
  }

  func testInvalidNarrationAssetMetadataIsRejected() throws {
    let invalidAssets: [[String: Any]] = [
      narrationAssetDocument(overrides: ["resource": "../Narration"]),
      narrationAssetDocument(overrides: ["resource": "Narration.wav"]),
      narrationAssetDocument(overrides: ["fileExtension": "m4a"]),
      narrationAssetDocument(overrides: ["duration": 0.0]),
      narrationAssetDocument(overrides: ["duration": 300.1]),
      narrationAssetDocument(overrides: ["duration": 295.0]),
      narrationAssetDocument(overrides: ["sha256": "not-a-sha"]),
    ]
    for asset in invalidAssets {
      assertInvalidContent(
        try catalogData(sessions: [sessionDocument(overrides: ["narrationAsset": asset])]))
    }
  }

  func testDurationEstimatesAreConfigurableWithoutChangingIdentityOrNarration() throws {
    let original = try preparedSession()
    for estimate in [45.0, 390.5, 1_200.0] {
      let prepared = try preparedSession(overrides: ["estimatedDuration": estimate])

      XCTAssertEqual(prepared.session.id, original.session.id)
      XCTAssertEqual(prepared.session.revision, original.session.revision)
      XCTAssertEqual(prepared.narration, original.narration)
      XCTAssertEqual(prepared.session.estimatedDuration, estimate)
    }
  }

  func testNonpositiveDurationEstimatesAreRejected() throws {
    for estimate in [0.0, -1.0] {
      XCTAssertThrowsError(try preparedSession(overrides: ["estimatedDuration": estimate])) {
        XCTAssertEqual($0 as? NapDomainError, .invalidDuration)
      }
    }
  }

  func testMalformedJSONAndUnsupportedSchemaAreRejected() throws {
    XCTAssertThrowsError(try PreparedCatalog(data: Data("{not JSON}".utf8))) {
      XCTAssertTrue($0 is DecodingError)
    }
    XCTAssertThrowsError(try PreparedCatalog(data: catalogData(schemaVersion: 2))) {
      XCTAssertEqual($0 as? PreparedCatalogError, .unsupportedSchema(2))
    }
  }

  func testRequiredSessionFieldsCannotBeMissing() throws {
    for field in [
      "id", "revision", "title", "estimatedDuration", "detailLevel", "language", "summary",
      "durationEstimateBasis", "paragraphs", "sources", "pronunciations",
    ] {
      var content = sessionDocument()
      content.removeValue(forKey: field)
      XCTAssertThrowsError(try PreparedCatalog(data: catalogData(sessions: [content])), field) {
        XCTAssertTrue($0 is DecodingError, field)
      }
    }
  }

  func testEmptyCatalogJourneyAndScriptAreRejected() throws {
    let invalidDocuments = try [
      catalogData(journeys: []), catalogData(sessions: []),
      catalogData(journeys: [journeyDocument(overrides: ["sessionIDs": [String]()])]),
      catalogData(sessions: [sessionDocument(overrides: ["paragraphs": [[String: Any]]()])]),
    ]
    for data in invalidDocuments {
      assertInvalidContent(data)
    }
  }

  func testWhitespaceOnlyEditorialFieldsAreRejected() throws {
    for field in ["title", "language", "summary", "durationEstimateBasis"] {
      assertInvalidContent(
        try catalogData(sessions: [sessionDocument(overrides: [field: " \n\t"])]))
    }
    assertInvalidContent(
      try catalogData(journeys: [journeyDocument(overrides: ["title": " \n"])]))
    var paragraphs = paragraphDocuments()
    paragraphs[0]["text"] = " \n\t"
    assertInvalidContent(
      try catalogData(sessions: [sessionDocument(overrides: ["paragraphs": paragraphs])]))
    for field in ["title", "publisher"] {
      var sources = sourceDocuments()
      sources[0][field] = " \n\t"
      assertInvalidContent(
        try catalogData(sessions: [sessionDocument(overrides: ["sources": sources])]))
    }
  }

  func testIdentitiesWithSurroundingWhitespaceAreRejected() throws {
    for field in ["id", "revision"] {
      assertInvalidContent(
        try catalogData(sessions: [sessionDocument(overrides: [field: " spaced "])]))
    }
    assertInvalidContent(
      try catalogData(journeys: [journeyDocument(overrides: ["id": " journey "])]))
    var sources = sourceDocuments()
    sources[0]["id"] = " engine-reference "
    assertInvalidContent(
      try catalogData(sessions: [sessionDocument(overrides: ["sources": sources])]))
  }

  func testDuplicateJourneySessionAndSourceIdentitiesAreRejected() throws {
    var sources = sourceDocuments()
    sources[1]["id"] = sources[0]["id"]
    let duplicateDocuments = try [
      catalogData(journeys: [journeyDocument(), journeyDocument()]),
      catalogData(sessions: [sessionDocument(), sessionDocument()]),
      catalogData(sessions: [sessionDocument(overrides: ["sources": sources])]),
      catalogData(journeys: [journeyDocument(overrides: ["sessionIDs": ["session", "session"]])]),
    ]
    for data in duplicateDocuments {
      XCTAssertThrowsError(try PreparedCatalog(data: data)) {
        XCTAssertEqual($0 as? NapDomainError, .duplicateIdentity)
      }
    }
  }

  func testSourcesMustHaveDistinctURLsAndAtLeastTwoReferences() throws {
    var sources = sourceDocuments()
    sources[1]["url"] = sources[0]["url"]
    XCTAssertThrowsError(try preparedSession(overrides: ["sources": sources])) {
      XCTAssertEqual($0 as? NapDomainError, .duplicateIdentity)
    }
    assertInvalidContent(
      try catalogData(sessions: [sessionDocument(overrides: ["sources": [sourceDocuments()[0]]])]))
  }

  func testDanglingAndDuplicateParagraphCitationsAreRejected() throws {
    for references in [["unknown-source"], ["engine-reference", "engine-reference"]] {
      var paragraphs = paragraphDocuments()
      paragraphs[0]["sourceIDs"] = references
      assertInvalidContent(
        try catalogData(sessions: [sessionDocument(overrides: ["paragraphs": paragraphs])]))
    }
  }

  func testDanglingJourneySessionsAndNextJourneysAreRejected() throws {
    for overrides in [
      ["sessionIDs": ["unprepared-session"]], ["nextJourneyIDs": ["unprepared-journey"]],
    ] {
      assertInvalidContent(try catalogData(journeys: [journeyDocument(overrides: overrides)]))
    }
  }

  func testUnusedSourcesAndUnreachableSessionsAreRejected() throws {
    var paragraphs = paragraphDocuments()
    paragraphs[1]["sourceIDs"] = ["engine-reference"]
    assertInvalidContent(
      try catalogData(sessions: [sessionDocument(overrides: ["paragraphs": paragraphs])]))
    assertInvalidContent(
      try catalogData(sessions: [
        sessionDocument(), sessionDocument(overrides: ["id": "unreachable"]),
      ]))
  }

  func testSourceURLsMustBeAbsoluteHTTPSWithoutCredentials() throws {
    for url in [
      "http://example.org/reference", "/relative/reference", "https:///",
      "https://reader@example.org/reference", "https://reader:secret@example.org/reference",
    ] {
      var sources = sourceDocuments()
      sources[0]["url"] = url
      assertInvalidContent(
        try catalogData(sessions: [sessionDocument(overrides: ["sources": sources])]))
    }
  }

  func testPronunciationNotesMustReferToSpokenWordsAndMayBeOmittedAsAnEmptyList() throws {
    for note in [
      ["term": "flywheel", "guidance": "Say this smoothly."],
      ["term": " \n", "guidance": "Say this smoothly."],
      ["term": "piston", "guidance": " \n"],
    ] {
      assertInvalidContent(
        try catalogData(sessions: [sessionDocument(overrides: ["pronunciations": [note]])]))
    }
    let withoutNotes = try preparedSession(overrides: ["pronunciations": [[String: String]]()])
    XCTAssertTrue(withoutNotes.pronunciations.isEmpty)
    let uppercaseTerm = try preparedSession(
      overrides: ["pronunciations": [["term": "PISTON", "guidance": "Keep this natural."]]])
    XCTAssertEqual(uppercaseTerm.pronunciations[0].term, "PISTON")
  }

  func testResumeUsesExactUTF16PositionsWithinVersionedNarration() throws {
    let prepared = try unicodeSession()
    for suffix in [
      prepared.narration, "🚲 rolls past a cafe\u{301}.\n\nAnother paragraph begins.",
      "Another paragraph begins.",
    ] {
      let range = try XCTUnwrap(prepared.narration.range(of: suffix))
      let offset = prepared.narration[..<range.lowerBound].utf16.count
      let point = try ResumePoint(
        session: prepared.session, utf16Offset: offset, estimatedRemainingDuration: 20)

      XCTAssertEqual(try prepared.narration(resumingAt: point), suffix)
    }
  }

  func testResumeRejectsWrongSessionOrRevision() throws {
    let prepared = try preparedSession()
    for session in [
      try Session(
        id: "another-session", revision: "r1", title: "Another session", estimatedDuration: 20),
      try Session(id: "session", revision: "r2", title: "New revision", estimatedDuration: 20),
    ] {
      let point = try ResumePoint(session: session, utf16Offset: 0, estimatedRemainingDuration: 20)
      XCTAssertThrowsError(try prepared.narration(resumingAt: point)) {
        XCTAssertEqual($0 as? NapDomainError, .invalidResumePoint)
      }
    }
  }

  func testResumeRejectsEndOutOfBoundsAndSplitUnicodeCharacters() throws {
    let prepared = try unicodeSession()
    let emoji = try XCTUnwrap(prepared.narration.range(of: "🚲"))
    let accent = try XCTUnwrap(prepared.narration.range(of: "e\u{301}"))
    let invalidOffsets = [
      prepared.narration.utf16.count, prepared.narration.utf16.count + 1,
      prepared.narration[..<emoji.lowerBound].utf16.count + 1,
      prepared.narration[..<accent.lowerBound].utf16.count + 1,
    ]
    for offset in invalidOffsets {
      let point = try ResumePoint(
        session: prepared.session, utf16Offset: offset, estimatedRemainingDuration: 20)
      XCTAssertThrowsError(try prepared.narration(resumingAt: point), "UTF-16 offset \(offset)") {
        XCTAssertEqual($0 as? NapDomainError, .invalidResumePoint)
      }
    }
  }

  func testBundledSessionPlansAnExactFitWithInjectedTimeAndIdentity() throws {
    let catalog = try PreparedCatalog.load()
    let prepared = try XCTUnwrap(catalog.sessions["turning-fuel-into-motion"])
    let start = Date(timeIntervalSince1970: 1_000)
    let request = NapRequest(
      window: .duration(prepared.session.estimatedDuration),
      startingAt: SessionSelection(journeyID: "how-a-car-works", sessionID: prepared.session.id))

    let plan = try NapPlanner.makePlan(
      id: "prepared-exact-fit", request: request, startingAt: start, now: start,
      catalog: catalog.planningCatalog)

    XCTAssertEqual(plan.id, "prepared-exact-fit")
    XCTAssertEqual(plan.route.map(\.session), [prepared.session])
    XCTAssertEqual(plan.route.first?.estimatedStart, start)
    XCTAssertEqual(plan.route.first?.estimatedEnd, plan.deadline)
    XCTAssertEqual(plan.deadline, start.addingTimeInterval(prepared.session.estimatedDuration))
    XCTAssertEqual(plan.segments.map(\.kind), [.narration(routeIndex: 0)])
    XCTAssertEqual(plan.routeEndReason, .windowFilled)
  }

  func testBundledSessionTooLongForWindowFallsBackToSilence() throws {
    let catalog = try PreparedCatalog.load()
    let prepared = try XCTUnwrap(catalog.sessions["turning-fuel-into-motion"])
    let start = Date(timeIntervalSince1970: 1_000)
    let duration = prepared.session.estimatedDuration / 2
    let request = NapRequest(
      window: .duration(duration),
      startingAt: SessionSelection(journeyID: "how-a-car-works", sessionID: prepared.session.id))

    let plan = try NapPlanner.makePlan(
      id: "prepared-short-window", request: request, startingAt: start, now: start,
      catalog: catalog.planningCatalog)

    XCTAssertTrue(plan.route.isEmpty)
    XCTAssertEqual(plan.segments.map(\.kind), [.rest(.silence)])
    XCTAssertEqual(plan.segments.map(\.duration), [duration])
    XCTAssertEqual(plan.deadline, start.addingTimeInterval(duration))
    XCTAssertEqual(plan.routeEndReason, .nextSessionDoesNotFit)
    XCTAssertEqual(catalog.sessions[prepared.session.id], prepared)
  }

  private func preparedSession(overrides: [String: Any] = [:]) throws -> PreparedSession {
    let catalog = try PreparedCatalog(
      data: catalogData(sessions: [sessionDocument(overrides: overrides)]))
    return try XCTUnwrap(catalog.sessions["session"])
  }

  private func unicodeSession() throws -> PreparedSession {
    var paragraphs = paragraphDocuments()
    paragraphs[0]["text"] = "A 🚲 rolls past a cafe\u{301}."
    paragraphs[1]["text"] = "Another paragraph begins."
    return try preparedSession(overrides: [
      "paragraphs": paragraphs, "pronunciations": [[String: String]](),
    ])
  }

  private func catalogData(
    schemaVersion: Int = 1, journeys: [[String: Any]]? = nil, sessions: [[String: Any]]? = nil
  ) throws -> Data {
    try JSONSerialization.data(withJSONObject: [
      "schemaVersion": schemaVersion,
      "journeys": journeys ?? [journeyDocument()],
      "sessions": sessions ?? [sessionDocument()],
    ])
  }

  private func journeyDocument(overrides: [String: Any] = [:]) -> [String: Any] {
    [
      "id": "journey", "title": "A prepared journey", "sessionIDs": ["session"],
      "nextJourneyIDs": [String](),
    ].merging(overrides) { _, replacement in replacement }
  }

  private func sessionDocument(overrides: [String: Any] = [:]) -> [String: Any] {
    [
      "id": "session", "revision": "r1", "title": "A prepared session",
      "estimatedDuration": 300.0, "detailLevel": "enthusiast", "language": "en-US",
      "summary": "An overview of engine motion.",
      "durationEstimateBasis": "A configurable editorial estimate pending a full render.",
      "paragraphs": paragraphDocuments(), "sources": sourceDocuments(),
      "pronunciations": [["term": "piston", "guidance": "Keep the first syllable clear."]],
    ].merging(overrides) { _, replacement in replacement }
  }

  private func paragraphDocuments() -> [[String: Any]] {
    [
      ["text": "A piston moves inside a cylinder.", "sourceIDs": ["engine-reference"]],
      [
        "text": "A crankshaft converts a push into rotation.", "sourceIDs": ["mechanism-reference"],
      ],
    ]
  }

  private func narrationAssetDocument(overrides: [String: Any] = [:]) -> [String: Any] {
    [
      "resource": "Prepared-Narration", "fileExtension": "wav", "duration": 297.5,
      "sha256": String(repeating: "a", count: 64),
    ].merging(overrides) { _, replacement in replacement }
  }

  private func sourceDocuments() -> [[String: Any]] {
    [
      [
        "id": "engine-reference", "title": "Engine reference title",
        "publisher": "Engine reference publisher", "url": "https://example.org/engine",
      ],
      [
        "id": "mechanism-reference", "title": "Mechanism reference title",
        "publisher": "Mechanism reference publisher", "url": "https://example.org/mechanism",
      ],
    ]
  }

  private func assertInvalidContent(
    _ data: Data, file: StaticString = #filePath, line: UInt = #line
  ) {
    XCTAssertThrowsError(try PreparedCatalog(data: data), file: file, line: line) { error in
      guard case .invalidContent = error as? PreparedCatalogError else {
        return XCTFail("Expected invalid content, received \(error)", file: file, line: line)
      }
    }
  }
}
