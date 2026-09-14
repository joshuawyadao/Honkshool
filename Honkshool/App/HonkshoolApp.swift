import SwiftUI

@main
struct HonkshoolApp: App {
  init() {
    #if DEBUG
      UITestFixtures.preparePersistentState()
    #endif
  }

  var body: some Scene {
    WindowGroup {
      FeasibilityConsoleView()
    }
  }
}
