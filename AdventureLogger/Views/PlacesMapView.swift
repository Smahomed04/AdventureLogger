//
//  PlacesMapView.swift
//

import SwiftUI
import MapKit
import CoreData
import UIKit

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
    @State private var trackUserLocation = false
    @State private var mapType: MKMapType = .standard
    @State private var showVisitedOnly = false
    @State private var selectedCategory = "All"

    let categories = ["All", "Beach", "Hike", "Activity", "Restaurant", "Other"]

    var filteredPlaces: [Place] {
        var filtered = Array(places)

        if showVisitedOnly {
            filtered = filtered.filter { $0.isVisited }
        }

        if selectedCategory != "All" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }

        return filtered
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Map(coordinateRegion: $region,
                    showsUserLocation: trackUserLocation,
                    annotationItems: filteredPlaces) { place in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(
                        latitude: place.latitude,
                        longitude: place.longitude
                    )) {
                        PlaceAnnotation(place: place) {
                            selectedPlace = place
                            showingPlaceDetail = true
                        }
                    }
                }
                .ignoresSafeArea(edges: .bottom)

                // Controls overlay
                VStack {
                    HStack {
                        Spacer()

                        VStack(spacing: 12) {
                            // Center on user location
                            Button(action: centerOnUserLocation) {
                                Image(systemName: trackUserLocation ? "location.fill" : "location")
                                    .font(.title2)
                                    .foregroundColor(trackUserLocation ? .blue : .primary)
                                    .padding(12)
                                    .background(Color(white: 1.0))
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }

                            // Show all places
                            Button(action: showAllPlaces) {
                                Image(systemName: "map.circle")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                                    .padding(12)
                                    .background(Color(white: 1.0))
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }

                            // Filter visited only
                            Button(action: { showVisitedOnly.toggle() }) {
                                Image(systemName: showVisitedOnly ? "checkmark.circle.fill" : "checkmark.circle")
                                    .font(.title2)
                                    .foregroundColor(showVisitedOnly ? .green : .primary)
                                    .padding(12)
                                    .background(Color(white: 1.0))
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                        }
                        .padding(.trailing)
                    }
                    .padding(.top, 8)

                    Spacer()

                    // Info banner at bottom
                    VStack(spacing: 12) {
                        // Category filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.self) { category in
                                    Button(action: { selectedCategory = category }) {
                                        Text(category)
                                            .font(.subheadline)
                                            .fontWeight(selectedCategory == category ? .semibold : .regular)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(selectedCategory == category ? Color.accentColor : Color(white: 1.0))
                                            .foregroundColor(selectedCategory == category ? .white : .primary)
                                            .cornerRadius(16)
                                            .shadow(radius: 2)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Place count info
                        HStack(spacing: 16) {
                            Label("\(filteredPlaces.count)", systemImage: "mappin.and.ellipse")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            if filteredPlaces.filter({ $0.isVisited }).count > 0 {
                                Label("\(filteredPlaces.filter { $0.isVisited }.count) visited", systemImage: "checkmark.circle.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }

                            Spacer()

                            if selectedPlace != nil {
                                Text("Tap marker for details")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(Color(white: 1.0).opacity(0.95))
                    }
                    .background(Color(white: 1.0).opacity(0.95))
                    .cornerRadius(16, corners: [.topLeft, .topRight])
                    .shadow(radius: 8)
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showVisitedOnly.toggle() }) {
                            Label(showVisitedOnly ? "Show All" : "Visited Only",
                                  systemImage: showVisitedOnly ? "eye" : "checkmark.circle")
                        }

                        Divider()

                        ForEach(categories, id: \.self) { category in
                            Button(action: { selectedCategory = category }) {
                                Label(category, systemImage: selectedCategory == category ? "checkmark" : "")
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
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
            .onAppear {
                showAllPlaces()
            }
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
        guard !filteredPlaces.isEmpty else { return }

        var minLat = filteredPlaces.first!.latitude
        var maxLat = filteredPlaces.first!.latitude
        var minLon = filteredPlaces.first!.longitude
        var maxLon = filteredPlaces.first!.longitude

        for place in filteredPlaces {
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
}

struct PlaceAnnotation: View {
    let place: Place
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(categoryColor)
                        .frame(width: 36, height: 36)

                    Image(systemName: categoryIcon)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }

                if place.isVisited {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 14, height: 14)
                        )
                        .offset(y: -8)
                }
            }
        }
    }

    private var categoryIcon: String {
        switch place.category {
        case "Beach": return "beach.umbrella"
        case "Hike": return "figure.hiking"
        case "Activity": return "figure.run"
        case "Restaurant": return "fork.knife"
        default: return "mappin"
        }
    }

    private var categoryColor: Color {
        switch place.category {
        case "Beach": return .blue
        case "Hike": return .green
        case "Activity": return .orange
        case "Restaurant": return .red
        default: return .purple
        }
    }
}

// Extension for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    PlacesMapView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
