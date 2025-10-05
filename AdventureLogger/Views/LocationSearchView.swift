//
//  LocationSearchView.swift
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LocationSearchViewModel()

    @State private var searchText = ""
    let onSelectLocation: (SearchResult) -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search results
                if viewModel.isSearching {
                    VStack {
                        ProgressView()
                        Text("Searching...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.searchResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No results found")
                            .font(.headline)
                        Text("Try searching for a place, address, or landmark")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.accentColor)
                        Text("Smart Location Search")
                            .font(.title2)
                            .fontWeight(.semibold)

                        VStack(alignment: .leading, spacing: 12) {
                            SearchTip(icon: "mappin.circle", text: "Full names: 'Bondi Beach', 'Eiffel Tower'")
                            SearchTip(icon: "text.word.spacing", text: "Keywords: 'blue beach', 'tall tower'")
                            SearchTip(icon: "fork.knife", text: "Types: 'italian restaurant', 'coffee shop'")
                            SearchTip(icon: "location", text: "Areas: 'restaurant downtown', 'park near me'")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.searchResults) { result in
                        LocationSearchResultRow(result: result) {
                            onSelectLocation(result)
                            dismiss()
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Search Location")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Try: 'blue beach', 'italian restaurant', 'opera house'...")
            .onChange(of: searchText) { _, newValue in
                viewModel.search(query: newValue)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SearchTip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct LocationSearchResultRow: View {
    let result: SearchResult
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: iconForCategory(result.category))
                        .foregroundColor(.accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if let address = result.address {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: 8) {
                        if let category = result.category {
                            Label(category, systemImage: "tag")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let distance = result.distance {
                            Label(formatDistance(distance), systemImage: "location")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func iconForCategory(_ category: String?) -> String {
        guard let category = category?.lowercased() else {
            return "mappin.circle.fill"
        }

        if category.contains("restaurant") || category.contains("food") || category.contains("cafe") {
            return "fork.knife"
        } else if category.contains("park") || category.contains("beach") {
            return "leaf.fill"
        } else if category.contains("museum") || category.contains("attraction") {
            return "building.columns.fill"
        } else if category.contains("hotel") || category.contains("lodging") {
            return "bed.double.fill"
        } else if category.contains("shop") || category.contains("store") {
            return "cart.fill"
        } else {
            return "mappin.circle.fill"
        }
    }

    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
}

// MARK: - View Model

@MainActor
class LocationSearchViewModel: NSObject, ObservableObject {
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching = false

    private var searchTask: Task<Void, Never>?
    private let locationManager = CLLocationManager()
    private var userLocation: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func search(query: String) {
        // Cancel previous search
        searchTask?.cancel()

        guard !query.isEmpty else {
            searchResults = []
            return
        }

        searchTask = Task {
            await performSearch(query: query)
        }
    }

    private func performSearch(query: String) async {
        isSearching = true

        // Split query into keywords for better matching
        let keywords = query.lowercased().split(separator: " ").map(String.init)

        // Create multiple search requests for better results
        var allResults: [SearchResult] = []

        // 1. Direct search with full query
        await performSingleSearch(query: query, results: &allResults)

        // 2. If query has multiple words, try searching each word
        if keywords.count > 1 {
            for keyword in keywords {
                if keyword.count >= 3 { // Only search meaningful words
                    await performSingleSearch(query: keyword, results: &allResults)
                }
            }
        }

        // 3. Try common place type keywords
        let placeTypes = ["restaurant", "cafe", "beach", "park", "museum", "hotel", "bar", "shop", "mall"]
        for placeType in placeTypes {
            if keywords.contains(where: { $0.contains(placeType) || placeType.contains($0) }) {
                let searchQuery = keywords.filter { !placeTypes.contains($0) }.joined(separator: " ")
                if !searchQuery.isEmpty {
                    await performSingleSearch(query: "\(searchQuery) \(placeType)", results: &allResults)
                }
            }
        }

        // Remove duplicates based on location proximity
        let uniqueResults = removeDuplicates(from: allResults)

        // Sort by relevance and distance
        searchResults = uniqueResults.sorted { result1, result2 in
            // Prioritize exact matches
            let query1Match = result1.name.lowercased().contains(query.lowercased())
            let query2Match = result2.name.lowercased().contains(query.lowercased())

            if query1Match != query2Match {
                return query1Match
            }

            // Then sort by distance
            return (result1.distance ?? Double.infinity) < (result2.distance ?? Double.infinity)
        }

        isSearching = false
    }

    private func performSingleSearch(query: String, results: inout [SearchResult]) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.pointOfInterest, .address]

        // Set search region based on user location
        if let userLocation = userLocation {
            request.region = MKCoordinateRegion(
                center: userLocation.coordinate,
                latitudinalMeters: 50000,
                longitudinalMeters: 50000
            )
        }

        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()
            guard !Task.isCancelled else { return }

            let newResults = response.mapItems.map { item -> SearchResult in
                let distance = userLocation?.distance(from: CLLocation(
                    latitude: item.placemark.coordinate.latitude,
                    longitude: item.placemark.coordinate.longitude
                ))

                return SearchResult(
                    name: item.name ?? "Unknown",
                    address: formatAddress(from: item.placemark),
                    latitude: item.placemark.coordinate.latitude,
                    longitude: item.placemark.coordinate.longitude,
                    category: item.pointOfInterestCategory?.rawValue,
                    distance: distance
                )
            }

            results.append(contentsOf: newResults)
        } catch {
            // Silently handle errors for individual searches
        }
    }

    private func removeDuplicates(from results: [SearchResult]) -> [SearchResult] {
        var uniqueResults: [SearchResult] = []

        for result in results {
            // Check if this location is already in results (within 50 meters)
            let isDuplicate = uniqueResults.contains { existing in
                let location1 = CLLocation(latitude: result.latitude, longitude: result.longitude)
                let location2 = CLLocation(latitude: existing.latitude, longitude: existing.longitude)
                return location1.distance(from: location2) < 50
            }

            if !isDuplicate {
                uniqueResults.append(result)
            }
        }

        return uniqueResults
    }

    private func formatAddress(from placemark: MKPlacemark) -> String {
        var components: [String] = []

        if let street = placemark.thoroughfare {
            components.append(street)
        }
        if let city = placemark.locality {
            components.append(city)
        }
        if let state = placemark.administrativeArea {
            components.append(state)
        }
        if let country = placemark.country {
            components.append(country)
        }

        return components.joined(separator: ", ")
    }
}

extension LocationSearchViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.first
    }
}

// MARK: - Search Result Model

struct SearchResult: Identifiable {
    let id = UUID()
    let name: String
    let address: String?
    let latitude: Double
    let longitude: Double
    let category: String?
    let distance: Double?
}

#Preview {
    LocationSearchView { result in
        print("Selected: \(result.name)")
    }
}
