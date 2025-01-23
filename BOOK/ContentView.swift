import SwiftUI
import AVKit

struct ContentView: View {
    init(){
        let appearence = UITabBarAppearance()
        appearence.configureWithOpaqueBackground()
        appearence.backgroundColor = UIColor.systemGreen
        
        UITabBar.appearance().standardAppearance = appearence
        UITabBar.appearance().scrollEdgeAppearance = appearence
        UITabBar.appearance().unselectedItemTintColor = .white
        //UITabBar.appearance().tintColor = UIColor.white
    }
    var body: some View {
        TabView {
            Tab("Your Books", systemImage: "book") {
                TTSBooksView()
            }
            .accessibilityIdentifier("TTS Tab")
            Tab("Your Reviews", systemImage: "bookmark") {
                ReviewView()
            }
            .accessibilityIdentifier("Review Tab")
            Tab("Your Goals", systemImage: "checkmark.square") {
                GoalsView()
            }
            .accessibilityIdentifier("Goals Tab")
            Tab("Profile", systemImage: "person.circle") {
                ProfileView()
            }
            .accessibilityIdentifier("Profile Tab")
        }
        .accentColor(.orange)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

