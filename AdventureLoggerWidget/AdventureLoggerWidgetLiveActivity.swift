//
//  AdventureLoggerWidgetLiveActivity.swift
//  AdventureLoggerWidget
//
//  Created by Rifath Parveen on 15/10/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct AdventureLoggerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct AdventureLoggerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AdventureLoggerWidgetAttributes.self) { context in
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

extension AdventureLoggerWidgetAttributes {
    fileprivate static var preview: AdventureLoggerWidgetAttributes {
        AdventureLoggerWidgetAttributes(name: "World")
    }
}

extension AdventureLoggerWidgetAttributes.ContentState {
    fileprivate static var smiley: AdventureLoggerWidgetAttributes.ContentState {
        AdventureLoggerWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: AdventureLoggerWidgetAttributes.ContentState {
         AdventureLoggerWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: AdventureLoggerWidgetAttributes.preview) {
   AdventureLoggerWidgetLiveActivity()
} contentStates: {
    AdventureLoggerWidgetAttributes.ContentState.smiley
    AdventureLoggerWidgetAttributes.ContentState.starEyes
}
