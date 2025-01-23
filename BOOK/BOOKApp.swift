//
//  BOOKApp.swift
//  BOOK
//
//  Created by IOSLAB on 14/11/2024.
//

import SwiftUI

@main
struct BOOKApp: App {
    @State private var isVideoFinished = false

    init() {
        // Trigger the file setup process
        AppFileManager.shared.setupDirectoriesAndFiles()

        #if DEBUG
        if CommandLine.arguments.contains("ui-testing") {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            print("DOCUMENTS_DIRECTORY: \(documentsURL.path)")
        }
        #endif
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
            //if isVideoFinished {
            //    ContentView()
            //} else {
            //    IntroVideoView(isVideoFinished: $isVideoFinished)
            //}
        }
    }
}
