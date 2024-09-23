//
//  WakeyApp.swift
//  Wakey
//
//  Created by Pratik Ray on 22/09/24.
//

import SwiftUI
@main
struct ScreenAwakeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
