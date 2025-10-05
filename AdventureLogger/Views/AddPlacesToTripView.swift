//
//  AddPlacesToTripView.swift
//  AdventureLogger
//

import SwiftUI
import CoreData

struct AddPlacesToTripView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var trip: Trip
    let availablePlaces: [Place]

    @State private var selectedPlaces: Set<UUID> = []
    @State private var searchText = ""

    var filteredPlaces: [Place] {
        if searchText.isEmpty {
            return availablePlaces
        }
        return availablePlaces.filter { place in
            place.name?.localizedCaseInsensitiveContains(searchText) ?? false ||
            place.placeDescription?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if availablePlaces.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        Text("All places are assigned!")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("All your adventures are already part of a trip")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredPlaces, id: \.id) { place in
                                SelectablePlaceRow(
                                    place: place,
                                    isSelected: selectedPlaces.contains(place.id ?? UUID())
                                ) {
                                    toggleSelection(place)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Add Places to Trip")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search places")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add (\(selectedPlaces.count))") {
                        addSelectedPlaces()
                    }
                    .disabled(selectedPlaces.isEmpty)
                }
            }
        }
    }

    private func toggleSelection(_ place: Place) {
        guard let id = place.id else { return }
        if selectedPlaces.contains(id) {
            selectedPlaces.remove(id)
        } else {
            selectedPlaces.insert(id)
        }
    }

    private func addSelectedPlaces() {
        for place in availablePlaces {
            if let id = place.id, selectedPlaces.contains(id) {
                place.trip = trip
            }
        }

        do {
            try viewContext.save()
            dismiss()
        } catch {
            let nsError = error as NSError
            print("Error adding places to trip: \(nsError), \(nsError.userInfo)")
        }
    }
}

struct SelectablePlaceRow: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var place: Place
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Selection indicator
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 2)
                        .background(
                            Circle().fill(
                                isSelected ?
                                LinearGradient(
                                    colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        )
                        .frame(width: 28, height: 28)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .bold))
                    }
                }

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

                    if let description = place.placeDescription {
                        Text(description)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

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
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isSelected ?
                                LinearGradient(
                                    colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(colors: [Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.08),
                        radius: isSelected ? 10 : 6,
                        x: 0,
                        y: 3
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
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
    AddPlacesToTripView(
        trip: {
            let context = PersistenceController.preview.container.viewContext
            let trip = Trip(context: context)
            trip.id = UUID()
            trip.name = "Summer Trip"
            return trip
        }(),
        availablePlaces: []
    )
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
