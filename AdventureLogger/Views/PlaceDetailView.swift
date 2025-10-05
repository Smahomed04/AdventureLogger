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
            VStack(alignment: .leading, spacing: 0) {
                // Gradient Header
                ZStack(alignment: .bottomLeading) {
                    // Background gradient
                    CategoryGradient.forCategory(place.category ?? "Other")
                        .frame(height: 180)
                        .overlay(
                            LinearGradient(
                                colors: [Color.clear, Color.black.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Content overlay
                    VStack(alignment: .leading, spacing: 12) {
                        // Category badge
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: categoryIcon)
                                    .font(.system(size: 12, weight: .semibold))
                                Text(place.category ?? "Other")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.25))
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)

                            Spacer()

                            if place.isVisited {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("Visited")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.25))
                                .background(.ultraThinMaterial)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                            }
                        }

                        // Title
                        if isEditing {
                            TextField("Place Name", text: $editedName)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        } else {
                            Text(place.name ?? "Unknown Place")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(20)
                }

                VStack(alignment: .leading, spacing: 20) {
                    // Map preview card
                    VStack(spacing: 0) {
                        MapPreview(
                            latitude: place.latitude,
                            longitude: place.longitude,
                            placeName: place.name ?? "Place"
                        )
                        .frame(height: 200)

                        // Address in map card
                        if let address = place.address {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(Color.red.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color.red, Color.red.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .font(.system(size: 16))
                                }

                                Text(address)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(16)
                            .background(Color.cardBackground)
                        }
                    }
                    .glassCard(cornerRadius: 16)
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Description Card
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Description", systemImage: "text.alignleft")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        if isEditing {
                            TextField("Add a description...", text: $editedDescription, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        } else {
                            Text(place.placeDescription ?? "No description added yet")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(place.placeDescription == nil ? .secondary : .primary)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()
                    .padding(.horizontal)

                    // Visit Status Card
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Visit Status", systemImage: "checkmark.seal")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        if isEditing {
                            Toggle("Visited", isOn: $editedVisited)
                                .toggleStyle(SwitchToggleStyle(tint: .green))

                            if editedVisited {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Rating")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(.secondary)

                                    HStack(spacing: 8) {
                                        ForEach(1...5, id: \.self) { star in
                                            Image(systemName: star <= editedRating ? "star.fill" : "star")
                                                .foregroundColor(star <= editedRating ? .yellow : .gray)
                                                .font(.system(size: 28))
                                                .onTapGesture {
                                                    withAnimation(.spring(response: 0.3)) {
                                                        editedRating = star
                                                    }
                                                }
                                        }
                                    }

                                    if editedRating > 0 {
                                        Text(ratingText(for: editedRating))
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill(place.isVisited ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: place.isVisited ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(place.isVisited ? .green : .gray)
                                            .font(.system(size: 16))
                                    }

                                    Text(place.isVisited ? "Visited" : "Not visited yet")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                }

                                if place.isVisited, let visitedDate = place.visitedDate {
                                    HStack(spacing: 10) {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 14))
                                        Text("Visited on \(visitedDate, formatter: dateFormatter)")
                                            .font(.system(size: 14, weight: .regular, design: .rounded))
                                            .foregroundColor(.secondary)
                                    }
                                }

                                if place.isVisited && place.rating > 0 {
                                    HStack(spacing: 6) {
                                        ForEach(0..<Int(place.rating), id: \.self) { _ in
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                                .font(.system(size: 18))
                                        }
                                        ForEach(Int(place.rating)..<5, id: \.self) { _ in
                                            Image(systemName: "star")
                                                .foregroundColor(.gray.opacity(0.3))
                                                .font(.system(size: 18))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()
                    .padding(.horizontal)

                    // Personal Reflection Card
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Personal Reflection", systemImage: "quote.bubble")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

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
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                    .foregroundColor(.primary)
                            } else {
                                Text("No reflection added yet")
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()
                    .padding(.horizontal)

                    // Category editing
                    if isEditing {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Category", systemImage: "tag")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)

                            Picker("Category", selection: $editedCategory) {
                                Text("Beach").tag("Beach")
                                Text("Hike").tag("Hike")
                                Text("Activity").tag("Activity")
                                Text("Restaurant").tag("Restaurant")
                                Text("Worship").tag("Place of Worship")
                                Text("Other").tag("Other")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassCard()
                        .padding(.horizontal)
                    }

                    // Metadata
                    if let createdAt = place.createdAt {
                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text("Added on \(createdAt, formatter: dateFormatter)")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
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
            if editedVisited {
                // Setting as visited
                if place.visitedDate == nil {
                    place.visitedDate = Date()
                }
            } else {
                // Setting as NOT visited - clear visited date and rating
                place.visitedDate = nil
                place.rating = 0
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
        case "Place of Worship": return "building.columns.fill"
        default: return "mappin.circle.fill"
        }
    }

    private var categoryColor: Color {
        switch category {
        case "Beach": return .blue
        case "Hike": return .green
        case "Activity": return .orange
        case "Restaurant": return .red
        case "Place of Worship": return Color(hex: "9B59B6")
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
