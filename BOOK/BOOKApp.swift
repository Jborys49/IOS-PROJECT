//
//  BOOKApp.swift
//  BOOK
//
//  Created by IOSLAB on 14/11/2024.
//

import SwiftUI

@main
struct BOOKApp: App {
    init() {
        // Trigger the file setup process
        AppFileManager.shared.setupDirectoriesAndFiles()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
