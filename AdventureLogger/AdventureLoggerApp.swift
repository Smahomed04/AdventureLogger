//
//  AdventureLoggerApp.swift
//  AdventureLogger
//
//  Created by Sa’d Mahomed on 3/10/2025.
//

import SwiftUI
import CoreData

@main
struct AdventureLoggerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
