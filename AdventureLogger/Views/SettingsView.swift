//
//  SettingsView.swift
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @AppStorage("defaultCategory") private var defaultCategory = "Activity"
    @AppStorage("searchRadius") private var searchRadius = 5.0
    @AppStorage("mapType") private var mapType = "standard"
    @AppStorage("showVisitedOnly") private var showVisitedOnly = false
    @AppStorage("sortOrder") private var sortOrder = "name"
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("autoSyncCloudKit") private var autoSyncCloudKit = true

    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: []) private var places: FetchedResults<Place>

    @State private var showingClearDataAlert = false
    @State private var showingExportSheet = false

    let categories = ["Beach", "Hike", "Activity", "Restaurant", "Other"]
    let mapTypes = ["standard", "hybrid", "satellite"]
    let sortOrders = ["name", "date", "distance", "rating"]

    var body: some View {
        NavigationView {
            Form {
                // MARK: - Header
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Settings")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Customize your adventure experience")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                // MARK: - General Settings
                Section(header: Text("General").font(.system(size: 14, weight: .semibold, design: .rounded))) {
                    Picker("Default Category", selection: $defaultCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }

                    Picker("Sort Order", selection: $sortOrder) {
                        Text("Name").tag("name")
                        Text("Date Added").tag("date")
                        Text("Distance").tag("distance")
                        Text("Rating").tag("rating")
                    }

                    Toggle("Show Visited Places Only", isOn: $showVisitedOnly)
                }

                // MARK: - Discovery Settings
                Section(header: Text("Discovery").font(.system(size: 14, weight: .semibold, design: .rounded)), footer: Text("Set the search radius for discovering nearby places").font(.system(size: 12, weight: .regular, design: .rounded))) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Search Radius: \(String(format: "%.1f", searchRadius)) km")
                            .font(.subheadline)

                        Slider(value: $searchRadius, in: 1...50, step: 0.5)
                    }

                    Picker("Map Type", selection: $mapType) {
                        Text("Standard").tag("standard")
                        Text("Hybrid").tag("hybrid")
                        Text("Satellite").tag("satellite")
                    }
                }

                // MARK: - Cloud & Sync
                Section(header: Text("iCloud & Sync").font(.system(size: 14, weight: .semibold, design: .rounded)), footer: Text("Automatically sync your adventures across all your devices using iCloud").font(.system(size: 12, weight: .regular, design: .rounded))) {
                    Toggle("Auto Sync with iCloud", isOn: $autoSyncCloudKit)

                    Toggle("Enable Notifications", isOn: $enableNotifications)
                }

                // MARK: - Statistics
                Section(header: Text("Statistics").font(.system(size: 14, weight: .semibold, design: .rounded))) {
                    HStack {
                        Text("Total Places")
                        Spacer()
                        Text("\(places.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Visited")
                        Spacer()
                        Text("\(visitedCount)")
                            .foregroundColor(.green)
                    }

                    HStack {
                        Text("Not Visited")
                        Spacer()
                        Text("\(notVisitedCount)")
                            .foregroundColor(.orange)
                    }

                    HStack {
                        Text("Average Rating")
                        Spacer()
                        if averageRating > 0 {
                            HStack(spacing: 4) {
                                Text(String(format: "%.1f", averageRating))
                                    .foregroundColor(.secondary)
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                        } else {
                            Text("N/A")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // MARK: - Data Management
                Section(header: Text("Data Management").font(.system(size: 14, weight: .semibold, design: .rounded))) {
                    Button(action: { showingExportSheet = true }) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }

                    Button(action: {
                        ImageCacheManager.shared.clearCache()
                    }) {
                        Label("Clear Image Cache", systemImage: "photo.on.rectangle.angled")
                    }

                    Button(role: .destructive, action: { showingClearDataAlert = true }) {
                        Label("Clear All Data", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }

                // MARK: - About
                Section(header: Text("About").font(.system(size: 14, weight: .semibold, design: .rounded))) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com")!) {
                        HStack {
                            Text("GitHub Repository")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                    }

                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("Are you sure you want to delete all your adventures? This action cannot be undone.")
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportDataView(places: Array(places))
            }
        }
    }

    // MARK: - Computed Properties
    private var visitedCount: Int {
        places.filter { $0.isVisited }.count
    }

    private var notVisitedCount: Int {
        places.filter { !$0.isVisited }.count
    }

    private var averageRating: Double {
        let visitedPlaces = places.filter { $0.isVisited && $0.rating > 0 }
        guard !visitedPlaces.isEmpty else { return 0 }
        let total = visitedPlaces.reduce(0.0) { $0 + Double($1.rating) }
        return total / Double(visitedPlaces.count)
    }

    // MARK: - Functions
    private func clearAllData() {
        for place in places {
            viewContext.delete(place)
        }

        do {
            try viewContext.save()
        } catch {
            print("Error clearing data: \(error)")
        }
    }
}

// MARK: - Export Data View
struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    let places: [Place]

    @State private var exportFormat = "JSON"
    @State private var includeReflections = true
    @State private var includeUnvisited = true
    @State private var showingShareSheet = false
    @State private var exportedDataURL: URL?

    let formats = ["JSON", "CSV", "Text"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Export Options")) {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(formats, id: \.self) { format in
                            Text(format).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    Toggle("Include Personal Reflections", isOn: $includeReflections)
                    Toggle("Include Unvisited Places", isOn: $includeUnvisited)
                }

                Section(header: Text("Summary")) {
                    HStack {
                        Text("Total Places")
                        Spacer()
                        Text("\(filteredPlaces.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Export Format")
                        Spacer()
                        Text(exportFormat)
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button(action: exportData) {
                        HStack {
                            Spacer()
                            Label("Export Data", systemImage: "square.and.arrow.up")
                                .font(.headline)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedDataURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private var filteredPlaces: [Place] {
        var filtered = places
        if !includeUnvisited {
            filtered = filtered.filter { $0.isVisited }
        }
        return filtered
    }

    private func exportData() {
        let fileName = "AdventureLogger_Export_\(Date().timeIntervalSince1970).\(exportFormat.lowercased())"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        var content = ""

        switch exportFormat {
        case "JSON":
            content = exportAsJSON()
        case "CSV":
            content = exportAsCSV()
        case "Text":
            content = exportAsText()
        default:
            break
        }

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            exportedDataURL = fileURL
            showingShareSheet = true
        } catch {
            print("Error exporting data: \(error)")
        }
    }

    private func exportAsJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let exportData = filteredPlaces.map { place in
            [
                "name": place.name ?? "",
                "category": place.category ?? "",
                "latitude": place.latitude,
                "longitude": place.longitude,
                "address": place.address ?? "",
                "isVisited": place.isVisited,
                "rating": place.rating,
                "reflection": includeReflections ? (place.personalReflection ?? "") : ""
            ] as [String: Any]
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }

        return "[]"
    }

    private func exportAsCSV() -> String {
        var csv = "Name,Category,Latitude,Longitude,Address,Visited,Rating"
        if includeReflections {
            csv += ",Reflection"
        }
        csv += "\n"

        for place in filteredPlaces {
            let row = [
                place.name ?? "",
                place.category ?? "",
                "\(place.latitude)",
                "\(place.longitude)",
                place.address ?? "",
                place.isVisited ? "Yes" : "No",
                "\(place.rating)"
            ]

            csv += row.joined(separator: ",")

            if includeReflections {
                csv += ",\"\(place.personalReflection ?? "")\""
            }

            csv += "\n"
        }

        return csv
    }

    private func exportAsText() -> String {
        var text = "Adventure Logger Export\n"
        text += "Generated: \(Date())\n"
        text += "Total Places: \(filteredPlaces.count)\n\n"
        text += String(repeating: "=", count: 50) + "\n\n"

        for place in filteredPlaces {
            text += "Name: \(place.name ?? "Unknown")\n"
            text += "Category: \(place.category ?? "N/A")\n"
            text += "Location: \(place.latitude), \(place.longitude)\n"
            if let address = place.address {
                text += "Address: \(address)\n"
            }
            text += "Visited: \(place.isVisited ? "Yes" : "No")\n"
            if place.isVisited {
                text += "Rating: \(place.rating) stars\n"
                if includeReflections, let reflection = place.personalReflection {
                    text += "Reflection: \(reflection)\n"
                }
            }
            text += "\n" + String(repeating: "-", count: 50) + "\n\n"
        }

        return text
    }
}

// MARK: - Share Sheet
#if canImport(UIKit)
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
