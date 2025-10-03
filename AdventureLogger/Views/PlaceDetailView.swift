//
//  PlaceDetailView.swift
//

import SwiftUI
import MapKit
import CoreData

struct PlaceDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var place: Place

    @State private var isEditing = false
    @State private var editedName = ""
    @State private var editedDescription = ""
    @State private var editedCategory = ""
    @State private var editedReflection = ""
    @State private var editedRating = 0
    @State private var editedVisited = false
    @State private var showingDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with category badge
                HStack {
                    CategoryBadge(category: place.category ?? "Other")
                    Spacer()
                    if place.isVisited {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Visited")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                // Title
                if isEditing {
                    TextField("Place Name", text: $editedName)
                        .font(.title)
                        .fontWeight(.bold)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                } else {
                    Text(place.name ?? "Unknown Place")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                }

                // Map preview
                MapPreview(
                    latitude: place.latitude,
                    longitude: place.longitude,
                    placeName: place.name ?? "Place"
                )
                .frame(height: 200)
                .cornerRadius(12)
                .padding(.horizontal)

                // Address
                if let address = place.address {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.red)
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }

                Divider()
                    .padding(.horizontal)

                // Description Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)

                    if isEditing {
                        TextField("Add a description...", text: $editedDescription, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    } else {
                        Text(place.placeDescription ?? "No description")
                            .font(.body)
                            .foregroundColor(place.placeDescription == nil ? .secondary : .primary)
                    }
                }
                .padding(.horizontal)

                Divider()
                    .padding(.horizontal)

                // Visited Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Visit Status")
                        .font(.headline)

                    if isEditing {
                        Toggle("Visited", isOn: $editedVisited)
                            .toggleStyle(SwitchToggleStyle(tint: .green))

                        if editedVisited {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Rating")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    HStack(spacing: 4) {
                                        ForEach(1...5, id: \.self) { star in
                                            Image(systemName: star <= editedRating ? "star.fill" : "star")
                                                .foregroundColor(star <= editedRating ? .yellow : .gray)
                                                .font(.title2)
                                                .onTapGesture {
                                                    editedRating = star
                                                }
                                        }
                                    }
                                }

                                if editedRating > 0 {
                                    Text(ratingText(for: editedRating))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: place.isVisited ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(place.isVisited ? .green : .gray)
                            Text(place.isVisited ? "Visited" : "Not visited yet")
                                .font(.body)
                        }

                        if place.isVisited, let visitedDate = place.visitedDate {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.secondary)
                                Text("Visited on \(visitedDate, formatter: dateFormatter)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if place.isVisited && place.rating > 0 {
                            HStack(spacing: 4) {
                                ForEach(0..<Int(place.rating), id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                }
                                ForEach(Int(place.rating)..<5, id: \.self) { _ in
                                    Image(systemName: "star")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Divider()
                    .padding(.horizontal)

                // Personal Reflection Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Personal Reflection")
                        .font(.headline)

                    if isEditing {
                        TextEditor(text: $editedReflection)
                            .frame(minHeight: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    } else {
                        if let reflection = place.personalReflection, !reflection.isEmpty {
                            Text(reflection)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        } else {
                            Text("No reflection added yet")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                }
                .padding(.horizontal)

                // Category editing
                if isEditing {
                    Divider()
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)

                        Picker("Category", selection: $editedCategory) {
                            Text("Beach").tag("Beach")
                            Text("Hike").tag("Hike")
                            Text("Activity").tag("Activity")
                            Text("Restaurant").tag("Restaurant")
                            Text("Other").tag("Other")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.horizontal)
                }

                // Metadata
                VStack(alignment: .leading, spacing: 4) {
                    if let createdAt = place.createdAt {
                        Text("Added on \(createdAt, formatter: dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveChanges()
                    } else {
                        startEditing()
                    }
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    Button("Cancel") {
                        isEditing = false
                    }
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                if !isEditing {
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .alert("Delete Place", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePlace()
            }
        } message: {
            Text("Are you sure you want to delete this place? This action cannot be undone.")
        }
    }

    private func startEditing() {
        editedName = place.name ?? ""
        editedDescription = place.placeDescription ?? ""
        editedCategory = place.category ?? "Other"
        editedReflection = place.personalReflection ?? ""
        editedRating = Int(place.rating)
        editedVisited = place.isVisited
        isEditing = true
    }

    private func saveChanges() {
        place.name = editedName
        place.placeDescription = editedDescription
        place.category = editedCategory
        place.personalReflection = editedReflection
        place.rating = Int16(editedRating)

        // Update visited status
        if editedVisited != place.isVisited {
            place.isVisited = editedVisited
            if editedVisited && place.visitedDate == nil {
                place.visitedDate = Date()
            }
        }

        place.updatedAt = Date()

        do {
            try viewContext.save()
            isEditing = false
        } catch {
            let nsError = error as NSError
            print("Error saving changes: \(nsError), \(nsError.userInfo)")
        }
    }

    private func deletePlace() {
        viewContext.delete(place)

        do {
            try viewContext.save()
            dismiss()
        } catch {
            let nsError = error as NSError
            print("Error deleting place: \(nsError), \(nsError.userInfo)")
        }
    }

    private func ratingText(for rating: Int) -> String {
        switch rating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Very Good"
        case 5: return "Excellent"
        default: return ""
        }
    }
}

struct CategoryBadge: View {
    let category: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: categoryIcon)
            Text(category)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(categoryColor.opacity(0.2))
        .foregroundColor(categoryColor)
        .cornerRadius(16)
    }

    private var categoryIcon: String {
        switch category {
        case "Beach": return "beach.umbrella.fill"
        case "Hike": return "figure.hiking"
        case "Activity": return "sportscourt.fill"
        case "Restaurant": return "fork.knife"
        default: return "mappin.circle.fill"
        }
    }

    private var categoryColor: Color {
        switch category {
        case "Beach": return .blue
        case "Hike": return .green
        case "Activity": return .orange
        case "Restaurant": return .red
        default: return .purple
        }
    }
}

struct MapPreview: View {
    let latitude: Double
    let longitude: Double
    let placeName: String

    @State private var region: MKCoordinateRegion

    init(latitude: Double, longitude: Double, placeName: String) {
        self.latitude = latitude
        self.longitude = longitude
        self.placeName = placeName

        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }

    var body: some View {
        Map(coordinateRegion: .constant(region), annotationItems: [MapLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), name: placeName)]) { location in
            MapMarker(coordinate: location.coordinate, tint: .red)
        }
    }
}

struct MapLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let name: String
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

#Preview {
    NavigationView {
        PlaceDetailView(place: {
            let context = PersistenceController.preview.container.viewContext
            let place = Place(context: context)
            place.id = UUID()
            place.name = "Bondi Beach"
            place.category = "Beach"
            place.latitude = -33.8908
            place.longitude = 151.2743
            place.placeDescription = "Famous beach in Sydney"
            place.isVisited = true
            place.visitedDate = Date()
            place.rating = 5
            place.personalReflection = "Amazing beach with beautiful views and great surfing conditions!"
            place.createdAt = Date()
            place.updatedAt = Date()
            return place
        }())
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
