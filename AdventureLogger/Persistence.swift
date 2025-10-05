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
        } else {
            // Configure CloudKit options for production
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("Failed to retrieve persistent store description")
            }

            // Enable remote change notifications
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

            // Enable history tracking for sync
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
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

        // Configure view context for optimal CloudKit sync
        container.viewContext.automaticallyMergesChangesFromParent = true

        // Set merge policy to handle conflicts (last write wins)
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        // Enable undo manager for better data integrity
        container.viewContext.undoManager = UndoManager()
    }

    // MARK: - Data Management

    /// Save the view context with error handling
    func saveContext() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    /// Clear all data from the persistent store
    func clearAllData() throws {
        let context = container.viewContext

        // Fetch all Place entities
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Place.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        try context.execute(deleteRequest)
        try context.save()
    }

    /// Export all data as JSON
    func exportData() -> Data? {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<Place> = Place.fetchRequest()

        do {
            let places = try context.fetch(fetchRequest)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted

            let exportData = places.map { place -> [String: Any] in
                var dict: [String: Any] = [
                    "id": place.id?.uuidString ?? "",
                    "name": place.name ?? "",
                    "category": place.category ?? "",
                    "latitude": place.latitude,
                    "longitude": place.longitude,
                    "address": place.address ?? "",
                    "description": place.placeDescription ?? "",
                    "isVisited": place.isVisited,
                    "rating": place.rating,
                    "personalReflection": place.personalReflection ?? "",
                    "createdAt": place.createdAt?.timeIntervalSince1970 ?? 0,
                    "updatedAt": place.updatedAt?.timeIntervalSince1970 ?? 0
                ]
                if let visitedDate = place.visitedDate {
                    dict["visitedDate"] = visitedDate.timeIntervalSince1970
                }
                return dict
            }

            return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        } catch {
            print("Error exporting data: \(error)")
            return nil
        }
    }
}
