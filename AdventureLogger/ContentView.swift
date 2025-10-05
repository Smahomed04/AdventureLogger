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

            PlacesMapView()
                .tabItem {
                    Label("Map", systemImage: selectedTab == 1 ? "map.fill" : "map")
                }
                .tag(1)

            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: selectedTab == 2 ? "sparkle.magnifyingglass" : "magnifyingglass")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                }
                .tag(3)
        }
        .accentColor(Color(hex: "FF6B6B"))
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
