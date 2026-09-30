//
//  ContentView.swift
//  Tasty
//
//  Created by FR. on 29/07/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @AppStorage("selectedTab") private var selectedTab = 0
    @State private var showOnboarding = true
    @State private var showSheet = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "book", value: 0) {
                HomeView()
            }

            Tab("AI assitent", systemImage: "sparkles", value: 1) {
                AIAssistantView()
            }

            Tab("Settings", systemImage: "gear", value: 2) {
                SettingsView()
            }

            if #available(iOS 27.0, *) {
                Tab(value: 3, role: .prominent) {
                    SheetView()
                } label: {
                    Image(systemName: "pencil.and.scribble")
                }
            } else {
                Tab(value: 3, role: .search) {
                    SheetView()
                } label: {
                    Image(systemName: "pencil.and.scribble")
                }
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == 3 {
                showSheet = true
                selectedTab = oldValue

            }
        }
        .sheet(isPresented: $showSheet) {
            SheetView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
        .environmentObject(SubscriptionManager())
}
