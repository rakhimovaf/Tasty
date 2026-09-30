//
//  TastyApp.swift
//  Tasty
//
//  Created by FR. on 29/07/26.
//

import SwiftUI
import SwiftData
import RevenueCat

@main
struct TastyApp: App {

    @AppStorage("hasCompletedOnboarding")
    private var hasCompletedOnboarding = false

    @StateObject private var subscriptionManager = SubscriptionManager()

    init() {
        Purchases.logLevel = .debug
        Purchases.configure(
            withAPIKey: "test_YUOKDzTBUCmQRwvtvhljfbNsuGL"
        )
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [
                    modelConfiguration
                ]
            )
        } catch {
            fatalError(
                "Could not create ModelContainer: \(error)"
            )
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView {
                        hasCompletedOnboarding = true
                    }
                }
            }
            .environmentObject(subscriptionManager) 
        }
        .modelContainer(sharedModelContainer)
    }
}
