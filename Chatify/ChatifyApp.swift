//
//  ChatifyApp.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-08-20.
//

import SwiftUI

@main
struct ChatifyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
