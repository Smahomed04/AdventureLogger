# Error Handling Strategy - AdventureLogger

## Overview

This document provides a comprehensive overview of the error handling approach implemented in AdventureLogger. Our strategy emphasizes **user experience**, **system stability**, and **developer debugging capability**.

---

## Core Principles

### 1. Fail Gracefully
The application never crashes due to errors. Every error scenario has a defined fallback behavior that allows users to continue using the app.

### 2. Inform Clearly
Error messages are written in plain language that users can understand and act upon. Technical jargon is avoided in user-facing messages.

### 3. Log Thoroughly
All errors are logged with sufficient context for developers to diagnose issues, while keeping sensitive information secure.

---

## Error Categories

### 1. Location Services Errors

#### Error Enumeration
```swift
enum LocationError: LocalizedError {
    case accessDenied
    case locationUnavailable
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Location access is required"
        case .locationUnavailable:
            return "Unable to determine your location"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
```

#### Handling Approach

**Access Denied**
- **Trigger**: User denies location permission or has it disabled in Settings
- **User Message**: "Location access is required to use your current location. Please enable it in Settings."
- **UI Response**: Show alert with "Open Settings" button
- **Fallback**: Allow manual coordinate entry
- **Logging**: `print("Location permission denied")`

**Location Unavailable**
- **Trigger**: GPS signal lost, device in airplane mode, or hardware failure
- **User Message**: "Unable to determine your location. Please try again or enter coordinates manually."
- **UI Response**: Show retry button and manual entry option
- **Fallback**: Manual coordinate input enabled
- **Logging**: `print("GPS unavailable: \(error.localizedDescription)")`

**Implementation Example** (`AddPlaceView.swift`):
```swift
private func requestLocation() {
    locationManager.requestLocation { [weak self] result in
        DispatchQueue.main.async {
            switch result {
            case .success(let location):
                self?.latitude = location.coordinate.latitude
                self?.longitude = location.coordinate.longitude
                self?.updateRegion()

            case .failure(let error):
                self?.showingLocationError = true

                switch error {
                case .accessDenied:
                    self?.locationErrorMessage = "Location permission denied. Enable in Settings."
                case .locationUnavailable:
                    self?.locationErrorMessage = "GPS unavailable. Try again or enter manually."
                case .unknown(let err):
                    self?.locationErrorMessage = "Error: \(err.localizedDescription)"
                }

                print("Location Error: \(error)")
            }
        }
    }
}
```

---

### 2. Network & API Errors

#### Error Enumeration
```swift
enum DiscoverError: LocalizedError {
    case networkUnavailable
    case invalidResponse
    case decodingFailed
    case apiError(String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection available"
        case .invalidResponse:
            return "Received invalid response from server"
        case .decodingFailed:
            return "Failed to process server data"
        case .apiError(let message):
            return message
        case .timeout:
            return "Request timed out"
        }
    }
}
```

#### Handling Approach

**Network Unavailable**
- **Trigger**: Device offline, no cellular/WiFi connection
- **User Message**: "No internet connection. Please check your network and try again."
- **UI Response**: Show network error banner, disable discovery features
- **Fallback**: Display mock/cached data with "Offline" indicator
- **Logging**: `print("Network unavailable at \(Date())")`

**Invalid Response**
- **Trigger**: API returns unexpected format or malformed JSON
- **User Message**: "Unable to load places. Please try again later."
- **UI Response**: Show error message with retry button
- **Fallback**: Keep previously loaded data visible
- **Logging**: `print("API Response Error: \(statusCode), Body: \(responseString)")`

**Timeout**
- **Trigger**: Request takes longer than 30 seconds
- **User Message**: "Request timed out. Please try again."
- **UI Response**: Automatic retry (max 2x), then show manual retry
- **Fallback**: Show cached results if available
- **Logging**: `print("Request timeout after \(duration)s for \(endpoint)")`

**Implementation Example** (`DiscoverViewModel.swift`):
```swift
func fetchNearbyPlaces(latitude: Double, longitude: Double) async {
    isLoading = true
    errorMessage = nil

    let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?..."
    guard let url = URL(string: urlString) else {
        self.errorMessage = "Invalid request URL"
        self.isLoading = false
        return
    }

    do {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DiscoverError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw DiscoverError.apiError("Server error: \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        let placesResponse = try decoder.decode(PlacesResponse.self, from: data)

        DispatchQueue.main.async {
            self.nearbyPlaces = placesResponse.results
            self.isLoading = false
        }

    } catch URLError.notConnectedToInternet {
        handleError(.networkUnavailable)
        useMockData() // Graceful fallback

    } catch URLError.timedOut {
        handleError(.timeout)

    } catch is DecodingError {
        handleError(.decodingFailed)
        print("JSON Decoding Error: \(error)")

    } catch {
        handleError(.invalidResponse)
        print("Unexpected error: \(error)")
    }
}

private func handleError(_ error: DiscoverError) {
    DispatchQueue.main.async {
        self.errorMessage = error.localizedDescription
        self.isLoading = false
    }
}
```

