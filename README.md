# 🗺️ AdventureLogger

**Track, Discover, and Remember Your Adventures**

AdventureLogger is a comprehensive iOS application that helps you keep track of places you want to visit and places you've been. Whether it's beaches, hiking trails, restaurants, or activities, AdventureLogger makes it easy to manage your bucket list and preserve memories of your adventures.

---

## 📱 Features

### Core Functionality
- **Add Places**: Easily add places using intelligent location search
- **Track Visits**: Mark places as visited and add ratings (1-5 stars)
- **Personal Reflections**: Write notes and memories about each place
- **Categories**: Organize places by type (Beach, Hike, Activity, Restaurant, Place of Worship, Other)
- **Trip Organization**: Create trips to group adventures into meaningful memories
- **Interactive Map**: View all your places on an interactive map with custom markers
- **Country Filtering**: Filter map by country with automatic zoom to selected region
- **Discover Nearby**: Find new places near you using REST APIs
- **Search & Filter**: Quickly find places using search and category filters
- **Statistics**: Track your progress with visit counts and average ratings

### Advanced Features
- **iCloud Sync**: Automatically sync your adventures across all your Apple devices
- **Location Search**: Search for places by name without needing exact coordinates
- **Smart Search**: Use keywords and partial names to find places intelligently
- **Modern UI Design**: Beautiful gradient cards, glassmorphism effects, and smooth animations
- **Dark Mode**: Fully adaptive design that works perfectly in light and dark modes
- **Image Caching**: Fast-loading place images with Kingfisher integration
- **Data Export**: Export your data in JSON, CSV, or Text format
- **User Preferences**: Customize app behavior with persistent settings
- **Real-time Updates**: See changes immediately across all views
- **Pull-to-Refresh**: Update your list with a simple pull gesture
- **Frosted Glass Tab Bar**: Beautiful ultra-thin material tab bar effect

---

## 🛠️ Technologies Used

### iOS Frameworks
- **SwiftUI**: Modern declarative UI framework
- **Core Data**: Local data persistence
- **CloudKit**: Cloud synchronization via NSPersistentCloudKitContainer
- **MapKit**: Interactive maps and location search (MKLocalSearch)
- **Core Location**: GPS and location services (CLLocationManager)
- **UserDefaults**: User preferences storage (@AppStorage)

### Advanced Concepts
- **REST API Integration**: Google Places API for discovering nearby places
- **Advanced JSON Parsing**: Custom Decodable for nested JSON structures
- **Async/Await**: Modern asynchronous programming
- **MVVM Architecture**: Separation of concerns with ViewModels
- **Reactive Programming**: @ObservedObject and @FetchRequest for reactive data
- **Error Handling**: Comprehensive error handling with user-friendly messages

---

## 📋 Requirements

- **iOS**: 15.0 or later
- **Xcode**: 14.0 or later
- **Device**: iPhone (Portrait mode optimized)
- **Apple ID**: Required for iCloud sync features

---

## 🚀 Setup Instructions

### 1. Clone or Download the Project
```bash
git clone <repository-url>
cd AdventureLogger
```

### 2. Open in Xcode
```bash
open AdventureLogger.xcodeproj
```

### 3. Configure iCloud (Important!)

**Step 1**: Select the project in Xcode's navigator
**Step 2**: Select the "AdventureLogger" target
**Step 3**: Go to "Signing & Capabilities" tab
**Step 4**: Ensure your Apple ID is signed in
**Step 5**: Enable "iCloud" capability if not already enabled
**Step 6**: Check "CloudKit" under iCloud services
**Step 7**: The container should be: `iCloud.com.yourteam.AdventureLogger`

### 4. Configure Location Permissions

Location permissions are already configured in `Info.plist`:
- `NSLocationWhenInUseUsageDescription`: For accessing user location
- The app will request permission on first use

### 5. Optional: Configure Google Places API

For live nearby place discovery (optional - mock data works by default):

