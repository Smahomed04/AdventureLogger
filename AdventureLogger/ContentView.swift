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
                    Label("Adventures", systemImage: "list.bullet")
                }
                .tag(0)

            PlacesMapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(1)

            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
