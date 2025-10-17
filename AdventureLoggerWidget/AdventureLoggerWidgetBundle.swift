import WidgetKit
import SwiftUI

@main
struct AdventureLoggerWidgetBundle: WidgetBundle {
    var body: some Widget {
        AdventureLoggerWidget()

        if #available(iOS 18.0, *) {
            AdventureLoggerWidgetControl()
        }
        if #available(iOS 16.1, *) {
            AdventureLoggerWidgetLiveActivity()
        }
    }
}
