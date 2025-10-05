//
//  ContentView.swift
//  AdventureLogger
//
//  Created by Sa'd Mahomed on 3/10/2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            PlaceListView()
                .tabItem {
                    Label("Adventures", systemImage: selectedTab == 0 ? "list.bullet.circle.fill" : "list.bullet.circle")
                }
                .tag(0)

            TripsView()
                .tabItem {
                    Label("Trips", systemImage: selectedTab == 1 ? "airplane.departure.fill" : "airplane.departure")
                }
                .tag(1)

            PlacesMapView()
                .tabItem {
                    Label("Map", systemImage: selectedTab == 2 ? "map.fill" : "map")
                }
                .tag(2)

            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: selectedTab == 3 ? "sparkle.magnifyingglass" : "magnifyingglass")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: selectedTab == 4 ? "gearshape.fill" : "gearshape")
                }
                .tag(4)
        }
        .accentColor(Color(hex: "FF6B6B"))
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
