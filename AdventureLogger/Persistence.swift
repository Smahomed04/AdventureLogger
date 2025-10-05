//
//  Persistence.swift
//  AdventureLogger
//
//  Created by Sa’d Mahomed on 3/10/2025.
//

import CoreData
import CloudKit
import Combine

struct PersistenceController {
    static let shared = PersistenceController()

    // Sync status publisher for UI updates
    let syncStatusPublisher = PassthroughSubject<SyncStatus, Never>()

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
            // Enhanced CloudKit configuration
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("No persistent store description found")
            }

            // Enable persistent history tracking for sync
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

            // Configure CloudKit container options
            let cloudKitOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.adventurelogger")
            description.cloudKitContainerOptions = cloudKitOptions
        }

        container.loadPersistentStores(completionHandler: { [weak syncStatusPublisher] (storeDescription, error) in
            if let error = error as NSError? {
                syncStatusPublisher?.send(.error(error.localizedDescription))
                print("❌ Core Data error: \(error), \(error.userInfo)")

                // In production, handle gracefully instead of crash
                #if DEBUG
                fatalError("Unresolved error \(error), \(error.userInfo)")
                #endif
            } else {
                syncStatusPublisher?.send(.synced)
                print("✅ Core Data stores loaded successfully")
            }
        })

        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Setup notification observers for sync events
        setupSyncNotifications()
    }

    // MARK: - Sync Monitoring

    private func setupSyncNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak syncStatusPublisher] notification in
            guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else {
                return
            }

            switch event.type {
            case .setup:
                syncStatusPublisher?.send(.syncing)
                print("☁️ CloudKit setup started")
            case .import:
                syncStatusPublisher?.send(.syncing)
                print("⬇️ CloudKit import started")
            case .export:
                syncStatusPublisher?.send(.syncing)
                print("⬆️ CloudKit export started")
            @unknown default:
                break
            }

            if event.endDate != nil {
                if let error = event.error {
                    syncStatusPublisher?.send(.error(error.localizedDescription))
                    print("❌ CloudKit event error: \(error)")
                } else {
                    syncStatusPublisher?.send(.synced)
                    print("✅ CloudKit event completed successfully")
                }
            }
        }
    }

    // MARK: - Manual Sync

    func forceSyncToCloud() {
        syncStatusPublisher.send(.syncing)

        do {
            try container.viewContext.save()
            syncStatusPublisher.send(.synced)
        } catch {
            syncStatusPublisher.send(.error(error.localizedDescription))
            print("❌ Failed to save context: \(error)")
        }
    }

    // MARK: - Data Management

    func exportDataAsJSON() throws -> Data {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<Place> = Place.fetchRequest()
        let places = try context.fetch(fetchRequest)

        let exportData = places.map { place in
            PlaceExportModel(
                id: place.id?.uuidString ?? UUID().uuidString,
                name: place.name ?? "",
                category: place.category ?? "",
                latitude: place.latitude,
                longitude: place.longitude,
                address: place.address,
                placeDescription: place.placeDescription,
                isVisited: place.isVisited,
                visitedDate: place.visitedDate,
                rating: Int(place.rating),
                personalReflection: place.personalReflection,
                createdAt: place.createdAt,
                updatedAt: place.updatedAt
            )
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        return try encoder.encode(exportData)
    }

    func importDataFromJSON(_ data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let importData = try decoder.decode([PlaceExportModel].self, from: data)
        let context = container.viewContext

        for placeData in importData {
            let place = Place(context: context)
            place.id = UUID(uuidString: placeData.id) ?? UUID()
            place.name = placeData.name
            place.category = placeData.category
            place.latitude = placeData.latitude
            place.longitude = placeData.longitude
            place.address = placeData.address
            place.placeDescription = placeData.placeDescription
            place.isVisited = placeData.isVisited
            place.visitedDate = placeData.visitedDate
            place.rating = Int16(placeData.rating)
            place.personalReflection = placeData.personalReflection
            place.createdAt = placeData.createdAt ?? Date()
            place.updatedAt = placeData.updatedAt ?? Date()
        }

        try context.save()
        syncStatusPublisher.send(.synced)
    }
}

// MARK: - Sync Status

enum SyncStatus {
    case idle
    case syncing
    case synced
    case error(String)

    var description: String {
        switch self {
        case .idle: return "Ready"
        case .syncing: return "Syncing..."
        case .synced: return "Synced"
        case .error(let message): return "Error: \(message)"
        }
    }

    var icon: String {
        switch self {
        case .idle: return "icloud"
        case .syncing: return "icloud.and.arrow.up.and.down"
        case .synced: return "icloud.and.arrow.up"
        case .error: return "exclamationmark.icloud"
        }
    }
}

// MARK: - Export Model

struct PlaceExportModel: Codable {
    let id: String
    let name: String
    let category: String
    let latitude: Double
    let longitude: Double
    let address: String?
    let placeDescription: String?
    let isVisited: Bool
    let visitedDate: Date?
    let rating: Int
    let personalReflection: String?
    let createdAt: Date?
    let updatedAt: Date?
}
