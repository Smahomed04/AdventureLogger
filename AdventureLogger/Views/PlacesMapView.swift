//
//  PlacesMapView.swift
//

import SwiftUI
import MapKit
import CoreData

struct PlacesMapView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Place.name, ascending: true)],
        animation: .default)
    private var places: FetchedResults<Place>

    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    @State private var selectedPlace: Place?
    @State private var showingPlaceDetail = false
    @State private var showingPlacePreview = false
    @State private var trackUserLocation = false
    @State private var mapType: MKMapType = .standard
    @State private var filterType: MapFilterType = .all
    @State private var showingCountrySelector = false
    @State private var selectedCountry: String?

    enum MapFilterType: String, CaseIterable {
        case all = "All"
        case visited = "Visited"
        case unvisited = "To Visit"
    }

    // Group places by country
    var placesByCountry: [String: [Place]] {
        Dictionary(grouping: Array(places), by: { place in
            place.address?.components(separatedBy: ", ").last ?? "Unknown"
        })
    }

    // Get countries sorted by place count
    var countriesWithCounts: [(country: String, count: Int)] {
        placesByCountry.map { (country: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    var filteredPlaces: [Place] {
        var filtered: [Place]

        switch filterType {
        case .all:
            filtered = Array(places)
        case .visited:
            filtered = places.filter { $0.isVisited }
        case .unvisited:
            filtered = places.filter { !$0.isVisited }
        }

        // Further filter by selected country
        if let country = selectedCountry {
            filtered = filtered.filter { place in
                let placeCountry = place.address?.components(separatedBy: ", ").last ?? "Unknown"
                return placeCountry == country
            }
        }

        return filtered
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $region,
                showsUserLocation: trackUserLocation,
                annotationItems: filteredPlaces) { place in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: place.latitude,
                    longitude: place.longitude
                )) {
                    PlaceAnnotation(place: place, isSelected: selectedPlace?.id == place.id) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedPlace = place
                            showingPlacePreview = true
                        }
                    }
                }
            }
            .ignoresSafeArea(edges: .top)

            // Controls overlay
            VStack(spacing: 0) {
                // Filter chips at top
                VStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(MapFilterType.allCases, id: \.self) { filter in
                                MapFilterChip(
                                    title: filter.rawValue,
                                    icon: filterIcon(for: filter),
                                    isSelected: filterType == filter
                                ) {
                                    withAnimation {
                                        filterType = filter
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }

                    // Selected country indicator
                    if let country = selectedCountry {
                        HStack(spacing: 8) {
                            Image(systemName: "globe")
                                .font(.system(size: 12, weight: .semibold))
                            Text(country)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                            Button(action: {
                                withAnimation {
                                    selectedCountry = nil
                                    showAllPlaces()
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(18)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .background(.ultraThinMaterial)
                .padding(.top, 60)

                HStack {
                    Spacer()

                    VStack(spacing: 16) {
                        // Country selector
                        MapControlButton(icon: "globe", gradient: LinearGradient(
                            colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ), action: { showingCountrySelector.toggle() })

                        // Map type selector
                        MapControlButton(icon: "map", action: toggleMapType)

                        // Center on user location
                        MapControlButton(icon: "location.fill", gradient: LinearGradient(
                            colors: [Color(hex: "4ECDC4"), Color(hex: "44A08D")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ), action: centerOnUserLocation)

                        // Show all places
                        MapControlButton(icon: "map.circle", action: showAllPlaces)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 12)

                Spacer()

                // Place preview or count badge
                if showingPlacePreview, let place = selectedPlace {
                    MapPlacePreview(place: place) {
                        showingPlaceDetail = true
                    } onDismiss: {
                        withAnimation {
                            showingPlacePreview = false
                            selectedPlace = nil
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if !filteredPlaces.isEmpty {
                    PlaceCountBadge(count: filteredPlaces.count)
                        .padding(.bottom, 30)
                        .transition(.opacity)
                }
            }
        }
        .sheet(isPresented: $showingPlaceDetail) {
            if let place = selectedPlace {
                NavigationView {
                    PlaceDetailView(place: place)
                }
            }
        }
        .sheet(isPresented: $showingCountrySelector) {
            CountrySelectorView(
                countries: countriesWithCounts,
                selectedCountry: selectedCountry,
                onSelectCountry: { country in
                    selectedCountry = country
                    showingCountrySelector = false
                    zoomToCountry(country)
                },
                onClearSelection: {
                    selectedCountry = nil
                    showingCountrySelector = false
                    showAllPlaces()
                }
            )
        }
        .onAppear {
            showAllPlaces()
        }
    }

    private func filterIcon(for filter: MapFilterType) -> String {
        switch filter {
        case .all: return "map"
        case .visited: return "checkmark.circle.fill"
        case .unvisited: return "circle"
        }
    }

    private func toggleMapType() {
        // Note: SwiftUI Map doesn't directly support map type, but we keep this for future enhancement
        // This would require using UIViewRepresentable with MKMapView for full control
        mapType = mapType == .standard ? .hybrid : .standard
    }

    private func centerOnUserLocation() {
        trackUserLocation = true
        locationManager.requestLocation { result in
            switch result {
            case .success(let location):
                withAnimation {
                    region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                }
            case .failure(let error):
                print("Error getting location: \(error.localizedDescription)")
            }
        }
    }

    private func showAllPlaces() {
        guard !places.isEmpty else { return }

        var minLat = places.first!.latitude
        var maxLat = places.first!.latitude
        var minLon = places.first!.longitude
        var maxLon = places.first!.longitude

        for place in places {
            minLat = min(minLat, place.latitude)
            maxLat = max(maxLat, place.latitude)
            minLon = min(minLon, place.longitude)
            maxLon = max(maxLon, place.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.3,
            longitudeDelta: (maxLon - minLon) * 1.3
        )

        withAnimation {
            region = MKCoordinateRegion(center: center, span: span)
        }
    }

    private func zoomToCountry(_ country: String) {
        let countryPlaces = placesByCountry[country] ?? []
        guard !countryPlaces.isEmpty else { return }

        var minLat = countryPlaces.first!.latitude
        var maxLat = countryPlaces.first!.latitude
        var minLon = countryPlaces.first!.longitude
        var maxLon = countryPlaces.first!.longitude

        for place in countryPlaces {
            minLat = min(minLat, place.latitude)
            maxLat = max(maxLat, place.latitude)
            minLon = min(minLon, place.longitude)
            maxLon = max(maxLon, place.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.5, 0.1),
            longitudeDelta: max((maxLon - minLon) * 1.5, 0.1)
        )

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            region = MKCoordinateRegion(center: center, span: span)
        }
    }
}

struct PlaceAnnotation: View {
    @Environment(\.colorScheme) var colorScheme
    let place: Place
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(categoryGradient)
                        .frame(width: isSelected ? 48 : 40, height: isSelected ? 48 : 40)
                        .shadow(
                            color: colorScheme == .dark ? Color.clear : categoryColor.opacity(0.4),
                            radius: isSelected ? 12 : 6,
                            x: 0,
                            y: isSelected ? 6 : 3
                        )

                    Image(systemName: categoryIcon)
                        .foregroundColor(.white)
                        .font(.system(size: isSelected ? 20 : 18, weight: .semibold))
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)

                if place.isVisited {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: isSelected ? 14 : 12))
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: isSelected ? 16 : 14, height: isSelected ? 16 : 14)
                        )
                        .offset(y: -8)
                }
            }
        }
    }

    private var categoryGradient: LinearGradient {
        CategoryGradient.forCategory(place.category ?? "Other")
    }

    private var categoryIcon: String {
        switch place.category {
        case "Beach": return "beach.umbrella"
        case "Hike": return "figure.hiking"
        case "Activity": return "figure.run"
        case "Restaurant": return "fork.knife"
        case "Place of Worship": return "building.columns"
        default: return "mappin"
        }
    }

    private var categoryColor: Color {
        switch place.category {
        case "Beach": return Color(hex: "4A90E2")
        case "Hike": return Color(hex: "56AB2F")
        case "Activity": return Color(hex: "FF6B6B")
        case "Restaurant": return Color(hex: "E74C3C")
        case "Place of Worship": return Color(hex: "9B59B6")
        default: return Color(hex: "A855F7")
        }
    }
}

struct MapControlButton: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    var gradient: LinearGradient? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        gradient ?? LinearGradient(
                            colors: [Color.cardBackground, Color.cardBackground],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(
                        color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.15),
                        radius: 10,
                        x: 0,
                        y: 4
                    )

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(gradient != nil ? .white : .primary)
            }
        }
    }
}

