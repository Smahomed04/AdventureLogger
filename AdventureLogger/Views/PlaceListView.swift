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
                    List {
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
                        }
                        .onDelete(perform: deletePlaces)
                    }
                    .listStyle(PlainListStyle())
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

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: categoryIcon)
                    .foregroundColor(categoryColor)
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(place.name ?? "Unknown")
                    .font(.headline)

                if let description = place.placeDescription {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    Label(place.category ?? "Other", systemImage: "tag.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if place.isVisited {
                        Label("Visited", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    if place.isVisited, place.rating > 0 {
                        HStack(spacing: 2) {
                            ForEach(0..<Int(place.rating), id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
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
        case "Beach": return .blue
        case "Hike": return .green
        case "Activity": return .orange
        case "Restaurant": return .red
        default: return .purple
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    PlaceListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
