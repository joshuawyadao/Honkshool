import Foundation
import XCTest

@testable import Honkshool

final class AudioInventoryTests: XCTestCase {
  func testScannerVerifiesCurrentBundledNarrationAndRain() async throws {
    let catalog = try PreparedCatalog.load()
    let scanned = await AudioInventoryScanner.scanAsync(catalog: catalog)
    let inventory = try XCTUnwrap(scanned)

    XCTAssertEqual(
      inventory.map(\.id),
      catalog.journeys.flatMap(\.sessionIDs) + [PreparedAmbience.gentleRainID])
    XCTAssertEqual(inventory.filter { $0.kind == .narration }.count, 2)
    XCTAssertEqual(inventory.last?.kind, .ambience)
    XCTAssertTrue(inventory.allSatisfy { $0.available && ($0.bytes ?? 0) > 0 })
  }

  @MainActor
  func testInjectedScanRunsOffMainThread() async throws {
    let catalog = try PreparedCatalog.load()
    let scanned = await AudioInventoryScanner.scanAsync(catalog: catalog) { _ in
      [
        AudioInventoryItem(
          id: "thread-check", title: "Thread check", kind: .narration,
          available: !Thread.isMainThread, bytes: nil)
      ]
    }
    let inventory = try XCTUnwrap(scanned)
    XCTAssertTrue(inventory[0].available)
  }

  func testCancelledDelayedScanCannotPublishResult() async throws {
    let catalog = try PreparedCatalog.load()
    let started = expectation(description: "Delayed inventory scan started")
    let gate = ScanGate()
    defer { gate.release.signal() }
    let task = Task {
      await AudioInventoryScanner.scanAsync(catalog: catalog) { _ in
        started.fulfill()
        gate.release.wait()
        return [
          AudioInventoryItem(
            id: "stale", title: "Stale result", kind: .narration,
            available: true, bytes: 1)
        ]
      }
    }
    await fulfillment(of: [started], timeout: 5)
    let fresh = await AudioInventoryScanner.scanAsync(catalog: catalog) { _ in
      [
        AudioInventoryItem(
          id: "fresh", title: "Fresh result", kind: .narration,
          available: true, bytes: 2)
      ]
    }
    XCTAssertEqual(fresh?.map(\.id), ["fresh"])
    task.cancel()
    gate.release.signal()
    let result = await task.value
    XCTAssertNil(result)
  }
}

private final class ScanGate: @unchecked Sendable {
  let release = DispatchSemaphore(value: 0)
}
