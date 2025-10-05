# Cloud and Local Data Management Documentation

## Overview
AdventureLogger implements a robust local and cloud-based data management system using **Core Data** with **CloudKit** integration through `NSPersistentCloudKitContainer`.

## Architecture

### 1. Local Data Storage (Core Data)
- **Framework**: Core Data with SQLite backend
- **Location**: `Persistence.swift`
- **Features**:
  - Persistent storage on device
  - Efficient querying with `NSFetchRequest`
  - Relationship management between entities
  - Automatic schema migrations
  - Undo/Redo support with `UndoManager`

### 2. Cloud Synchronization (CloudKit)
- **Framework**: CloudKit via `NSPersistentCloudKitContainer`
- **Location**: `Persistence.swift`, `CloudSyncManager.swift`
- **Features**:
  - Automatic bidirectional sync between devices
  - Background sync operations
  - Offline-first architecture
  - Conflict resolution

## Key Components

### PersistenceController (`Persistence.swift`)

```swift
// Initialize CloudKit container
let container = NSPersistentCloudKitContainer(name: "AdventureLogger")

// Enable remote change notifications
description.setOption(true as NSNumber,
    forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

// Enable history tracking for sync
description.setOption(true as NSNumber,
    forKey: NSPersistentHistoryTrackingKey)

// Automatic merge of remote changes
container.viewContext.automaticallyMergesChangesFromParent = true

// Conflict resolution strategy (last write wins)
container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
```

**Key Features:**
- ✅ **History Tracking**: Enables CloudKit to track changes and sync efficiently
- ✅ **Remote Notifications**: Receives updates when data changes on other devices
- ✅ **Automatic Merging**: Seamlessly merges changes from iCloud
- ✅ **Conflict Resolution**: Uses "last write wins" strategy for conflicts

### CloudSyncManager (`CloudSyncManager.swift`)

Manages sync status, network connectivity, and manual sync operations.

```swift
class CloudSyncManager: ObservableObject {
    @Published var syncStatus: SyncStatus
    @Published var lastSyncDate: Date?
    @Published var isOnline: Bool
    @Published var pendingChanges: Int
}
```

**Responsibilities:**
1. **Sync Status Monitoring**
   - Listens to `NSPersistentCloudKitContainer.eventChangedNotification`
   - Tracks import/export events
   - Reports sync progress to UI

2. **Network Status Detection**
   - Checks CloudKit account availability
   - Detects online/offline state
   - Displays offline banner when disconnected

3. **Manual Sync Trigger**
   - Allows users to force sync
   - Provides visual feedback during sync
   - Handles sync errors gracefully

4. **Data Export**
   - Exports all data to JSON format
   - Useful for backups and data portability

## Sync Flow

### Automatic Sync (Default Behavior)

```
┌─────────────────┐
│   Local Change  │ (User edits place)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Core Data Save │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ CloudKit Export │ (Automatic)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   iCloud Sync   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Other Devices  │ (Automatic import)
└─────────────────┘
```

### Manual Sync

```
User Taps "Sync Now"
         │
         ▼
CloudSyncManager.manualSync()
         │
         ▼
Save local context
         │
         ▼
Trigger CloudKit export
         │
         ▼
Update sync status UI
         │
         ▼
Complete (Success/Error)
```

## Conflict Resolution

### Strategy: Last Write Wins
- **Policy**: `NSMergePolicy.mergeByPropertyObjectTrump`
- **Behavior**: Most recent change (by timestamp) wins
- **Why**: Simple, predictable, works well for personal apps

### How it works:
1. User A edits "Bondi Beach" description on iPhone
2. User B edits "Bondi Beach" description on iPad
3. Both changes sync to CloudKit
4. CloudKit detects conflict
5. Most recent edit (based on timestamp) is kept
6. Older edit is discarded
7. Final state syncs to both devices

## Offline Mode

### Offline-First Architecture
- ✅ All changes are saved locally first
- ✅ App works fully offline
- ✅ Changes queue automatically
- ✅ Sync happens when back online
- ✅ Visual indicator shows offline status

