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
    @State private var isVideoFinished = false
        WindowGroup {
            if isVideoFinished {
                        ContentView()
                    } else {
                        VideoPlayerView(isVideoFinished: $isVideoFinished)
                            .edgesIgnoringSafeArea(.all) // Ensure the video covers the whole screen
                    }
        }
    }
}

struct VideoPlayerView: UIViewControllerRepresentable {
    @Binding var isVideoFinished: Bool
    let player = AVPlayer(url: Bundle.main.url(forResource: "splash", withExtension: "mp4")!)

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            isVideoFinished = true
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if isVideoFinished {
            uiViewController.player?.pause()
        } else {
            uiViewController.player?.play()
        }
    }
}