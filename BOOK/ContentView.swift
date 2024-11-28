import SwiftUI

struct ContentView: View {
    
    @State private var outputText: String = ""
    
    var body: some View {
        TabView {
                    Tab("Your Books", systemImage: "book") {
                //BookView()
                }
                    Tab("Your Reviews", systemImage: "bookmark") {
                BookListView()
                }

                    Tab("Your Goals", systemImage: "checkmark.square") {
                GoalsView()
                }

                    Tab("Profile", systemImage: "person.circle") {
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

