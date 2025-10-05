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
    @State private var trackUserLocation = false
    @State private var mapType: MKMapType = .standard

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $region,
                showsUserLocation: trackUserLocation,
                annotationItems: Array(places)) { place in
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
            .ignoresSafeArea(edges: .top)

            // Controls overlay
            VStack {
                HStack {
                    Spacer()

                    VStack(spacing: 16) {
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
                .padding(.top, 60)

                Spacer()

                // Place count badge
                if !places.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                        Text("\(places.count) place\(places.count == 1 ? "" : "s")")
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
                    .shadow(color: Color.accentColor.opacity(0.4), radius: 10, x: 0, y: 5)
                    .padding(.bottom, 30)
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
        case "Beach": return Color(hex: "4A90E2")
        case "Hike": return Color(hex: "56AB2F")
        case "Activity": return Color(hex: "FF6B6B")
        case "Restaurant": return Color(hex: "E74C3C")
        default: return Color(hex: "A855F7")
        }
    }
}

struct MapControlButton: View {
    let icon: String
    var gradient: LinearGradient? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        gradient ?? LinearGradient(
                            colors: [Color.white, Color.white],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(gradient != nil ? .white : .primary)
            }
        }
    }
}

#Preview {
    PlacesMapView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
