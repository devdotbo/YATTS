//
//  YATTSApp.swift
//  YATTS
//
//  Created by Reza Shokri on 19.06.25.
//

import SwiftUI
import SwiftData

@main
struct YATTSApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AudioItem.self,
            Settings.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
