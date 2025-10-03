//
//  DiscoverView.swift
//

import SwiftUI
import CoreLocation

struct DiscoverView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = DiscoverViewModel()
    @State private var searchQuery = ""
    @State private var selectedCategory = "tourist_attraction"
    @State private var showingAddAlert = false
    @State private var selectedDiscoveredPlace: DiscoveredPlace?

    let categories = [
        ("All", "tourist_attraction"),
        ("Restaurant", "restaurant"),
        ("Beach", "natural_feature"),
        ("Hike", "park"),
        ("Museum", "museum")
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.0) { category in
                            CategoryFilterButton(
                                title: category.0,
                                isSelected: selectedCategory == category.1
                            ) {
                                selectedCategory = category.1
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(Color(.systemBackground))

                // Content
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Discovering nearby places...")
                    Spacer()
                } else if let error = viewModel.error {
                    ErrorView(
                        error: error,
                        retryAction: {
                            viewModel.discoverNearbyPlaces(category: selectedCategory)
                        }
                    )
                } else if viewModel.discoveredPlaces.isEmpty {
                    EmptyDiscoverView {
                        viewModel.discoverNearbyPlaces(category: selectedCategory)
                    }
                } else {
                    List(viewModel.discoveredPlaces) { place in
                        DiscoveredPlaceRow(place: place) {
                            selectedDiscoveredPlace = place
                            showingAddAlert = true
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Discover")
            .searchable(text: $searchQuery, prompt: "Search nearby places")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.discoverNearbyPlaces(category: selectedCategory)
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                if viewModel.discoveredPlaces.isEmpty {
                    viewModel.discoverNearbyPlaces(category: selectedCategory)
                }
            }
            .onChange(of: selectedCategory) { newCategory in
                viewModel.discoverNearbyPlaces(category: newCategory)
            }
            .alert("Add to Adventures", isPresented: $showingAddAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Add") {
                    if let place = selectedDiscoveredPlace {
                        addToAdventures(place)
                    }
                }
            } message: {
                if let place = selectedDiscoveredPlace {
                    Text("Add \(place.name) to your adventure list?")
                }
            }
        }
    }

    private func addToAdventures(_ discoveredPlace: DiscoveredPlace) {
        let newPlace = Place(context: viewContext)
        newPlace.id = UUID()
        newPlace.name = discoveredPlace.name
        newPlace.placeDescription = discoveredPlace.description ?? "Discovered nearby place"
        newPlace.category = mapCategory(discoveredPlace.types.first ?? "tourist_attraction")
        newPlace.latitude = discoveredPlace.latitude
        newPlace.longitude = discoveredPlace.longitude
        newPlace.address = discoveredPlace.address
        newPlace.isVisited = false
        newPlace.rating = Int16(discoveredPlace.rating ?? 0)
        newPlace.createdAt = Date()
        newPlace.updatedAt = Date()

        do {
            try viewContext.save()
        } catch {
            print("Error saving discovered place: \(error)")
        }
    }

    private func mapCategory(_ apiType: String) -> String {
        switch apiType {
        case "restaurant", "cafe", "food": return "Restaurant"
        case "natural_feature", "beach": return "Beach"
        case "park", "hiking_area": return "Hike"
        default: return "Activity"
        }
    }
}

struct DiscoveredPlaceRow: View {
    let place: DiscoveredPlace
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.headline)

                if let description = place.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    if let rating = place.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let distance = place.distance {
                        Text("\(String(format: "%.1f", distance / 1000)) km away")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct EmptyDiscoverView: View {
    let onDiscover: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Discover Places Near You")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Find beaches, hikes, restaurants, and activities around your current location")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: onDiscover) {
                Label("Start Discovering", systemImage: "location.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorView: View {
    let error: DiscoverError
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: errorIcon)
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text(errorTitle)
                .font(.title2)
                .fontWeight(.semibold)

            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: retryAction) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorIcon: String {
        switch error {
        case .locationAccessDenied:
            return "location.slash.fill"
        case .networkError:
            return "wifi.slash"
        default:
            return "exclamationmark.triangle.fill"
        }
    }

    private var errorTitle: String {
        switch error {
        case .locationAccessDenied:
            return "Location Access Denied"
        case .networkError:
            return "Network Error"
        default:
            return "Something Went Wrong"
        }
    }
}

#Preview {
    DiscoverView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
