//
//  AreaBookWidgetLiveActivity.swift
//  AreaBookWidget
//
//  Created by Jona Turagavou on 7/17/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct AreaBookWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct AreaBookWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AreaBookWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension AreaBookWidgetAttributes {
    fileprivate static var preview: AreaBookWidgetAttributes {
        AreaBookWidgetAttributes(name: "World")
    }
}

extension AreaBookWidgetAttributes.ContentState {
    fileprivate static var smiley: AreaBookWidgetAttributes.ContentState {
        AreaBookWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: AreaBookWidgetAttributes.ContentState {
         AreaBookWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: AreaBookWidgetAttributes.preview) {
   AreaBookWidgetLiveActivity()
} contentStates: {
    AreaBookWidgetAttributes.ContentState.smiley
    AreaBookWidgetAttributes.ContentState.starEyes
}
