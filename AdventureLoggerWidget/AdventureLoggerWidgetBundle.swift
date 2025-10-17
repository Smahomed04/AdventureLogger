//
//  AdventureLoggerWidgetBundle.swift
//  AdventureLoggerWidget
//
//  Created by Rifath Parveen on 15/10/2025.
//

import WidgetKit
import SwiftUI

@main
struct AdventureLoggerWidgetBundle: WidgetBundle {
    var body: some Widget {
        AdventureLoggerWidget()
        AdventureLoggerWidgetControl()
        AdventureLoggerWidgetLiveActivity()
    }
}