---

### 3. Core Data Errors

#### Error Types
- Save failures
- Fetch request failures
- Merge conflicts
- Schema migration errors
- Validation errors

#### Handling Approach

**Save Failures**
- **Trigger**: Disk full, permission issues, constraint violations
- **User Message**: "Unable to save changes. Please try again."
- **UI Response**: Alert with retry option, data stays in form
- **Fallback**: Keep data in UI, retry on next save attempt
- **Logging**:
  ```swift
  let nsError = error as NSError
  print("CoreData Save Error: \(nsError)")
  print("Domain: \(nsError.domain), Code: \(nsError.code)")
  print("UserInfo: \(nsError.userInfo)")
  ```

**Fetch Failures**
- **Trigger**: Invalid predicate, corrupted database
- **User Message**: Empty state with "Unable to load data"
- **UI Response**: Show empty state view
- **Fallback**: Return empty array, app continues functioning
- **Logging**: `print("Fetch failed: \(error), Predicate: \(fetchRequest.predicate)")`

**Merge Conflicts**
- **Trigger**: Same object modified on multiple devices
- **User Message**: None (transparent to user)
- **UI Response**: Data automatically merged
- **Fallback**: Latest write wins (NSMergePolicy.mergeByPropertyObjectTrump)
- **Logging**: `print("Merge conflict resolved: \(objectID)")`

**Implementation Example** (`PlaceDetailView.swift`):
```swift
private func saveChanges() {
    place.name = editedName
    place.placeDescription = editedDescription
    place.category = editedCategory
    place.personalReflection = editedReflection
    place.rating = Int16(editedRating)

    if editedVisited != place.isVisited {
        place.isVisited = editedVisited
        if editedVisited {
            if place.visitedDate == nil {
                place.visitedDate = Date()
            }
        } else {
            place.visitedDate = nil
            place.rating = 0
        }
    }

    place.updatedAt = Date()

    do {
        try viewContext.save()
        isEditing = false

    } catch {
        let nsError = error as NSError

        // Detailed logging for debugging
        print("=== CoreData Save Error ===")
        print("Error: \(nsError)")
        print("Description: \(nsError.localizedDescription)")
        print("User Info: \(nsError.userInfo)")
        print("Failed Object: Place - \(place.name ?? "Unknown")")
        print("==========================")

        // User-friendly error message
        errorMessage = "Unable to save changes. Please try again."
        showingError = true
    }
}
```

---

### 4. CloudKit Sync Errors

#### Error Types
- Account not available (not signed in to iCloud)
- Network errors during sync
- Quota exceeded
- Sync conflicts
- Permission issues

#### Handling Approach

**Account Not Available**
- **Trigger**: User not signed in to iCloud
- **User Message**: "iCloud is not available. Data will sync when you sign in."
- **UI Response**: Show informational banner
- **Fallback**: App works in local-only mode
- **Logging**: `print("iCloud account unavailable")`

**Sync Conflicts**
- **Trigger**: Same record modified on multiple devices
- **User Message**: None (transparent)
- **UI Response**: Automatic conflict resolution
- **Fallback**: Server truth wins for CloudKit records
- **Logging**: `print("CloudKit conflict resolved for: \(recordID)")`

**Quota Exceeded**
- **Trigger**: User's iCloud storage is full
- **User Message**: "iCloud storage is full. Please free up space or data won't sync."
- **UI Response**: Alert with link to iCloud settings
- **Fallback**: Local-only mode
- **Logging**: `print("CloudKit quota exceeded")`

