//
//  PlaceListView.swift
//
//

import SwiftUI
import CoreData

struct PlaceListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Place.isVisited, ascending: true),
            NSSortDescriptor(keyPath: \Place.name, ascending: true)
        ],
        animation: .default)
    private var places: FetchedResults<Place>

    @State private var showingAddPlace = false
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var refreshID = UUID()

    let categories = ["All", "Beach", "Hike", "Activity", "Restaurant", "Other"]

    var filteredPlaces: [Place] {
        var filtered = Array(places)

        // Filter by category
        if selectedCategory != "All" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }

        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { place in
                place.name?.localizedCaseInsensitiveContains(searchText) ?? false ||
                place.placeDescription?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }

        return filtered
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            CategoryChip(
                                title: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(Color(.systemBackground))

                // Places list
                if filteredPlaces.isEmpty {
                    EmptyStateView(
                        icon: "map.fill",
                        title: "No Adventures Yet",
                        message: searchText.isEmpty ?
                            "Start tracking your adventures by adding your first place!" :
                            "No places found matching '\(searchText)'"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredPlaces, id: \.id) { place in
                                NavigationLink(destination:
                                    PlaceDetailView(place: place)
                                        .onDisappear {
                                            // Force UI refresh when returning from detail view
                                            refreshID = UUID()
                                        }
                                ) {
                                    PlaceRowView(place: place)
                                        .id(refreshID)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                    }
                    .refreshable {
                        // Pull to refresh
                        refreshID = UUID()
                    }
                }
            }
            .navigationTitle("My Adventures")
            .searchable(text: $searchText, prompt: "Search places")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPlace = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if !places.isEmpty {
                        EditButton()
                    }
                }
            }
            .sheet(isPresented: $showingAddPlace) {
                AddPlaceView()
            }
        }
    }

    private func deletePlaces(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredPlaces[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error deleting place: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct PlaceRowView: View {
    @ObservedObject var place: Place
    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 16) {
            // Gradient icon with shadow
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(categoryGradient)
                    .frame(width: 60, height: 60)
                    .shadow(
                        color: colorScheme == .dark ? Color.clear : categoryColor.opacity(0.4),
                        radius: 8,
                        x: 0,
                        y: 4
                    )

                Image(systemName: categoryIcon)
                    .foregroundColor(.white)
                    .font(.system(size: 24, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(place.name ?? "Unknown")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                if let description = place.placeDescription {
                    Text(description)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Tags row
                HStack(spacing: 8) {
                    // Category badge
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 10))
                        Text(place.category ?? "Other")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor.opacity(0.15))
                    .foregroundColor(categoryColor)
                    .cornerRadius(8)

                    if place.isVisited {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                            Text("Visited")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                    }

                    if place.isVisited, place.rating > 0 {
                        HStack(spacing: 2) {
                            ForEach(0..<Int(place.rating), id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.yellow)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.15))
                        .cornerRadius(8)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(
                    color: colorScheme == .dark ?
                        Color.white.opacity(isPressed ? 0.02 : 0.05) :
                        Color.black.opacity(isPressed ? 0.05 : 0.1),
                    radius: isPressed ? 4 : 8,
                    x: 0,
                    y: isPressed ? 2 : 4
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }

    private var categoryIcon: String {
        switch place.category {
        case "Beach": return "beach.umbrella.fill"
        case "Hike": return "figure.hiking"
        case "Activity": return "sportscourt.fill"
        case "Restaurant": return "fork.knife"
        default: return "mappin.circle.fill"
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

    private var categoryGradient: LinearGradient {
        CategoryGradient.forCategory(place.category ?? "Other")
    }
}

struct CategoryChip: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .semibold, design: .rounded))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            categoryGradient
                        } else {
                            LinearGradient(
                                colors: colorScheme == .dark ?
                                    [Color(.systemGray5), Color(.systemGray6)] :
                                    [Color(.systemGray6), Color(.systemGray5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                )
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .shadow(
                    color: isSelected && colorScheme == .light ? categoryColor.opacity(0.3) : Color.clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    private var categoryGradient: LinearGradient {
        switch title {
        case "Beach":
            return CategoryGradient.forCategory("Beach")
        case "Hike":
            return CategoryGradient.forCategory("Hike")
        case "Activity":
            return CategoryGradient.forCategory("Activity")
        case "Restaurant":
            return CategoryGradient.forCategory("Restaurant")
        case "Other":
            return CategoryGradient.forCategory("Other")
        default:
            return LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var categoryColor: Color {
        switch title {
        case "Beach": return Color(hex: "4A90E2")
        case "Hike": return Color(hex: "56AB2F")
        case "Activity": return Color(hex: "FF6B6B")
        case "Restaurant": return Color(hex: "E74C3C")
        case "Other": return Color(hex: "A855F7")
        default: return Color.accentColor
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .pulse()

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(message)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    PlaceListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
