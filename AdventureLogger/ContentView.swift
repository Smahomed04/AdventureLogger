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
    @State private var showingAddPlace = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content area with bottom padding for tab bar
            Group {
                switch selectedTab {
                case 0:
                    PlaceListView()
                case 1:
                    PlacesMapView()
                case 2:
                    DiscoverView()
                case 3:
                    SettingsView()
                default:
                    PlaceListView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 60) // Tab bar height

            // Custom Tab Bar - Always visible at bottom
            VStack(spacing: 0) {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .sheet(isPresented: $showingAddPlace) {
            AddPlaceView()
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