### Implementation:
```swift
// Network status banner shown when offline
NetworkStatusBanner()

// Checks CloudKit account status
CKContainer.default().accountStatus { status, error in
    switch status {
    case .available:
        self.isOnline = true
    default:
        self.isOnline = false
    }
}
```

## Data Management Features

### 1. Export Data
- **Format**: JSON
- **Location**: Settings → Data Management → Export Data
- **Use Case**: Backup, data portability, manual migration

### 2. Clear All Data
- **Method**: Batch delete request
- **Location**: Settings → Data Management → Clear All Data
- **Safety**: Confirmation alert before deletion

### 3. Image Cache Management
- **Purpose**: Manage Kingfisher cached images
- **Location**: Settings → Data Management → Clear Image Cache
- **Benefit**: Free up storage space

## User Interface Components

### 1. Sync Status Indicator (`SyncStatusView.swift`)
- Shows current sync state (idle, syncing, success, error)
- Animated icon during sync
- Displays time since last sync
- Color-coded status (blue=syncing, green=success, red=error)

### 2. Manual Sync Button
- One-tap sync trigger
- Disabled during active sync
- Shows progress indicator
- Located in Settings → iCloud & Sync

### 3. Network Status Banner
- Appears when offline
- Shows "Offline Mode" message
- Explains sync will resume when online
- Dismisses automatically when back online

## Security & Privacy

### CloudKit Security
- ✅ Data encrypted in transit (HTTPS)
- ✅ Data encrypted at rest on iCloud servers
- ✅ User authentication via Apple ID
- ✅ Scoped to user's private database
- ✅ No cross-user data access

### Privacy
- All data stored in user's private CloudKit container
- No data shared with other users
- No server-side code required
- Apple handles all infrastructure

## Testing Sync

### How to Test:
1. **Setup**: Sign in with Apple ID on multiple devices
2. **Create**: Add a place on Device A
3. **Wait**: Allow 5-10 seconds for sync
4. **Verify**: Check Device B for the new place
5. **Edit**: Modify the place on Device B
6. **Verify**: Check Device A for the update

### Manual Sync Test:
1. Turn on Airplane Mode on Device A
2. Add/edit places on Device A
3. Go to Settings → iCloud & Sync
4. Observe "Offline Mode" banner
5. Turn off Airplane Mode
6. Tap "Sync Now"
7. Verify changes appear on Device B

## Performance Optimizations

### 1. Batch Operations
- Uses `NSBatchDeleteRequest` for bulk deletions
- Reduces memory footprint

### 2. Lazy Loading
- `@FetchRequest` with predicates
- Only loads visible data

### 3. Background Sync
- CloudKit syncs in background
- No blocking of UI thread

### 4. Change Notifications
- Only updates affected views
- Minimizes unnecessary re-renders

## Error Handling

### Common Errors & Solutions

1. **"Not Authenticated"**
   - User not signed into iCloud
   - Solution: Settings → Sign in with Apple ID

2. **"Network Unavailable"**
   - No internet connection
   - Solution: Automatic retry when online

3. **"Quota Exceeded"**
   - CloudKit storage limit reached
   - Solution: Clean up old data

4. **"Zone Not Found"**
   - First-time sync setup
   - Solution: Automatic zone creation

## Best Practices Implemented

✅ **Offline-First**: All operations work offline
✅ **Automatic Sync**: No user intervention needed
✅ **Conflict Resolution**: Deterministic merge policy
✅ **Error Recovery**: Graceful handling of failures
✅ **User Feedback**: Clear status indicators
✅ **Data Integrity**: Undo/redo support
✅ **Privacy**: User's private container only
✅ **Performance**: Efficient background sync

## Conclusion

AdventureLogger demonstrates a production-ready implementation of local and cloud data management that:
- Seamlessly syncs across all user devices
- Works offline with automatic sync when online
- Handles conflicts predictably
- Provides clear user feedback
- Maintains data integrity and security
- Follows Apple's best practices for CloudKit integration
