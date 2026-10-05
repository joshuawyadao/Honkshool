import ActivityKit
import SwiftUI
import WidgetKit

struct RestCountdownActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: RestActivityAttributes.self) { context in
      RestCountdownLayout(presentation: presentation(context))
        .foregroundStyle(RestStyle.ink)
        .activityBackgroundTint(RestStyle.background)
    } dynamicIsland: { context in
      let presentation = presentation(context)
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label("Rest", systemImage: "moon")
        }
        DynamicIslandExpandedRegion(.trailing) {
          RestCountdownTimer(presentation: presentation)
            .font(.title2)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 4) {
            RestCountdownEnding(deadline: context.state.deadline)
            Text(presentation.playbackLabel)
            Text(presentation.alarmLabel).font(.footnote)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      } compactLeading: {
        Image(systemName: "moon")
      } compactTrailing: {
        RestCountdownTimer(presentation: presentation)
          .frame(maxWidth: 64)
      } minimal: {
        Image(systemName: "moon")
      }
    }
  }

  private func presentation(
    _ context: ActivityViewContext<RestActivityAttributes>
  ) -> RestCountdownPresentation {
    RestCountdownPresentation(
      state: context.state, isStale: context.isStale || context.state.deadline <= .now)
  }
}
