//
//  TripsView.swift
//  AdventureLogger
//

import SwiftUI
import CoreData

struct TripsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Trip.startDate, ascending: false)],
        animation: .default)
    private var trips: FetchedResults<Trip>

    @State private var showingAddTrip = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if trips.isEmpty {
                    EmptyTripsView {
                        showingAddTrip = true
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(trips, id: \.id) { trip in
                                NavigationLink(destination: TripDetailView(trip: trip)) {
                                    TripCardView(trip: trip)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Trips")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTrip = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTrip) {
                AddTripView()
            }
        }
    }
}

struct TripCardView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var trip: Trip

    var placeCount: Int {
        (trip.places as? Set<Place>)?.count ?? 0
    }

    var visitedCount: Int {
        (trip.places as? Set<Place>)?.filter { $0.isVisited }.count ?? 0
    }

    var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        if let start = trip.startDate, let end = trip.endDate {
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        } else if let start = trip.startDate {
            return formatter.string(from: start)
        }
        return "No dates set"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with gradient
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [
                        Color(hex: "667eea"),
                        Color(hex: "764ba2")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 140)
                .overlay(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(trip.name ?? "Untitled Trip")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)

                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        Text(dateRangeText)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.9))
                }
                .padding(16)
            }

            // Stats section
            HStack(spacing: 0) {
                StatBox(
                    icon: "mappin.and.ellipse",
                    value: "\(placeCount)",
                    label: "Places",
                    color: Color(hex: "4ECDC4")
                )

                Divider()
                    .frame(height: 40)

                StatBox(
                    icon: "checkmark.circle.fill",
                    value: "\(visitedCount)",
                    label: "Visited",
                    color: Color.green
                )

                Divider()
                    .frame(height: 40)

                StatBox(
                    icon: "heart.fill",
                    value: "\(placeCount - visitedCount)",
                    label: "To Visit",
                    color: Color(hex: "FF6B6B")
                )
            }
            .padding(.vertical, 16)
            .background(Color.cardBackground)

            // Description if available
            if let description = trip.tripDescription, !description.isEmpty {
                Text(description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .background(Color.cardBackground)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(
            color: colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.1),
            radius: 10,
            x: 0,
            y: 5
        )
    }
}

struct StatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct EmptyTripsView: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "667eea").opacity(0.2), Color(hex: "764ba2").opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "airplane.departure")
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .pulse()

            VStack(spacing: 12) {
                Text("No Trips Yet")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Create a trip to organize your adventures into meaningful memories")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button(action: onCreate) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Your First Trip")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(25)
                }
                .padding(.top, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    TripsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
