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

                    VStack(spacing: 12) {
                        // Map type selector
                        Button(action: toggleMapType) {
                            Image(systemName: "map")
                                .font(.title2)
                                .foregroundColor(.primary)
                                .padding(12)
                                .background(Color(white: 1.0))
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }

                        // Center on user location
                        Button(action: centerOnUserLocation) {
                            Image(systemName: "location.fill")
                                .font(.title2)
                                .foregroundColor(.primary)
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
                    }
                    .padding(.trailing)
                }
                .padding(.top, 60)

                Spacer()

                // Place count badge
                if !places.isEmpty {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.white)
                        Text("\(places.count) place\(places.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .cornerRadius(20)
                    .shadow(radius: 4)
                    .padding(.bottom, 20)
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
        case "Beach": return .blue
        case "Hike": return .green
        case "Activity": return .orange
        case "Restaurant": return .red
        default: return .purple
        }
    }
}

#Preview {
    PlacesMapView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
