# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AdventureLogger is a SwiftUI iOS application that uses Core Data with CloudKit integration for data persistence and synchronization.

## Building and Running

**Build and run in Xcode:**
```bash
open AdventureLogger.xcodeproj
```
Then use Cmd+R to build and run in Xcode.

**Build from command line:**
```bash
xcodebuild -project AdventureLogger.xcodeproj -scheme AdventureLogger -configuration Debug
```

## Architecture

### Core Data Stack
- **PersistenceController** (`Persistence.swift`): Singleton managing the `NSPersistentCloudKitContainer`
- Uses CloudKit for iCloud synchronization (configured in entitlements)
- Data model: `AdventureLogger.xcdatamodeld` with a single `Item` entity (timestamp attribute)
- Preview environment uses in-memory store for SwiftUI previews

### App Structure
- **AdventureLoggerApp** (`AdventureLoggerApp.swift`): Main app entry point, injects Core Data context into the environment
- **ContentView** (`ContentView.swift`): Root view with master-detail navigation
  - Uses `@FetchRequest` to observe Core Data changes
  - CRUD operations: add items, delete items via swipe actions

### Data Flow
1. SwiftUI views access Core Data through `@Environment(\.managedObjectContext)`
2. `@FetchRequest` automatically updates views when data changes
3. All Core Data operations happen on the view context
4. CloudKit automatically syncs changes when configured with proper iCloud container

## Key Considerations

- The app uses `NSPersistentCloudKitContainer`, not the standard `NSPersistentContainer`
- CloudKit entitlements are configured but iCloud container identifiers are empty (needs configuration for production)
- Error handling uses `fatalError()` in several places (development scaffolding, should be replaced for production)
