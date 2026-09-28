import AVFoundation
import CryptoKit
import Foundation

enum PreparedAmbienceError: Error, Equatable {
  case unknownID(String)
  case missingResource(String)
  case invalidProvenance
  case invalidAudio
}

/// A deliberately small allowlist: a sound is selectable only when the accepted
/// provenance and the exact prepared PCM are both present in this bundle.
enum PreparedAmbience {
  static let gentleRainID = "gentle-rain-window"

  private static let fileName = "GentleRain.wav"
  private static let acceptedSHA256 =
    "060a5183311a297c7370607d50902f054240b280dde54e00a278e90e692438c5"
  private static let acceptedFrames: AVAudioFramePosition = 435_102

  static func displayName(for id: String) -> String {
    id == gentleRainID ? "Gentle rain" : id
  }

  static func availableIDs(bundle: Bundle = .main) -> Set<String> {
    (try? resolve(id: gentleRainID, bundle: bundle)) == nil ? [] : [gentleRainID]
  }

  static func resolve(id: String, bundle: Bundle = .main) throws -> URL {
    guard id == gentleRainID else { throw PreparedAmbienceError.unknownID(id) }
    guard let url = bundle.url(forResource: "GentleRain", withExtension: "wav"),
      let provenanceURL = bundle.url(
        forResource: "GentleRain-Provenance", withExtension: "json")
    else { throw PreparedAmbienceError.missingResource(id) }

    let provenance: Provenance
    do {
      provenance = try JSONDecoder().decode(Provenance.self, from: Data(contentsOf: provenanceURL))
    } catch { throw PreparedAmbienceError.invalidProvenance }
    guard provenance.schemaVersion == 1, provenance.id == id,
      provenance.fileName == fileName, provenance.status == "accepted-for-playback",
      provenance.preparedSHA256 == acceptedSHA256,
      provenance.validation.frameCount == Int(acceptedFrames),
      provenance.validation.sampleRate == 44_100,
      provenance.validation.channelCount == 1,
      provenance.validation.bitsPerSample == 16
    else { throw PreparedAmbienceError.invalidProvenance }

    do {
      let hash = SHA256.hash(data: try Data(contentsOf: url, options: .mappedIfSafe))
        .map { String(format: "%02x", $0) }.joined()
      guard hash == acceptedSHA256 else { throw PreparedAmbienceError.invalidAudio }

      let audio = try AVAudioFile(forReading: url)
      let format = audio.fileFormat
      guard audio.length == acceptedFrames,
        format.sampleRate == 44_100, format.channelCount == 1,
        (format.settings[AVLinearPCMBitDepthKey] as? NSNumber)?.intValue == 16,
        (format.settings[AVLinearPCMIsFloatKey] as? NSNumber)?.boolValue == false
      else { throw PreparedAmbienceError.invalidAudio }
    } catch { throw PreparedAmbienceError.invalidAudio }
    return url
  }

  private struct Provenance: Decodable {
    let schemaVersion: Int
    let id: String
    let fileName: String
    let status: String
    let preparedSHA256: String
    let validation: Validation

    struct Validation: Decodable {
      let frameCount: Int
      let sampleRate: Int
      let channelCount: Int
      let bitsPerSample: Int
    }
  }
}
