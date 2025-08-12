//
//  TableMakerPublishApp.swift
//  TableMakerPublish
//
//  Created by Austin Frankel on 5/23/25.
//

import SwiftUI
import UserNotifications

@main
struct TableMakerPublishApp: App {
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.showingTutorialInitially, !hasSeenTutorial)
                .onAppear {
                    // Reset tutorial state for testing (remove in production)
                    // UserDefaults.standard.set(false, forKey: "hasSeenTutorial")
                    NotificationService.shared.configureOnLaunch()
                }
        }
    }
}
