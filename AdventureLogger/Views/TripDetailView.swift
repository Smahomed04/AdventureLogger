//
//  TripDetailView.swift
//  AdventureLogger
//

import SwiftUI
import CoreData
import MapKit

struct TripDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var trip: Trip

    @State private var isEditing = false
    @State private var editedName = ""
    @State private var editedDescription = ""
    @State private var editedStartDate = Date()
    @State private var editedEndDate = Date()
    @State private var showingDeleteAlert = false
    @State private var showingAddPlaces = false

    @FetchRequest(sortDescriptors: []) private var allPlaces: FetchedResults<Place>

    var tripPlaces: [Place] {
        (trip.places as? Set<Place>)?.sorted { p1, p2 in
            (p1.visitedDate ?? p1.createdAt ?? Date()) < (p2.visitedDate ?? p2.createdAt ?? Date())
        } ?? []
    }

    var unassignedPlaces: [Place] {
        allPlaces.filter { $0.trip == nil }
    }

    var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long

        if let start = trip.startDate, let end = trip.endDate {
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
        return "No dates set"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Gradient Header
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 200)
                    .overlay(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        if isEditing {
                            TextField("Trip Name", text: $editedName)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        } else {
                            Text(trip.name ?? "Untitled Trip")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)

                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 14))
                                Text(dateRangeText)
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(20)
                }

                VStack(alignment: .leading, spacing: 20) {
                    // Stats Card
                    HStack(spacing: 0) {
                        StatBox(
                            icon: "mappin.and.ellipse",
                            value: "\(tripPlaces.count)",
                            label: "Places",
                            color: Color(hex: "4ECDC4")
                        )

                        Divider()
                            .frame(height: 50)

                        StatBox(
                            icon: "checkmark.circle.fill",
                            value: "\(tripPlaces.filter { $0.isVisited }.count)",
                            label: "Visited",
                            color: Color.green
                        )

                        Divider()
                            .frame(height: 50)

                        StatBox(
                            icon: "star.fill",
                            value: String(format: "%.1f", averageRating),
                            label: "Avg Rating",
                            color: Color.yellow
                        )
                    }
                    .padding(.vertical, 20)
                    .glassCard()
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Description Card
                    if isEditing {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Description", systemImage: "text.alignleft")
                                .font(.system(size: 18, weight: .bold, design: .rounded))

                            TextEditor(text: $editedDescription)
                                .frame(minHeight: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                        .padding(16)
                        .glassCard()
                        .padding(.horizontal)
                    } else if let description = trip.tripDescription, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Description", systemImage: "text.alignleft")
                                .font(.system(size: 18, weight: .bold, design: .rounded))

                            Text(description)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .glassCard()
                        .padding(.horizontal)
                    }

                    // Date editing
                    if isEditing {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Dates", systemImage: "calendar")
                                .font(.system(size: 18, weight: .bold, design: .rounded))

                            DatePicker("Start Date", selection: $editedStartDate, displayedComponents: .date)
                            DatePicker("End Date", selection: $editedEndDate, in: editedStartDate..., displayedComponents: .date)
                        }
                        .padding(16)
                        .glassCard()
                        .padding(.horizontal)
                    }

                    // Places Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label("Adventures", systemImage: "map.fill")
                                .font(.system(size: 20, weight: .bold, design: .rounded))

                            Spacer()

                            Button(action: { showingAddPlaces = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Places")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal, 16)

                        if tripPlaces.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "map")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("No places added yet")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                                Text("Tap 'Add Places' to start building your trip")
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(tripPlaces, id: \.id) { place in
                                    NavigationLink(destination: PlaceDetailView(place: place)) {
                                        TripPlaceRow(place: place) {
                                            removePlace(place)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 20)
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
        .sheet(isPresented: $showingAddPlaces) {
            AddPlacesToTripView(trip: trip, availablePlaces: unassignedPlaces)
        }
        .alert("Delete Trip", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTrip()
            }
        } message: {
            Text("Are you sure you want to delete this trip? The places will not be deleted.")
        }
    }

    private var averageRating: Double {
        let visitedPlaces = tripPlaces.filter { $0.isVisited && $0.rating > 0 }
        guard !visitedPlaces.isEmpty else { return 0 }
        let total = visitedPlaces.reduce(0.0) { $0 + Double($1.rating) }
        return total / Double(visitedPlaces.count)
    }

    private func startEditing() {
        editedName = trip.name ?? ""
        editedDescription = trip.tripDescription ?? ""
        editedStartDate = trip.startDate ?? Date()
        editedEndDate = trip.endDate ?? Date()
        isEditing = true
    }

    private func saveChanges() {
        trip.name = editedName
        trip.tripDescription = editedDescription.isEmpty ? nil : editedDescription
        trip.startDate = editedStartDate
        trip.endDate = editedEndDate
        trip.updatedAt = Date()

        do {
            try viewContext.save()
            isEditing = false
        } catch {
            let nsError = error as NSError
            print("Error saving changes: \(nsError), \(nsError.userInfo)")
        }
    }

    private func removePlace(_ place: Place) {
        place.trip = nil
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error removing place: \(nsError), \(nsError.userInfo)")
        }
    }

    private func deleteTrip() {
        // Remove trip reference from all places
        for place in tripPlaces {
            place.trip = nil
        }

        viewContext.delete(trip)

        do {
            try viewContext.save()
            dismiss()
        } catch {
            let nsError = error as NSError
            print("Error deleting trip: \(nsError), \(nsError.userInfo)")
        }
    }
}

struct TripPlaceRow: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var place: Place
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(categoryGradient)
                    .frame(width: 50, height: 50)

                Image(systemName: categoryIcon)
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(place.name ?? "Unknown")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 9))
                        Text(place.category ?? "Other")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(categoryColor.opacity(0.15))
                    .foregroundColor(categoryColor)
                    .cornerRadius(6)

                    if place.isVisited {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 9))
                            Text("Visited")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                    }
                }
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red.opacity(0.7))
                    .font(.system(size: 22))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.cardBackground)
                .shadow(
                    color: colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.08),
                    radius: 6,
                    x: 0,
                    y: 3
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

#Preview {
    NavigationView {
        TripDetailView(trip: {
            let context = PersistenceController.preview.container.viewContext
            let trip = Trip(context: context)
            trip.id = UUID()
            trip.name = "Summer in Europe"
            trip.tripDescription = "Amazing trip across Europe"
            trip.startDate = Date()
            trip.endDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
            return trip
        }())
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