**Implementation Example** (`CloudSyncManager.swift`):
```swift
private func handleSyncEvent(_ notification: Notification) {
    guard let event = notification.userInfo?[
        NSPersistentCloudKitContainer.eventNotificationUserInfoKey
    ] as? NSPersistentCloudKitContainer.Event else {
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
                    print("CloudKit import completed successfully")
                }

            case .export:
                self?.syncStatus = .syncing
                if event.endDate != nil {
                    self?.lastSyncDate = Date()
                    self?.syncStatus = .success
                    print("CloudKit export completed successfully")
                }

            @unknown default:
                break
            }
        }

        // Handle errors
        if let error = event.error {
            let ckError = error as NSError

            print("=== CloudKit Sync Error ===")
            print("Error: \(ckError)")
            print("Domain: \(ckError.domain)")
            print("Code: \(ckError.code)")
            print("Description: \(ckError.localizedDescription)")
            print("==========================")

            self?.syncStatus = .error(ckError.localizedDescription)
        }
    }
}
```

---

### 5. Image Loading Errors

#### Error Types
- Invalid URL
- Network failure during download
- Corrupted image data
- Cache corruption

#### Handling Approach

**Download Failure**
- **Trigger**: Network issue while loading image
- **User Message**: None (shows placeholder)
- **UI Response**: Display placeholder icon/image
- **Fallback**: Retry with exponential backoff
- **Logging**: `print("Image download failed: \(url)")`

**Cache Corruption**
- **Trigger**: Corrupted cached image file
- **User Message**: None
- **UI Response**: Clear cache, reload from network
- **Fallback**: Fetch fresh image
- **Logging**: `print("Cache corruption detected, clearing: \(cacheKey)")`

**Implementation Example** (`ImageCacheManager.swift`):
```swift
func clearCache() {
    KingfisherManager.shared.cache.clearMemoryCache()
    KingfisherManager.shared.cache.clearDiskCache {
        print("Image cache cleared successfully")
    }
}

// In SwiftUI views with Kingfisher:
KFImage(URL(string: imageURL))
    .placeholder {
        // Placeholder shown while loading or on error
        Image(systemName: "photo")
            .foregroundColor(.gray)
    }
    .onFailure { error in
        print("Image load failed: \(error)")
        // Retry logic or permanent placeholder
    }
    .retry(maxCount: 2, interval: .seconds(1))
```

---

## Error Presentation Patterns

### 1. Alerts (Critical Errors)
Used for errors that require user action or acknowledgment.

```swift
.alert("Error", isPresented: $showingError) {
    Button("OK", role: .cancel) { }
    Button("Retry") {
        retryAction()
    }
} message: {
    Text(errorMessage)
}
```

**Use Cases:**
- Location permission denied
- Save failures
- Delete confirmations

### 2. Inline Messages (Form Validation)
Shown directly in the UI context.

```swift
if !errorMessage.isEmpty {
    Text(errorMessage)
        .font(.caption)
        .foregroundColor(.red)
        .padding(.top, 4)
}
```

**Use Cases:**
- Empty required fields
- Invalid input formats
- Validation failures

### 3. Empty States (No Data Scenarios)
Friendly messages when data is unavailable.

```swift
VStack(spacing: 16) {
    Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 50))
        .foregroundColor(.orange)
    Text("Unable to load data")
        .font(.headline)
    Text("Please check your connection and try again")
        .font(.subheadline)
        .foregroundColor(.secondary)
    Button("Retry") {
        retryFetch()
    }
}
```

**Use Cases:**
- Network errors in list views
- Empty search results with errors
- Failed data fetches

### 4. Banners (Non-Critical Information)
Subtle notifications for background operations.

```swift
if syncStatus == .error(let message) {
    HStack {
        Image(systemName: "exclamationmark.circle")
        Text(message)
        Spacer()
        Button("Dismiss") { /* ... */ }
    }
    .padding()
    .background(Color.yellow.opacity(0.2))
}
```

**Use Cases:**
- CloudKit sync issues
- Background operation failures
- Offline mode indicators

---

## Error Logging Strategy

### Console Logging Format

**Standard Format:**
```swift
print("=== [Component] Error ===")
print("Function: \(#function)")
print("Error: \(error)")
print("Description: \(error.localizedDescription)")
print("Context: \(additionalInfo)")
print("Timestamp: \(Date())")
print("========================")
```

**Example Output:**
```
=== CoreData Save Error ===
Function: saveChanges()
Error: Error Domain=NSCocoaErrorDomain Code=133000
Description: The operation couldn't be completed.
Context: Saving Place: "Bondi Beach"
Timestamp: 2025-10-05 14:32:11 +0000
=======================
```

### What NOT to Log
- User passwords or credentials
- Personal identifiable information (PII)
- API keys or secrets
- Full API responses with sensitive data

### What TO Log
- Error types and codes
- Error descriptions
- Function/file where error occurred
- Contextual data (IDs, states, not content)
- Timestamps
- Stack traces (for debugging builds)

