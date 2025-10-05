# 🗺️ AdventureLogger

**Track, Discover, and Remember Your Adventures**

AdventureLogger is a comprehensive iOS application that helps you keep track of places you want to visit and places you've been. Whether it's beaches, hiking trails, restaurants, or activities, AdventureLogger makes it easy to manage your bucket list and preserve memories of your adventures.

---

## 📱 Features

### Core Functionality
- **Add Places**: Easily add places using intelligent location search
- **Track Visits**: Mark places as visited and add ratings (1-5 stars)
- **Personal Reflections**: Write notes and memories about each place
- **Categories**: Organize places by type (Beach, Hike, Activity, Restaurant, Other)
- **Interactive Map**: View all your places on an interactive map with custom markers
- **Discover Nearby**: Find new places near you using REST APIs
- **Search & Filter**: Quickly find places using search and category filters
- **Statistics**: Track your progress with visit counts and average ratings

### Advanced Features
- **iCloud Sync**: Automatically sync your adventures across all your Apple devices
- **Location Search**: Search for places by name without needing exact coordinates
- **Smart Search**: Use keywords and partial names to find places
- **Data Export**: Export your data in JSON, CSV, or Text format
- **User Preferences**: Customize app behavior with persistent settings
- **Real-time Updates**: See changes immediately across all views
- **Pull-to-Refresh**: Update your list with a simple pull gesture

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
3. Search for a place using the search bar (e.g., "Bondi Beach", "Italian restaurant")
4. Select a location from the search results
5. Fill in details (category, description, rating if visited)
6. Tap **"Save"**

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
   - 🟣 Purple = Other
3. Green checkmark badge = Visited places
4. Tap any marker to view details

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

---

## 🏗️ Project Structure

```
AdventureLogger/
├── AdventureLoggerApp.swift          # App entry point
├── ContentView.swift                  # Main tab view
├── Persistence.swift                  # CoreData + CloudKit setup
│
├── Views/
│   ├── PlaceListView.swift           # Home screen list
│   ├── AddPlaceView.swift            # Add/create new place
│   ├── PlaceDetailView.swift         # View/edit place details
│   ├── PlacesMapView.swift           # Interactive map
│   ├── DiscoverView.swift            # Discover nearby places
│   ├── LocationSearchView.swift      # Location search with MKLocalSearch
│   └── SettingsView.swift            # Settings & data export
│
├── ViewModels/
│   └── DiscoverViewModel.swift       # REST API & JSON parsing
│
└── AdventureLogger.xcdatamodeld/     # CoreData model
    └── Place entity with attributes:
        - id, name, category
        - latitude, longitude, address
        - isVisited, visitedDate, rating
        - personalReflection, placeDescription
        - photos, createdAt, updatedAt
```

---

## 🔧 Error Handling

### Location Errors
- **Access Denied**: User-friendly alert prompting to enable location in Settings
- **Unknown Error**: Generic error message with retry option
- Handled in: `AddPlaceView.swift` (LocationError enum, lines 337-349)

### Network Errors
- **No Internet**: Alert when network is unavailable
- **Invalid Response**: Handles malformed API responses
- **Timeout**: 30-second timeout with retry option
- Handled in: `DiscoverViewModel.swift` (DiscoverError enum)

### CoreData Errors
- **Save Failures**: Logged to console with NSError details
- **Merge Conflicts**: Auto-resolved with `automaticallyMergesChangesFromParent`
- **CloudKit Sync**: Automatic retry on sync failures

### User-Friendly Error Messages
All errors are displayed to users via:
- Alert dialogs with clear explanations
- Actionable solutions (e.g., "Enable location in Settings")
- Non-blocking error states (app remains usable)

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

- [ ] Photo attachments for places
- [ ] Share adventures with friends
- [ ] Trip planning and routes
- [ ] Offline map caching
- [ ] Custom place categories
- [ ] Dark mode optimizations
- [ ] iPad-optimized layout
- [ ] Widget for home screen
- [ ] Siri shortcuts integration

---

## 📄 License

This project is created for educational purposes as part of an iOS Development course assessment.

---

## 👨‍💻 Author

**Taahir Mahomed**
- Created: October 2025
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
