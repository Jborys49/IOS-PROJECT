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
                VideoPlayerView(videoName: "intro", onVideoEnd: {
                    showTabView = true // Show the TabView after the video finishes
                })
                .edgesIgnoringSafeArea(.all)
            }
        }
    }
}

// VideoPlayerView to play the intro video
struct VideoPlayerView: View {
    let videoName: String
    let onVideoEnd: () -> Void

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                player.play()
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: player.currentItem,
                    queue: .main
                ) { _ in
                    onVideoEnd()
                }
            }
    }

    private var player: AVPlayer {
        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
            fatalError("Video file \(videoName) not found")
        }
        return AVPlayer(url: url)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