**Step 1**: Get a Google Places API key from [Google Cloud Console](https://console.cloud.google.com/)
**Step 2**: Open `ViewModels/DiscoverViewModel.swift`
**Step 3**: Replace `"YOUR_GOOGLE_PLACES_API_KEY"` with your actual API key (line 157)

**Note**: The app works without a real API key - it will use mock data for demonstration.

### 6. Build and Run
- Select your target device or simulator
- Press `Cmd + R` to build and run
- Grant location permissions when prompted

---

## 📖 How to Use

### Adding a Place
1. Tap the **"Adventures"** tab
2. Tap the **"+"** button in the top right
3. Search for a place using the search bar (e.g., "Bondi Beach", "Italian restaurant", "mosque")
4. Select a location from the search results
5. Fill in details (category, description, rating if visited)
6. Choose a category: Beach, Hike, Activity, Restaurant, Place of Worship, or Other
7. Optionally assign to a Trip
8. Tap **"Save"**

### Marking a Place as Visited
1. Tap on a place in your list
2. Toggle **"Already Visited"** to ON
3. Add a rating (1-5 stars by tapping the stars)
4. Add a personal reflection (optional)
5. Tap **"Save"**

### Viewing on Map
1. Tap the **"Map"** tab
2. See all your places with color-coded markers:
   - 🔵 Blue = Beach
   - 🟢 Green = Hike
   - 🟠 Orange = Activity
   - 🔴 Red = Restaurant
   - 🟣 Purple = Place of Worship
   - 🟣 Purple = Other
3. Green checkmark badge = Visited places
4. Tap any marker to view details
5. Use filter chips to show: All, Visited, or To Visit
6. Tap the globe button to filter by country and auto-zoom

### Creating and Managing Trips
1. Tap the **"Trips"** tab
2. Tap the **"+"** button to create a new trip
3. Enter trip name (e.g., "Summer in Europe", "Hajj 2024")
4. Add description and set start/end dates
5. Tap **"Create Trip"**
6. Open the trip and tap **"Add Places"** to add adventures to it
7. View all places in the trip organized chronologically
8. See trip statistics (total places, visited count, average rating)

### Assigning Places to Trips
**Method 1**: From Trip Detail
1. Open a trip and tap **"Add Places"**
2. Select multiple places from the list
3. Tap **"Add"** to assign them to the trip

**Method 2**: From Place Detail
1. Open any place from Adventures list
2. Scroll to the "Trip" section
3. Tap **"Assign to a Trip"**
4. Select the trip from the list

### Discovering New Places
1. Tap the **"Discover"** tab
2. Grant location permission if prompted
3. Browse nearby places by category
4. Tap **"+"** on any place to add it to your adventures

### Exporting Data
1. Tap the **"Settings"** tab
2. Tap **"Export Data"**
3. Choose format (JSON, CSV, or Text)
4. Select export options
5. Tap **"Export Data"**
6. Share via any app (AirDrop, Mail, Messages, etc.)

### Managing Image Cache
1. Tap the **"Settings"** tab
2. Tap **"Clear Image Cache"** to free up storage
3. Images will reload automatically when needed

---

## 🏗️ Project Structure

```
AdventureLogger/
├── AdventureLoggerApp.swift          # App entry point
├── ContentView.swift                  # Main tab view (5 tabs)
├── Persistence.swift                  # CoreData + CloudKit setup
│
├── Views/
│   ├── PlaceListView.swift           # Adventures list with filters
│   ├── AddPlaceView.swift            # Add/create new place
│   ├── PlaceDetailView.swift         # View/edit place details
│   ├── PlacesMapView.swift           # Interactive map with country filter
│   ├── TripsView.swift               # Trip organization main view
│   ├── TripDetailView.swift          # Trip details with places
│   ├── AddTripView.swift             # Create new trip
│   ├── AddPlacesToTripView.swift     # Add places to existing trip
│   ├── DiscoverView.swift            # Discover nearby places
│   ├── LocationSearchView.swift      # Smart location search
│   └── SettingsView.swift            # Settings & data export
│
├── ViewModels/
│   └── DiscoverViewModel.swift       # REST API & JSON parsing
│
├── Utilities/
│   ├── DesignSystem.swift            # Modern design system with gradients
│   ├── ImageCacheManager.swift       # Kingfisher image caching
│   └── CloudSyncManager.swift        # CloudKit sync management
│
└── AdventureLogger.xcdatamodeld/     # CoreData model
    ├── Place entity:
    │   - id, name, category
    │   - latitude, longitude, address
    │   - isVisited, visitedDate, rating
    │   - personalReflection, placeDescription
    │   - photoURL, createdAt, updatedAt
    │   - trip (relationship to Trip)
    │
    └── Trip entity:
        - id, name, tripDescription
        - startDate, endDate
        - coverImageURL, createdAt, updatedAt
        - places (relationship to Place)
```

---

## 🔧 Error Handling Strategy

AdventureLogger implements a comprehensive, multi-layered error handling approach that prioritizes user experience while maintaining system stability. Our strategy follows three core principles:

1. **Fail Gracefully**: Never crash - always provide fallback behavior
2. **Inform Clearly**: Give users actionable, non-technical error messages
3. **Log Thoroughly**: Capture detailed errors for debugging without exposing users

### Error Handling Architecture

#### 1. Location Services Errors
**Location**: `AddPlaceView.swift`, `LocationManager.swift`

**Error Types**:
```swift
enum LocationError: LocalizedError {
    case accessDenied
    case locationUnavailable
    case unknown(Error)
}
```

**Handling Strategy**:
- **Access Denied**:
  - User sees: "Location access is required to use your current location. Please enable it in Settings."
  - Action: Direct link to Settings (on device) or manual coordinate entry fallback
  - Logged: Permission denial event

- **Location Unavailable**:
  - User sees: "Unable to determine your location. Please try again or enter manually."
  - Action: Retry button + manual entry fallback
  - Logged: GPS failure details

- **Unknown Errors**:
  - User sees: "Something went wrong. Please try again."
  - Action: Retry option
  - Logged: Full error details with stack trace

**Implementation**:
```swift
locationManager.requestLocation { result in
    switch result {
    case .success(let location):
        // Handle success
    case .failure(let error):
        showingLocationError = true
        locationErrorMessage = error.localizedDescription
        // Error logged to console with full context
    }
}
```

#### 2. Network & API Errors
**Location**: `DiscoverViewModel.swift`

**Error Types**:
```swift
enum DiscoverError: LocalizedError {
    case networkUnavailable
    case invalidResponse
    case decodingFailed
    case apiError(String)
    case timeout
}
```

**Handling Strategy**:
- **Network Unavailable**:
  - User sees: "No internet connection. Please check your network and try again."
  - Fallback: Cached/mock data displayed with indicator
  - Logged: Network state at time of failure

- **Invalid Response**:
  - User sees: "Unable to load places. Please try again later."
  - Fallback: Shows previously loaded places if available
  - Logged: Response details, status code, headers

- **Timeout**:
  - User sees: "Request timed out. Please try again."
  - Action: Automatic retry (max 2 attempts) then manual retry
  - Logged: Request duration, endpoint

- **API Errors**:
  - User sees: Specific message from API (sanitized)
  - Fallback: Mock data for demonstration purposes
  - Logged: Full API error response

**Implementation**:
```swift
do {
    let data = try await URLSession.shared.data(from: url)
    // Process data
} catch URLError.notConnectedToInternet {
    self.error = .networkUnavailable
    useMockData() // Graceful fallback
} catch URLError.timedOut {
    if retryCount < maxRetries {
        await retry()
    } else {
        self.error = .timeout
    }
} catch {
    self.error = .invalidResponse
    print("API Error: \(error)") // Detailed logging
}
```

#### 3. Core Data Errors
**Location**: `Persistence.swift`, all View files with viewContext

**Error Types**:
- Save failures
- Fetch failures
- Merge conflicts
- Migration errors

**Handling Strategy**:
- **Save Failures**:
  - User sees: "Unable to save changes. Please try again."
  - Action: Data preserved in UI, automatic retry on next change
  - Logged: NSError with userInfo dictionary

- **Merge Conflicts**:
  - User sees: Nothing (auto-resolved)
  - Resolution: Latest write wins (NSMergePolicy.mergeByPropertyObjectTrump)
  - Logged: Conflict details for monitoring

- **Fetch Failures**:
  - User sees: Empty state with helpful message
  - Fallback: Show cached data or empty state
  - Logged: Predicate and sort descriptors

**Implementation**:
```swift
do {
    try viewContext.save()
} catch {
    let nsError = error as NSError
    print("Save error: \(nsError)")
    print("User info: \(nsError.userInfo)")

    // Show user-friendly alert
    errorMessage = "Unable to save changes. Please try again."
    showingError = true

    // Log for debugging
    logError("CoreData Save", error: nsError)
}
```

#### 4. CloudKit Sync Errors
**Location**: `CloudSyncManager.swift`, `Persistence.swift`

**Error Types**:
- Account not available
- Network errors
- Quota exceeded
- Sync conflicts

**Handling Strategy**:
- **Account Issues**:
  - User sees: "iCloud is not available. Data will sync when you sign in."
  - Fallback: Local-only mode continues working
  - Logged: Account status details

- **Sync Conflicts**:
  - User sees: Nothing (auto-resolved)
  - Resolution: Server truth wins for CloudKit data
  - Logged: Conflict resolution path taken

- **Quota Exceeded**:
  - User sees: "iCloud storage is full. Please free up space."
  - Fallback: Local storage only
  - Logged: Current usage stats

**Implementation**:
```swift
NotificationCenter.default.publisher(
    for: NSPersistentCloudKitContainer.eventChangedNotification
)
.sink { notification in
    guard let event = notification.userInfo?[...] as? Event else { return }

    if let error = event.error {
        handleCloudKitError(error)
        logCloudKitEvent(event)
    }
}
```

#### 5. Image Loading Errors
**Location**: `ImageCacheManager.swift`, Kingfisher integration

**Error Types**:
- Invalid URL
- Download failure
- Cache corruption

**Handling Strategy**:
- **Download Failure**:
  - User sees: Placeholder image
  - Action: Automatic retry with exponential backoff
  - Logged: URL and error reason

- **Cache Corruption**:
  - User sees: Image reloads from source
  - Action: Automatic cache clear and rebuild
  - Logged: Affected cache keys

**Implementation**:
```swift
KingfisherManager.shared.retrieveImage(with: url) { result in
    switch result {
    case .success(let value):
        // Display image
    case .failure(let error):
        // Show placeholder
        print("Image load error: \(error)")
        logImageError(url: url, error: error)
    }
}
```

### Error Reporting & Logging

#### Console Logging
All errors are logged to console with context:
```swift
print("Error in \(functionName): \(error)")
print("Context: \(additionalInfo)")
```

#### User Feedback
- **Alerts**: For critical errors requiring user action
- **Banners**: For non-critical informational errors
- **Inline Messages**: For form validation and input errors
- **Toast Messages**: For successful recovery or retries

#### Error Recovery Mechanisms
1. **Automatic Retry**: Network requests retry up to 2 times
2. **Graceful Degradation**: Fall back to cached/mock data
3. **User Retry**: Manual retry buttons for failed operations
4. **State Preservation**: UI state maintained during errors

### Testing Error Scenarios

**Manual Testing Checklist**:
- ✅ Airplane mode (network errors)
- ✅ Location disabled (permission errors)
- ✅ iCloud signed out (sync errors)
- ✅ Invalid API key (API errors)
- ✅ Corrupt data entry (validation errors)
- ✅ Full storage (disk errors)

### Error Prevention

1. **Input Validation**: All user input validated before processing
2. **Nil Coalescing**: Optional values safely unwrapped
3. **Type Safety**: Swift's type system prevents many runtime errors
4. **Guard Statements**: Early returns prevent invalid states
5. **Default Values**: Sensible defaults for optional data

### Documentation References

For detailed implementation:
- Location errors: See `AddPlaceView.swift` lines 230-260
- Network errors: See `DiscoverViewModel.swift` lines 80-120
- Core Data errors: See `Persistence.swift` lines 100-130
- CloudKit errors: See `CloudSyncManager.swift` lines 160-200

For more details, see: [ERROR_HANDLING.md](./ERROR_HANDLING.md)

---

## 🧪 Testing

### Manual Testing Checklist
- ✅ Add a new place using location search
- ✅ Mark a place as visited and add a rating
- ✅ Edit place details and verify changes appear in list
- ✅ View places on map with correct markers
- ✅ Discover nearby places (mock data works without API key)
- ✅ Export data in all formats (JSON, CSV, Text)
- ✅ Delete a place
- ✅ Test iCloud sync by signing in on another device

### Preview Data
The app includes sample preview data for testing:
- 5 sample places in Sydney area (Bondi Beach, Blue Mountains, etc.)
- Mix of visited and unvisited places
- Various categories and ratings
- Located in: `Persistence.swift` (preview controller)

---

## 📊 Assessment Requirements Coverage

This project fulfills all requirements for the iOS Application Development assessment:

| Requirement | Implementation | Status |
|------------|---------------|---------|
| **Local Data (CoreData)** | Place entity with 15+ attributes | ✅ Complete |
| **Local Data (UserDefaults)** | Settings with @AppStorage | ✅ Complete |
| **Cloud Data (CloudKit)** | NSPersistentCloudKitContainer | ✅ Complete |
| **REST APIs** | Google Places API integration | ✅ Complete |
| **Advanced JSON Parsing** | Nested geometry/location parsing | ✅ Complete |
| **Core Location** | LocationManager with permissions | ✅ Complete |
| **MapKit** | Interactive map with MKLocalSearch | ✅ Complete |
| **Swift Package Manager** | External library (Kingfisher) | ✅ Complete |
| **UI/UX Design** | Modern SwiftUI with 4 main views | ✅ Complete |
| **Error Handling** | Comprehensive error handling | ✅ Complete |
| **Documentation** | This README + inline comments | ✅ Complete |

---

## 🎨 Design Decisions

### Why CoreData + CloudKit?
- Native iOS solution for data persistence
- Automatic iCloud sync across devices
- Offline-first with conflict resolution
- No backend server required

### Why SwiftUI?
- Modern declarative syntax
- Reactive data binding with @ObservedObject
- Built-in support for iOS design patterns
- Faster development and iteration

### Why MKLocalSearch?
- No API key required (unlike Google Places for search)
- Native iOS integration
- Accurate results with minimal code
- Respects user privacy

### Data Model Design
- Single `Place` entity keeps it simple
- Flexible `category` string for extensibility
- `isVisited` boolean for bucket list tracking
- Optional `rating` and `reflection` for visited places

---

## 🐛 Known Issues

- Tab bar hides on Map view when using standard TabView (by design for full-screen map)
- Google Places API requires real API key for live data (falls back to mock data)
- Export share sheet requires iOS device (not available in simulator)

---

## 🚦 Future Enhancements

- [ ] Photo attachments for places (multiple photos)
- [ ] Share adventures with friends
- [ ] Trip routes and itineraries
- [ ] Offline map caching
- [ ] Custom place categories
- [x] ~~Dark mode optimizations~~ ✅ Complete
- [ ] iPad-optimized layout
- [ ] Widget for home screen
- [ ] Siri shortcuts integration
- [x] ~~Trip organization~~ ✅ Complete
- [x] ~~Place of Worship category~~ ✅ Complete
- [x] ~~Country-based map filtering~~ ✅ Complete

---

## 📄 License

This project is created for educational purposes as part of an iOS Development course assessment.

---

## 👨‍💻 Author

**Sa'd Mahomed**
- Created: October 2025
- Project: Assessment Task 3 - iOS Application Development

---

## 🙏 Acknowledgments

- Apple Documentation for SwiftUI, CoreData, and MapKit
- iOS Design Guidelines for UI/UX best practices
- Google Places API for nearby place discovery
- Stack Overflow community for troubleshooting assistance

---

## 📞 Support

For issues or questions about this project:
1. Check this README for setup instructions
2. Review inline code comments
3. Check the error handling documentation above
4. Verify iCloud is configured correctly in Xcode

---

**Built with ❤️ using Swift and SwiftUI**
