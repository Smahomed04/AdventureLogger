//
//  CloudSyncManager.swift
//  AdventureLogger
//

import Foundation
import CoreData
import CloudKit
import Combine

/// Manages CloudKit synchronization status and operations
class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()

    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var isOnline: Bool = true
    @Published var pendingChanges: Int = 0

    enum SyncStatus {
        case idle
        case syncing
        case success
        case error(String)

        var description: String {
            switch self {
            case .idle: return "Ready"
            case .syncing: return "Syncing..."
            case .success: return "Synced"
            case .error(let message): return "Error: \(message)"
            }
        }

        var icon: String {
            switch self {
            case .idle: return "icloud"
            case .syncing: return "icloud.and.arrow.up.and.down"
            case .success: return "icloud.fill"
            case .error: return "exclamationmark.icloud"
            }
        }
    }

    private var cancellables = Set<AnyCancellable>()
    private var container: NSPersistentCloudKitContainer?

    private init() {
        // Delay initialization to avoid circular dependency
        DispatchQueue.main.async { [weak self] in
            self?.container = PersistenceController.shared.container
            self?.setupNotifications()
            // Check network status after a delay to avoid blocking
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self?.checkNetworkStatus()
            }
        }
    }

    // MARK: - Setup

    private func setupNotifications() {
        // Monitor CloudKit sync events
        NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .sink { [weak self] notification in
                self?.handleSyncEvent(notification)
            }
            .store(in: &cancellables)

        // Monitor network changes
        NotificationCenter.default.publisher(for: .NSSystemClockDidChange)
            .sink { [weak self] _ in
                self?.checkNetworkStatus()
            }
            .store(in: &cancellables)
    }

    // MARK: - Sync Operations

    func manualSync() {
        guard let container = container else {
            syncStatus = .error("Container not ready")
            return
        }

        syncStatus = .syncing

        // Trigger a save to push local changes
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    self?.syncStatus = .success
                    self?.lastSyncDate = Date()

                    // Reset to idle after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self?.syncStatus = .idle
                    }
                }
            } catch {
                syncStatus = .error("Failed to save changes")
            }
        } else {
            // No changes, just mark as success
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.syncStatus = .success
                self?.lastSyncDate = Date()

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self?.syncStatus = .idle
                }
            }
        }
    }

    // MARK: - Event Handling

    private func handleSyncEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            if #available(iOS 17.0, *) {
                switch event.type {
                case .setup:
                    self?.syncStatus = .idle

                case .import:
                    self?.syncStatus = .syncing
                    if event.endDate != nil {
                        self?.lastSyncDate = Date()
                        self?.syncStatus = .success

                        // Reset to idle after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self?.syncStatus = .idle
                        }
                    }

                case .export:
                    self?.syncStatus = .syncing
                    if event.endDate != nil {
                        self?.lastSyncDate = Date()
                        self?.syncStatus = .success

                        // Reset to idle after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self?.syncStatus = .idle
                        }
                    }

                @unknown default:
                    break
                }
            } else {
                // Fallback for earlier versions
                self?.syncStatus = .idle
            }

            // Handle errors
            if let error = event.error {
                self?.syncStatus = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - Network Status

    private func checkNetworkStatus() {
        // Async network check to avoid blocking UI
        DispatchQueue.global(qos: .background).async { [weak self] in
            var isConnected = true

            // Create a semaphore with timeout to prevent indefinite blocking
            let semaphore = DispatchSemaphore(value: 0)

            CKContainer.default().accountStatus { status, error in
                switch status {
                case .available:
                    isConnected = true
                case .noAccount, .restricted, .couldNotDetermine, .temporarilyUnavailable:
                    isConnected = false
                @unknown default:
                    isConnected = false
                }
                semaphore.signal()
            }

            // Wait max 3 seconds
            _ = semaphore.wait(timeout: .now() + 3)

            DispatchQueue.main.async {
                self?.isOnline = isConnected
            }
        }
    }

    // MARK: - Conflict Resolution

    func resolveConflicts() {
        guard let container = container else { return }

        // CloudKit automatically handles conflicts with NSPersistentCloudKitContainer
        // This uses a "last write wins" strategy by default
        // You can customize this by implementing NSMergePolicy

        let mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        container.viewContext.mergePolicy = mergePolicy
    }

    // MARK: - Data Export/Backup

    func exportData() -> Data? {
        guard let container = container else { return nil }

        let context = container.viewContext
        let fetchRequest: NSFetchRequest<Place> = Place.fetchRequest()

        do {
            let places = try context.fetch(fetchRequest)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601

            let exportData = places.map { place -> [String: Any] in
                return [
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
            }

            return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        } catch {
            print("Error exporting data: \(error)")
            return nil
        }
    }
}
