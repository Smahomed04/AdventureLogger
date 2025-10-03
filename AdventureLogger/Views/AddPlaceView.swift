//
//  AddPlaceView.swift
//

import SwiftUI
import CoreLocation
import MapKit
import Combine
import CoreData

struct AddPlaceView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var locationManager = LocationManager()

    @State private var name = ""
    @State private var description = ""
    @State private var category = "Activity"
    @State private var latitude = 0.0
    @State private var longitude = 0.0
    @State private var address = ""
    @State private var isVisited = false
    @State private var rating = 0
    @State private var personalReflection = ""

    @State private var useCurrentLocation = false
    @State private var showingLocationError = false
    @State private var locationErrorMessage = ""

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093), // Sydney default
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    let categories = ["Beach", "Hike", "Activity", "Restaurant", "Other"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Place Name", text: $name)

                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)

                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }

                Section(header: Text("Location")) {
                    Toggle("Use Current Location", isOn: $useCurrentLocation)
                        .onChange(of: useCurrentLocation) { newValue in
                            if newValue {
                                requestLocation()
                            }
                        }

                    if !useCurrentLocation {
                        HStack {
                            Text("Latitude")
                            Spacer()
                            TextField("0.0", value: $latitude, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }

                        HStack {
                            Text("Longitude")
                            Spacer()
                            TextField("0.0", value: $longitude, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    } else {
                        HStack {
                            Text("Latitude")
                            Spacer()
                            Text("\(latitude, specifier: "%.6f")")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Longitude")
                            Spacer()
                            Text("\(longitude, specifier: "%.6f")")
                                .foregroundColor(.secondary)
                        }
                    }

                    TextField("Address (Optional)", text: $address)

                    // Map preview
                    Map(coordinateRegion: $region, annotationItems: [MapLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), name: name.isEmpty ? "New Place" : name)]) { location in
                        MapMarker(coordinate: location.coordinate, tint: .red)
                    }
                    .frame(height: 200)
                    .cornerRadius(8)
                    .onChange(of: latitude) { newValue in
                        updateRegion()
                    }
                    .onChange(of: longitude) { newValue in
                        updateRegion()
                    }
                }

                Section(header: Text("Visit Status")) {
                    Toggle("Already Visited", isOn: $isVisited)

                    if isVisited {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Rating")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack(spacing: 8) {
                                ForEach(1...5, id: \.self) { ratingValue in
                                    Button(action: {
                                        rating = ratingValue
                                    }) {
                                        Image(systemName: ratingValue <= rating ? "star.fill" : "star")
                                            .foregroundColor(ratingValue <= rating ? .yellow : .gray)
                                            .font(.title3)
                                    }
                                }
                            }
                        }

                        TextField("Personal Reflection", text: $personalReflection, axis: .vertical)
                            .lineLimit(3...8)
                    }
                }
            }
            .navigationTitle("Add New Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePlace()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .alert("Location Error", isPresented: $showingLocationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(locationErrorMessage)
            }
        }
    }

    private func requestLocation() {
        locationManager.requestLocation { result in
            switch result {
            case .success(let location):
                latitude = location.coordinate.latitude
                longitude = location.coordinate.longitude

                // Reverse geocode to get address
                let geocoder = CLGeocoder()
                geocoder.reverseGeocodeLocation(location) { placemarks, error in
                    if let placemark = placemarks?.first {
                        var addressComponents: [String] = []
                        if let street = placemark.thoroughfare {
                            addressComponents.append(street)
                        }
                        if let city = placemark.locality {
                            addressComponents.append(city)
                        }
                        if let state = placemark.administrativeArea {
                            addressComponents.append(state)
                        }
                        address = addressComponents.joined(separator: ", ")
                    }
                }

            case .failure(let error):
                useCurrentLocation = false
                locationErrorMessage = error.localizedDescription
                showingLocationError = true
            }
        }
    }

    private func updateRegion() {
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }

    private func savePlace() {
        let newPlace = Place(context: viewContext)
        newPlace.id = UUID()
        newPlace.name = name
        newPlace.placeDescription = description
        newPlace.category = category
        newPlace.latitude = latitude
        newPlace.longitude = longitude
        newPlace.address = address.isEmpty ? nil : address
        newPlace.isVisited = isVisited
        newPlace.createdAt = Date()
        newPlace.updatedAt = Date()

        if isVisited {
            newPlace.visitedDate = Date()
            newPlace.rating = Int16(rating)
            newPlace.personalReflection = personalReflection.isEmpty ? nil : personalReflection
        }

        do {
            try viewContext.save()
            dismiss()
        } catch {
            let nsError = error as NSError
            print("Error saving place: \(nsError), \(nsError.userInfo)")
            locationErrorMessage = "Failed to save place. Please try again."
            showingLocationError = true
        }
    }
}

// Location Manager for handling Core Location
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var completion: ((Result<CLLocation, Error>) -> Void)?

    @Published var authorizationStatus: CLAuthorizationStatus

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    func requestLocation(completion: @escaping (Result<CLLocation, Error>) -> Void) {
        self.completion = completion

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            completion(.failure(LocationError.accessDenied))
        @unknown default:
            completion(.failure(LocationError.unknown))
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            completion?(.success(location))
            completion = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion?(.failure(error))
        completion = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            completion?(.failure(LocationError.accessDenied))
            completion = nil
        }
    }
}

enum LocationError: LocalizedError {
    case accessDenied
    case unknown

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Location access denied. Please enable location services in Settings."
        case .unknown:
            return "An unknown error occurred while accessing location."
        }
    }
}

#Preview {
    AddPlaceView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
