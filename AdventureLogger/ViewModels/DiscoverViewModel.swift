//
//  DiscoverViewModel.swift
//

import Foundation
import CoreLocation
import Combine

class DiscoverViewModel: ObservableObject {
    @Published var discoveredPlaces: [DiscoveredPlace] = []
    @Published var isLoading = false
    @Published var error: DiscoverError?

    private let locationManager = LocationManager()
    private let placesService = PlacesAPIService()
    private var cancellables = Set<AnyCancellable>()

    func discoverNearbyPlaces(category: String, radius: Double = 5000) {
        isLoading = true
        error = nil

        locationManager.requestLocation { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let location):
                self.fetchNearbyPlaces(
                    location: location,
                    category: category,
                    radius: radius
                )

            case .failure(_):
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.error = .locationAccessDenied
                }
            }
        }
    }

    private func fetchNearbyPlaces(location: CLLocation, category: String, radius: Double) {
        placesService.fetchNearbyPlaces(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            radius: radius,
            type: category
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                switch result {
                case .success(let places):
                    self.discoveredPlaces = places
                case .failure(let error):
                    self.error = error
                }
            }
        }
    }
}

// MARK: - Models for API Response

struct DiscoveredPlace: Identifiable, Decodable {
    let id: String
    let name: String
    let description: String?
    let latitude: Double
    let longitude: Double
    let address: String?
    let types: [String]
    let rating: Double?
    var distance: Double?

    enum CodingKeys: String, CodingKey {
        case id = "place_id"
        case name
        case description = "editorial_summary"
        case geometry
        case address = "vicinity"
        case types
        case rating
    }

    enum GeometryCodingKeys: String, CodingKey {
        case location
    }

    enum LocationCodingKeys: String, CodingKey {
        case lat
        case lng
    }

    enum EditorialSummaryCodingKeys: String, CodingKey {
        case overview
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try? container.decode(String.self, forKey: .address)
        types = try container.decode([String].self, forKey: .types)
        rating = try? container.decode(Double.self, forKey: .rating)

        // Parse nested editorial summary
        if let editorialContainer = try? container.nestedContainer(keyedBy: EditorialSummaryCodingKeys.self, forKey: .description) {
            description = try? editorialContainer.decode(String.self, forKey: .overview)
        } else {
            description = nil
        }

        // Parse nested geometry location
        let geometryContainer = try container.nestedContainer(keyedBy: GeometryCodingKeys.self, forKey: .geometry)
        let locationContainer = try geometryContainer.nestedContainer(keyedBy: LocationCodingKeys.self, forKey: .location)

        latitude = try locationContainer.decode(Double.self, forKey: .lat)
        longitude = try locationContainer.decode(Double.self, forKey: .lng)

        distance = nil
    }

    // Custom initializer for manual creation
    init(id: String, name: String, description: String?, latitude: Double, longitude: Double, address: String?, types: [String], rating: Double?, distance: Double?) {
        self.id = id
        self.name = name
        self.description = description
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.types = types
        self.rating = rating
        self.distance = distance
    }
}

struct PlacesAPIResponse: Decodable {
    let results: [DiscoveredPlace]
    let status: String
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case results
        case status
        case errorMessage = "error_message"
    }
}

// MARK: - Places API Service

class PlacesAPIService {
    // NOTE: In production, store API key securely (e.g., in Keychain or environment variables)
    // For demonstration, using a placeholder
    private let apiKey = "YOUR_GOOGLE_PLACES_API_KEY"
    private let baseURL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"