---

## Error Prevention Strategies

### 1. Input Validation
All user input is validated before processing:

```swift
// Example: Validate place name
private var isValidInput: Bool {
    !name.trimmingCharacters(in: .whitespaces).isEmpty &&
    latitude != 0.0 &&
    longitude != 0.0
}

Button("Save") {
    savePlace()
}
.disabled(!isValidInput)
```

### 2. Safe Unwrapping
Optional values are safely unwrapped:

```swift
// Good: Nil coalescing with default
let placeName = place.name ?? "Unknown Place"

// Good: Optional binding
if let visitDate = place.visitedDate {
    Text("Visited: \(visitDate, style: .date)")
}

// Good: Guard statement
guard let url = URL(string: urlString) else {
    print("Invalid URL: \(urlString)")
    return
}
```

### 3. Type Safety
Leverage Swift's type system:

```swift
// Use enums instead of strings
enum PlaceCategory: String {
    case beach = "Beach"
    case hike = "Hike"
    case activity = "Activity"
    case restaurant = "Restaurant"
    case worship = "Place of Worship"
    case other = "Other"
}

// Result type for operations
func fetchLocation() -> Result<CLLocation, LocationError> {
    // Implementation
}
```

### 4. Default Values
Provide sensible defaults:

```swift
@AppStorage("defaultCategory") private var defaultCategory = "Activity"
@AppStorage("searchRadius") private var searchRadius = 5.0

// In Core Data model
attribute rating: Int16 default 0
attribute isVisited: Bool default NO
```

---

## Testing Error Scenarios

### Manual Testing Checklist

#### Location Errors
- [ ] Deny location permission in Settings
- [ ] Enable airplane mode
- [ ] Disable Location Services entirely
- [ ] Test in area with weak GPS signal

#### Network Errors
- [ ] Enable airplane mode during API call
- [ ] Slow down network with Network Link Conditioner
- [ ] Use invalid API key
- [ ] Test with server returning errors (500, 404)

#### Core Data Errors
- [ ] Fill device storage completely
- [ ] Force concurrent modifications
- [ ] Test with corrupted database file
- [ ] Rapid save/delete operations

#### CloudKit Errors
- [ ] Sign out of iCloud
- [ ] Use account with full storage
- [ ] Modify same record on two devices
- [ ] Test with poor network connectivity

#### Image Errors
- [ ] Use invalid image URLs
- [ ] Fill cache storage
- [ ] Interrupt downloads
- [ ] Corrupt cache files manually

---

## Error Recovery Mechanisms

### 1. Automatic Retry
Network requests automatically retry with exponential backoff:

```swift
func fetchWithRetry(maxAttempts: Int = 3) async throws -> Data {
    var lastError: Error?

    for attempt in 1...maxAttempts {
        do {
            return try await URLSession.shared.data(from: url).0
        } catch {
            lastError = error
            if attempt < maxAttempts {
                let delay = pow(2.0, Double(attempt)) // Exponential backoff
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    throw lastError ?? NetworkError.unknown
}
```

### 2. Graceful Degradation
Features degrade gracefully when services are unavailable:

```swift
// Example: Discovery feature
if isNetworkAvailable {
    loadRealPlaces()
} else {
    loadMockPlaces()
    showOfflineIndicator()
}
```

### 3. State Preservation
UI state is preserved during errors:

```swift
// Data stays in form even if save fails
@State private var editedName = ""
@State private var editedDescription = ""

// On save error, user can retry without re-entering data
```

### 4. User Retry Options
Users can manually retry failed operations:

```swift
if let error = errorMessage {
    VStack {
        Text(error)
        Button("Retry") {
            performOperation()
        }
    }
}
```

---

## Summary

AdventureLogger's error handling strategy ensures:

✅ **Never crashes** - All errors handled gracefully
✅ **User-friendly** - Clear, actionable error messages
✅ **Debuggable** - Comprehensive logging for developers
✅ **Recoverable** - Automatic and manual retry options
✅ **Preventive** - Input validation and type safety
✅ **Tested** - Manual testing checklist for all scenarios

This multi-layered approach provides a robust, production-ready error handling system that maintains app stability while delivering an excellent user experience.

---

**Last Updated**: October 2025
**Maintained By**: Sa'd Mahomed
**Related Documentation**: [README.md](./README.md), [CLOUD_DATA_MANAGEMENT.md](./CLOUD_DATA_MANAGEMENT.md)
