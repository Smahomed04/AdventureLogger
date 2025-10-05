//
//  NetworkMonitor.swift
//  AdventureLogger
//

import Foundation
import Network
import Combine

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown

    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown

        var description: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .ethernet: return "Ethernet"
            case .unknown: return "No Connection"
            }
        }

        var icon: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .ethernet: return "cable.connector"
            case .unknown: return "wifi.slash"
            }
        }
    }

    private init() {
        startMonitoring()
    }

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.updateConnectionType(path)
            }
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    private func updateConnectionType(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }
    }
}

// MARK: - Network Request Helpers

extension URLSession {
    /// Enhanced data task with retry logic and offline handling
    func enhancedDataTask(
        with request: URLRequest,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 2.0,
        completion: @escaping (Result<(Data, URLResponse), Error>) -> Void
    ) -> URLSessionDataTask {
        var currentRetry = 0

        func attemptRequest() {
            let task = dataTask(with: request) { data, response, error in
                if let error = error {
                    // Check if we should retry
                    if currentRetry < maxRetries {
                        currentRetry += 1
                        print("⚠️ Request failed, retry \(currentRetry)/\(maxRetries): \(error.localizedDescription)")

                        // Exponential backoff
                        let delay = retryDelay * Double(currentRetry)
                        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                            attemptRequest()
                        }
                    } else {
                        completion(.failure(error))
                    }
                    return
                }

                guard let data = data, let response = response else {
                    completion(.failure(NSError(domain: "NetworkMonitor", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data or response"])))
                    return
                }

                completion(.success((data, response)))
            }
            task.resume()
        }

        // Start the initial request
        let dummyTask = dataTask(with: request) { _, _, _ in }
        attemptRequest()
        return dummyTask
    }
}
