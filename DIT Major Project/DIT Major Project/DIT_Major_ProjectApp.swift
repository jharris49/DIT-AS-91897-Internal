//
//  DIT_Major_ProjectApp.swift
//  DIT Major Project
//
//  Created by Josh Harris on 03/06/2025.
//

import SwiftUI

@main
struct DIT_Major_ProjectApp: App {
    let persistenceController = PersistenceController.shared
    @AppStorage("darkMode") var darkMode = false
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(darkMode ? .dark : .light)
        }
    }
}
