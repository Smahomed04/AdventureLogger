//
//  Persistence.swift
//  AdventureLogger
//
//  Created by Sa’d Mahomed on 3/10/2025.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Sample data for preview
        let samplePlaces = [
            ("Bondi Beach", "Beach", -33.8908, 151.2743, "Beautiful coastal beach"),
            ("Blue Mountains", "Hike", -33.7320, 150.3114, "Stunning mountain trails"),
            ("Sydney Opera House", "Activity", -33.8568, 151.2153, "Iconic landmark"),
            ("Manly Beach", "Beach", -33.7969, 151.2871, "Perfect for surfing"),
            ("Royal National Park", "Hike", -34.1341, 151.0531, "Coastal walking tracks")
        ]

        for (name, category, lat, lon, desc) in samplePlaces {
            let newPlace = Place(context: viewContext)
            newPlace.id = UUID()
            newPlace.name = name
            newPlace.category = category
            newPlace.latitude = lat
            newPlace.longitude = lon
            newPlace.placeDescription = desc
            newPlace.isVisited = Bool.random()
            newPlace.createdAt = Date()
            newPlace.updatedAt = Date()
            if newPlace.isVisited {
                newPlace.visitedDate = Date()
                newPlace.rating = Int16.random(in: 1...5)
            }
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "AdventureLogger")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
