import SwiftUI

struct ContentView: View {
    
    @State private var outputText: String = ""
    
    var body: some View {
        TabView {
                    Tab("Your Books", systemImage: "BookIcon") {
                //BookView()
                }
                    Tab("Your Reviews", systemImage: "BookIcon") {
                BookListView()
                }

                    Tab("Your Goals", systemImage: "ListIcon") {
                GoalsView()
                }

                    Tab("Profile", systemImage: "ProfileIcon") {
                ProfileView()
                }
    }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

