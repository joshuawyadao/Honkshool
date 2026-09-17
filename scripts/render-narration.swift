#!/usr/bin/env swift  // Development-only Mac renderer. Run interpreted with the installed system voice.
import AVFoundation
import CryptoKit
import Foundation

private let usage = """
  Usage: swift scripts/render-narration.swift CATALOG.json SESSION_ID OUTPUT_DIRECTORY

  Render each complete paragraph to PCM CAF with the installed Aaron voice used for
  Honkshool's audition reference. OUTPUT_DIRECTORY must not exist; its parent must
  exist. Produces manifest.json only after every paragraph finishes successfully.
  No playback, resampling, filtering, added pauses, or duration-estimate changes.
  A failed run may leave partial audio in its new directory, without a manifest.
  """

private struct Catalog: Decodable {
  let schemaVersion: Int
  let sessions: [ScriptSession]
}
private struct ScriptSession: Decodable {
  let id: String
  let revision: String
  let paragraphs: [Paragraph]
}
private struct Paragraph: Decodable { let text: String }
private struct RenderFailure: LocalizedError {
  let message: String
  var errorDescription: String? { message }
}
private func fail(_ message: String) -> RenderFailure { RenderFailure(message: message) }
private func sha256(_ text: String) -> String {
  SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
}

private struct VoiceRecord: Encodable {
  let identifier: String
  let name: String
  let quality: Int
  let rate: Float
  let pitchMultiplier: Float
  let volume: Float
}
private struct ParagraphRecord: Encodable {
  let index: Int
  let fileName: String
  let textSHA256: String
  let textUTF16Count: Int
  let frameCount: Int64
  let sampleRate: Double
  let channelCount: UInt32
  let durationSeconds: Double
}
private struct Manifest: Encodable {
  let schemaVersion = 1
  let sessionID: String
  let revision: String
  let scriptSHA256: String
  let scriptUTF16Count: Int
  let voice: VoiceRecord
  let paragraphs: [ParagraphRecord]
}

// Callback state is protected by lock; synthesizer methods run only in render().
private final class ParagraphRenderer: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
  private let synth = AVSpeechSynthesizer()
  private let lock = NSLock()
  private var file: AVAudioFile?
  private var format: AVAudioFormat?
  private var frames: Int64 = 0
  private var finished = false
  private var sealed = false
  private var failure: String?
  private var lastBufferTime = ProcessInfo.processInfo.systemUptime

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance)
  {
    lock.lock()
    defer { lock.unlock() }
    if !sealed { finished = true }
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance)
  {
    lock.lock()
    defer { lock.unlock() }
    if !sealed { failure = "Synthesis was cancelled." }
  }

  private func accept(_ buffer: AVAudioBuffer, at url: URL) {
    lock.lock()
    defer { lock.unlock() }
    guard !sealed, failure == nil else { return }
    lastBufferTime = ProcessInfo.processInfo.systemUptime
    guard let pcm = buffer as? AVAudioPCMBuffer else {
      failure = "Synthesizer returned a non-PCM buffer."
      return
    }
    // An empty buffer is not evidence that synthesis completed.
    guard pcm.frameLength > 0 else { return }
    do {
      if let format, !format.isEqual(pcm.format) {
        throw fail("Audio format changed within a paragraph.")
      }
      if file == nil {
        guard pcm.format.sampleRate > 0, pcm.format.channelCount > 0 else {
          throw fail("Invalid audio format.")
        }
        format = pcm.format
        file = try AVAudioFile(
          forWriting: url, settings: pcm.format.settings,
          commonFormat: pcm.format.commonFormat, interleaved: pcm.format.isInterleaved)
      }
      guard let file else { throw fail("Audio file was not created.") }
      try file.write(from: pcm)
      frames += Int64(pcm.frameLength)
    } catch {
      failure = error.localizedDescription
    }
  }

  func render(_ text: String, index: Int, voice: AVSpeechSynthesisVoice, to url: URL) throws
    -> ParagraphRecord
  {
    synth.delegate = self
    defer { synth.delegate = nil }
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = voice
    utterance.rate = 0.45
    utterance.pitchMultiplier = 1
    utterance.volume = 1
    synth.write(utterance) { [weak self] buffer in self?.accept(buffer, at: url) }
    let deadline = ProcessInfo.processInfo.systemUptime + 180
    while true {
      RunLoop.current.run(until: Date().addingTimeInterval(0.05))
      lock.lock()
      let now = ProcessInfo.processInfo.systemUptime
      let done = finished && now - lastBufferTime >= 0.5
      if failure == nil, now >= deadline {
        failure = "Synthesis exceeded the 180-second paragraph timeout."
      }
      if failure != nil || done {
        sealed = true
        file = nil  // Close the writer before publishing its frame count.
        let error = failure
        let completed = finished
        let recordedFrames = frames
        let recordedFormat = format
        lock.unlock()
        if let error {
          synth.stopSpeaking(at: .immediate)
          throw fail(error)
        }
        guard completed, recordedFrames > 0, let recordedFormat else {
          throw fail("Synthesis finished without usable audio.")
        }
        return ParagraphRecord(
          index: index, fileName: url.lastPathComponent, textSHA256: sha256(text),
          textUTF16Count: text.utf16.count, frameCount: recordedFrames,
          sampleRate: recordedFormat.sampleRate, channelCount: recordedFormat.channelCount,
          durationSeconds: Double(recordedFrames) / recordedFormat.sampleRate)
      }
      lock.unlock()
    }
  }
}