    func fetchNearbyPlaces(
        latitude: Double,
        longitude: Double,
        radius: Double,
        type: String,
        completion: @escaping (Result<[DiscoveredPlace], DiscoverError>) -> Void
    ) {
        // Check if API key is configured
        guard apiKey != "YOUR_GOOGLE_PLACES_API_KEY" else {
            // Return mock data for development/testing
            completion(.success(generateMockPlaces(latitude: latitude, longitude: longitude)))
            return
        }

        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "location", value: "\(latitude),\(longitude)"),
            URLQueryItem(name: "radius", value: "\(Int(radius))"),
            URLQueryItem(name: "type", value: type),
            URLQueryItem(name: "key", value: apiKey)
        ]

        guard let url = components?.url else {
            completion(.failure(.invalidURL))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(.httpError(httpResponse.statusCode)))
                return
            }

            guard let data = data else {
                completion(.failure(.noData))
                return
            }

            do {
                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(PlacesAPIResponse.self, from: data)

                if apiResponse.status == "OK" {
                    // Calculate distances and sort by distance
                    let userLocation = CLLocation(latitude: latitude, longitude: longitude)
                    var placesWithDistance = apiResponse.results.map { place -> DiscoveredPlace in
                        let placeLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
                        let distance = userLocation.distance(from: placeLocation)
                        return DiscoveredPlace(
                            id: place.id,
                            name: place.name,
                            description: place.description,
                            latitude: place.latitude,
                            longitude: place.longitude,
                            address: place.address,
                            types: place.types,
                            rating: place.rating,
                            distance: distance
                        )
                    }
                    placesWithDistance.sort { ($0.distance ?? 0) < ($1.distance ?? 0) }
                    completion(.success(placesWithDistance))
                } else {
                    completion(.failure(.apiError(apiResponse.errorMessage ?? "Unknown API error")))
                }
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }

        task.resume()
    }

    // Mock data for development/testing when API key is not configured
    private func generateMockPlaces(latitude: Double, longitude: Double) -> [DiscoveredPlace] {
        let mockPlaces = [
            DiscoveredPlace(
                id: "1",
                name: "Nearby Beach Paradise",
                description: "Beautiful sandy beach with crystal clear water",
                latitude: latitude + 0.01,
                longitude: longitude + 0.01,
                address: "123 Beach Road",
                types: ["natural_feature", "beach"],
                rating: 4.5,
                distance: 1200
            ),
            DiscoveredPlace(
                id: "2",
                name: "Mountain Trail Hike",
                description: "Scenic hiking trail with amazing views",
                latitude: latitude - 0.02,
                longitude: longitude + 0.02,
                address: "456 Mountain Way",
                types: ["park", "hiking_area"],
                rating: 4.8,
                distance: 2500
            ),
            DiscoveredPlace(
                id: "3",
                name: "Local Cafe & Restaurant",
                description: "Cozy cafe with great coffee and food",
                latitude: latitude + 0.005,
                longitude: longitude - 0.005,
                address: "789 Main Street",
                types: ["restaurant", "cafe"],
                rating: 4.2,
                distance: 800
            ),
            DiscoveredPlace(
                id: "4",
                name: "Adventure Park",
                description: "Fun activities and adventure sports",
                latitude: latitude - 0.015,
                longitude: longitude - 0.015,
                address: "321 Adventure Lane",
                types: ["tourist_attraction", "park"],
                rating: 4.6,
                distance: 3200
            ),
            DiscoveredPlace(
                id: "5",
                name: "Coastal Lookout",
                description: "Stunning coastal views and photography spot",
                latitude: latitude + 0.03,
                longitude: longitude + 0.01,
                address: "555 Coastal Road",
                types: ["tourist_attraction", "point_of_interest"],
                rating: 4.9,
                distance: 4100
            )
        ]

        return mockPlaces.sorted { ($0.distance ?? 0) < ($1.distance ?? 0) }
    }
}

// MARK: - Error Handling

enum DiscoverError: LocalizedError {
    case locationAccessDenied
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case httpError(Int)
    case noData
    case decodingError(Error)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .locationAccessDenied:
            return "Location access is required to discover nearby places. Please enable location services in Settings."
        case .invalidURL:
            return "Invalid URL configuration. Please try again later."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server. Please try again."
        case .httpError(let code):
            return "Server error (Code: \(code)). Please try again later."
        case .noData:
            return "No data received from server."
        case .decodingError(let error):
            return "Failed to parse data: \(error.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}
