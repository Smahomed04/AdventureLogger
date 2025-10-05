//
//  DiscoverView.swift
//

import SwiftUI
import CoreLocation
import CoreData

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
                    VStack(spacing: 20) {
                        Spacer()

                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .pulse()

                            ProgressView()
                                .scaleEffect(1.5)
                        }

                        Text("Discovering nearby places...")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)

                        Spacer()
                    }
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
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.discoveredPlaces) { place in
                                DiscoveredPlaceRow(place: place) {
                                    selectedDiscoveredPlace = place
                                    showingAddAlert = true
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                    }
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
            .onChange(of: selectedCategory) { _, newCategory in
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
    @Environment(\.colorScheme) var colorScheme
    let place: DiscoveredPlace
    let onAdd: () -> Void
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 16) {
            // Icon based on place type
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(
                        color: colorScheme == .dark ? Color.clear : Color.accentColor.opacity(0.3),
                        radius: 6,
                        x: 0,
                        y: 3
                    )

                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(place.name)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                if let description = place.description {
                    Text(description)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 10) {
                    if let rating = place.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.15))
                        .cornerRadius(8)
                    }

                    if let distance = place.distance {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 10))
                            Text("\(String(format: "%.1f", distance / 1000)) km")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                }
            }

            Spacer()

            Button(action: onAdd) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .shadow(
                            color: colorScheme == .dark ? Color.clear : Color.accentColor.opacity(0.3),
                            radius: 6,
                            x: 0,
                            y: 3
                        )

                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(
                    color: colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.08),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
    }
}

struct CategoryFilterButton: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .semibold, design: .rounded))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            LinearGradient(
                                colors: colorScheme == .dark ?
                                    [Color(.systemGray5), Color(.systemGray6)] :
                                    [Color(.systemGray6), Color(.systemGray5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                )
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .shadow(
                    color: isSelected && colorScheme == .light ? Color.accentColor.opacity(0.3) : Color.clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct EmptyDiscoverView: View {
    let onDiscover: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .pulse()

            VStack(spacing: 10) {
                Text("Discover Places Near You")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Find beaches, hikes, restaurants, and activities around your current location")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            ModernButton(
                title: "Start Discovering",
                icon: "location.fill",
                gradient: LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                action: onDiscover
            )
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorView: View {
    let error: DiscoverError
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.2), Color.red.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: errorIcon)
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 10) {
                Text(errorTitle)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(error.localizedDescription)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            ModernButton(
                title: "Try Again",
                icon: "arrow.clockwise",
                gradient: LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                action: retryAction
            )
            .padding(.horizontal, 40)
            .padding(.top, 8)
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