private func main() throws {
  let args = CommandLine.arguments
  if args.count == 2, ["--help", "-h"].contains(args[1]) {
    print(usage)
    return
  }
  guard args.count == 4 else { throw fail(usage) }
  let catalog = try JSONDecoder().decode(
    Catalog.self, from: Data(contentsOf: URL(fileURLWithPath: args[1])))
  guard catalog.schemaVersion == 1 else { throw fail("Unsupported catalog schema.") }
  let matches = catalog.sessions.filter { $0.id == args[2] }
  guard matches.count == 1, let session = matches.first else {
    throw fail("Session ID must match exactly one catalog session.")
  }
  guard !session.revision.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
    !session.paragraphs.isEmpty,
    session.paragraphs.allSatisfy({
      !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    })
  else { throw fail("Session revision and every paragraph must be nonempty.") }
  let identifier = "com.apple.siri.natural.Aaron"
  guard let voice = AVSpeechSynthesisVoice(identifier: identifier), voice.identifier == identifier
  else {
    throw fail("Required voice is unavailable: \(identifier). No substitute was selected.")
  }
  let output = URL(fileURLWithPath: args[3], isDirectory: true)
  // Reject existing output rather than combining this run with earlier audio.
  guard !FileManager.default.fileExists(atPath: output.path) else {
    throw fail("Output directory already exists.")
  }
  let created = output.withUnsafeFileSystemRepresentation { path in
    guard let path else { return Int32(-1) }
    return mkdir(path, 0o755)
  }
  guard created == 0 else {
    throw fail(
      "Could not create a new output directory: \(NSError(domain: NSPOSIXErrorDomain, code: Int(errno)).localizedDescription)"
    )
  }
  var records: [ParagraphRecord] = []
  for (index, paragraph) in session.paragraphs.enumerated() {
    let fileName = String(format: "paragraph-%03d.caf", index + 1)
    let renderer = ParagraphRenderer()
    let record = try withExtendedLifetime(renderer) {
      try renderer.render(
        paragraph.text, index: index, voice: voice, to: output.appendingPathComponent(fileName))
    }
    records.append(record)
    print(
      "Rendered \(fileName): \(record.frameCount) frames, \(String(format: "%.2f", record.durationSeconds)) seconds"
    )
  }
  let script = session.paragraphs.map(\.text).joined(separator: "\n\n")
  let manifest = Manifest(
    sessionID: session.id, revision: session.revision, scriptSHA256: sha256(script),
    scriptUTF16Count: script.utf16.count,
    voice: VoiceRecord(
      identifier: voice.identifier, name: voice.name, quality: voice.quality.rawValue, rate: 0.45,
      pitchMultiplier: 1, volume: 1),
    paragraphs: records)
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  try encoder.encode(manifest).write(
    to: output.appendingPathComponent("manifest.json"), options: .atomic)
}

do { try main() } catch {
  FileHandle.standardError.write(Data("Render failed: \(error.localizedDescription)\n".utf8))
  exit(1)
}
