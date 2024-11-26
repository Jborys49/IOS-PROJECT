import SwiftUI

struct DirectoryItem: Identifiable {
    let id = UUID()
    let name: String
    let image: Image
    let description: String
    let tags: [String]
}

struct BookListView: View {
    var body: some View {

        @State private var items: [DirectoryItem] = []

        VStack{
            ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(items) { item in
                    Button(action: {
                        print("Tapped on \(item.name)")
                    }) {
                        HStack {
                            // Image
                            item.image
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                            
                            // Text information
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.headline)
                                Text(item.description)
                                    .font(.subheadline)
                                    .lineLimit(2) // Limit to 2 lines
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                    }
                }
            }
            .padding()
        }
        .onAppear(perform: loadDirectoryItems)
        .navigationTitle("Dynamic List")
        }
        Spacer()
        //shuffling beetween views
        TabView {
            Tab("Your Books", systemImage: "BookIcon") {
        BookView()
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

    func loadDirectoryItems() {
        @State private var commons = Commons()
        do {
            // Get the list of directories in the base URL
            let directories = try commons.fm.contentsOfDirectory(at: Commons.ReadBooksURL, includingPropertiesForKeys: nil)
            
            // Iterate over each directory
            for directory in directories {
                if directory.hasDirectoryPath && directory!=".DS_Store" {
                    let name = directory.lastPathComponent
                    
                    // Load the image
                    let imageFileURL = directory.appendingPathComponent("\(name).png")
                    let image: Image = Commons.fm.fileExists(atPath: imageFileURL.path) ? Image(uiImage: UIImage(contentsOfFile: imageFileURL.path) ?? UIImage()) : Image(systemName: "photo")
                    
                    // Load the description
                    let descriptionFileURL = directory.appendingPathComponent("\(name)_data.json")
                    var description = "No description available"
                    if let jsonData = FileManager.default.contents(atPath: descriptionFileURL.path) {
                        if let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String] {
                            description = jsonObject["description"] ?? description
                            tags = jsonObject["tags"] ?? tags
                        }
                    }
                    
                    // Append to items
                    items.append(DirectoryItem(name: name, image: image, description: description))
                }
            }
        } catch {
            print("Error reading directory: \(error.localizedDescription)")
        }
    }
}

#Preview{
    GoalsView()
}
