import SwiftUI
import AVKit

struct IntroVideoView: View {
    @Binding var isVideoFinished: Bool

    var body: some View {
        VideoPlayerView(videoName: "Intro", isFinished: $isVideoFinished)
            .edgesIgnoringSafeArea(.all) // Optional: Fullscreen video
    }
}

struct VideoPlayerView: UIViewControllerRepresentable {
    let videoName: String
    @Binding var isFinished: Bool

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        if let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") {
            let player = AVPlayer(url: url)
            controller.player = player

            // Add an observer for when the video ends
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { _ in
                isFinished = true
            }

            player.play()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}