struct PlaceCountBadge: View {
    @Environment(\.colorScheme) var colorScheme
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "mappin.and.ellipse")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
            Text("\(count) place\(count == 1 ? "" : "s")")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(25)
        .shadow(
            color: colorScheme == .dark ? Color.clear : Color.accentColor.opacity(0.4),
            radius: 10,
            x: 0,
            y: 5
        )
    }
}

struct MapFilterChip: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .bold : .semibold, design: .rounded))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color(.systemGray5).opacity(0.8)
                    }
                }
            )
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(18)
        }
    }
}

struct MapPlacePreview: View {
    @Environment(\.colorScheme) var colorScheme
    let place: Place
    let onTap: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(categoryGradient)
                    .frame(width: 60, height: 60)

                Image(systemName: categoryIcon)
                    .foregroundColor(.white)
                    .font(.system(size: 24, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(place.name ?? "Unknown")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .lineLimit(1)

                if let description = place.placeDescription {
                    Text(description)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 10))
                        Text(place.category ?? "Other")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor.opacity(0.15))
                    .foregroundColor(categoryColor)
                    .cornerRadius(8)

                    if place.isVisited {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                            Text("Visited")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                    }
                }
            }

            Spacer()

            VStack(spacing: 8) {
                Button(action: onTap) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(
                    color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.15),
                    radius: 15,
                    x: 0,
                    y: 8
                )
        )
    }

    private var categoryIcon: String {
        switch place.category {
        case "Beach": return "beach.umbrella.fill"
        case "Hike": return "figure.hiking"
        case "Activity": return "sportscourt.fill"
        case "Restaurant": return "fork.knife"
        case "Place of Worship": return "building.columns.fill"
        default: return "mappin.circle.fill"
        }
    }

    private var categoryColor: Color {
        switch place.category {
        case "Beach": return Color(hex: "4A90E2")
        case "Hike": return Color(hex: "56AB2F")
        case "Activity": return Color(hex: "FF6B6B")
        case "Restaurant": return Color(hex: "E74C3C")
        case "Place of Worship": return Color(hex: "9B59B6")
        default: return Color(hex: "A855F7")
        }
    }

    private var categoryGradient: LinearGradient {
        CategoryGradient.forCategory(place.category ?? "Other")
    }
}

struct CountrySelectorView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    let countries: [(country: String, count: Int)]
    let selectedCountry: String?
    let onSelectCountry: (String) -> Void
    let onClearSelection: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Country")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Zoom into your adventures by country")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)

                // Clear selection button
                if selectedCountry != nil {
                    Button(action: {
                        onClearSelection()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                            Text("Clear Selection - View All")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.red, Color.red.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }

                // Country list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(countries, id: \.country) { item in
                            CountryRow(
                                country: item.country,
                                count: item.count,
                                isSelected: selectedCountry == item.country
                            ) {
                                onSelectCountry(item.country)
                                dismiss()
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CountryRow: View {
    @Environment(\.colorScheme) var colorScheme
    let country: String
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Flag/Globe icon
                ZStack {
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: "globe")
                        .foregroundColor(isSelected ? .white : .accentColor)
                        .font(.system(size: 22, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(country)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("\(count) place\(count == 1 ? "" : "s")")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 24))
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary.opacity(0.5))
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .shadow(
                        color: colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.1),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PlacesMapView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
