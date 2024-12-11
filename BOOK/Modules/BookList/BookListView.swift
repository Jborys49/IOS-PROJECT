import SwiftUI

struct DirectoryItem: Identifiable {
    let id = UUID()
    let name: String
    let image: Image
    let description: String
    let tags: [String]
}

struct GoalDescription: Decodable,Encodable {
    var description: String
    var tags: [String]
}

struct BookListView: View {
    @State var items: [DirectoryItem] = []
    @State private var loaded = false
    @State private var showAlert = false
    @State private var itemToDelete: DirectoryItem? = nil

    var body: some View {
        NavigationView {
            ZStack {
                // Main Content
                VStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(items) { item in
                                HStack {
                                    NavigationLink(destination: ReviewView(
                                        image: item.image,
                                        description: item.description,
                                        tags: item.tags
                                    )) {
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
                                                    .lineLimit(2)
                                                    .foregroundColor(.gray)
                                            }
                                            Spacer()
                                            // Delete Button
                                            Button(action: {
                                                itemToDelete = item
                                                showAlert = true
                                            }) {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                                    .padding()
                                            }
                                        }
                                        .padding()
                                        .frame(width: 400,height: 80)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                    }
                    .onAppear(perform: ensureLoadOnce)
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("Are you sure?"),
                            message: Text("This action will delete the selected item."),
                            primaryButton: .destructive(Text("Delete")) {
                                if let item = itemToDelete {
                                    deleteItem(item: item)
                                }
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    .navigationTitle("Saved Reviews")
                }

                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        NavigationLink(destination: AddReview(items:$items)) {
                            Image(systemName: "plus")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding()
                        Spacer()
                    }
                }
            }
        }
    }

    func ensureLoadOnce() {
        if !loaded {
            loadDirectoryItems()
            loaded = true
        }
    }

    func loadDirectoryItems() {
        let fm = FileManager.default

        guard let BaseDataURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        let ReadBooksURL = BaseDataURL.appendingPathComponent("ReadBooks")

        do {
            let directories = try fm.contentsOfDirectory(at: ReadBooksURL, includingPropertiesForKeys: nil)
            for directory in directories {
                if directory.hasDirectoryPath && directory.lastPathComponent != ".DS_Store" {
                    let name = directory.lastPathComponent

                    // Load the image
                    let imageFileURL = directory.appendingPathComponent("\(name).png")
                    let image: Image = fm.fileExists(atPath: imageFileURL.path) ? Image(uiImage: UIImage(contentsOfFile: imageFileURL.path) ?? UIImage()) : Image(systemName: "photo")

                    // Load the description
                    var nameL = name.lowercased()
                    let descriptionFileURL = directory.appendingPathComponent("\(nameL)_data.json")
                    var description = "No description available"
                    var tags: [String] = []
                    if let jsonData = FileManager.default.contents(atPath: descriptionFileURL.path) {
                        let decoder = JSONDecoder()
                        do {
                            let decoded = try decoder.decode(GoalDescription.self, from: jsonData)
                            description = decoded.description
                            tags = decoded.tags
                        } catch {
                            print("\(error)")
                        }
                    }

                    // Append to items
                    items.append(DirectoryItem(name: name, image: image, description: description, tags: tags))
                }
            }
        } catch {
            print("Error reading directory: \(error.localizedDescription)")
        }
    }

    func deleteItem(item: DirectoryItem) {
        let fm = FileManager.default

        guard let BaseDataURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        let ReadBooksURL = BaseDataURL.appendingPathComponent("ReadBooks")
        print(ReadBooksURL)
        let directoryToDelete = ReadBooksURL.appendingPathComponent(item.name)

        do {
            print(directoryToDelete)
            try fm.removeItem(at: directoryToDelete)
            items.removeAll { $0.id == item.id } // Remove item from state
        } catch {
            print("Error deleting item: \(error)")
        }
    }
}



#Preview {
    BookListView()
}
