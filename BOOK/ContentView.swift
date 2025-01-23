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
            TTSBooksView()
                .tabItem {
                    Label("Your Books", systemImage: "book")
                        .accessibilityIdentifier("TTS Tab")
                }
                            
            ReviewView()
                .tabItem {
                    Label("Your Reviews", systemImage: "bookmark")
                        .accessibilityIdentifier("Review Tab")
                }
                
            
            GoalsView()
                .tabItem {
                    Label("Your Goals", systemImage: "checkmark.square")
                        .accessibilityIdentifier("Goal Tab")
                }
                
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                        .accessibilityIdentifier("Profile Tab")
                }
                
        }
        .accentColor(.orange)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

