import SwiftUI
import AVKit

struct ContentView: View {
    @State private var showTabView = false // Controls when to show the TabView

    var body: some View {
        Group {
            if showTabView {
                TabView {
                    Tab("Your Books", systemImage: "book") {
                        TTSBooksView()
                    }
                    Tab("Your Reviews", systemImage: "bookmark") {
                        ReviewView()
                    }
                    Tab("Your Goals", systemImage: "checkmark.square") {
                        GoalsView()
                    }
                    Tab("Profile", systemImage: "person.circle") {
                        ProfileView()
                    }
                }
            } else {
                VideoPlayerView(videoName: "Intro", onVideoEnd: {
                    showTabView = true // Transition to TabView after video ends
                })
                .edgesIgnoringSafeArea(.all)
            }
        }
    }
}

struct VideoPlayerView: View {
    let videoName: String
    let onVideoEnd: () -> Void

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                player.play() // Automatically start playback when view appears
                setupVideoEndObserver()
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(self) // Cleanup observer
            }
    }

    private var player: AVPlayer {
        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
            fatalError("Video file \(videoName) not found")
        }
        return AVPlayer(url: url)
    }

    private func setupVideoEndObserver() {
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            onVideoEnd() // Trigger the closure when the video finishes
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

