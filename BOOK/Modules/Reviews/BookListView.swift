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

struct ReviewView: View {
    @State var items: [DirectoryItem] = []
    @State private var loaded = false
    @State private var showAlert = false
    @State private var itemToDelete: DirectoryItem? = nil
    //Filter vars
    @State private var searchText: String = ""
    @State private var activeFilters: [String] = []

    var body: some View {
        NavigationView {
            ZStack {
                // List of Reviews
                VStack {
                    // Search Bar
                    HStack {
                        TextField("Search...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)

                        Button(action: {
                            addFilter()
                        }) {
                            Image(systemName: "plus")
                                .padding(10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        .padding(.trailing)
                    }
                    .padding(.top)

                    // Active Filters
                    if !activeFilters.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(activeFilters, id: \.self) { filter in
                                    HStack {
                                        Text(filter)
                                            .padding(8)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(8)

                                        Button(action: {
                                            removeFilter(filter)
                                        }) {
                                            Image(systemName: "xmark.circle")
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(filteredItems) { item in
                                HStack {
                                    NavigationLink(destination: IndReviewView(
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
                    .navigationTitle("Your Reviews")
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
                        .accessibilityIdentifier("Review Add Link")
                        Spacer()
                    }
                }
            }
        }
    }

    var filteredItems: [DirectoryItem] {
        if activeFilters.isEmpty {
            return items
        } else {
            return items.filter { item in
                activeFilters.allSatisfy { filter in
                    item.name.localizedCaseInsensitiveContains(filter) ||
                    item.tags.contains { $0.localizedCaseInsensitiveContains(filter) }
                }
            }
        }
    }

    func addFilter() {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty && !activeFilters.contains(trimmedText) {
            activeFilters.append(trimmedText)
        }
        searchText = ""
    }

    func removeFilter(_ filter: String) {
        activeFilters.removeAll { $0 == filter }
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
        let ReadBooksURL = BaseDataURL.appendingPathComponent("BookKeepReviews")

        do {
            let directories = try fm.contentsOfDirectory(at: ReadBooksURL, includingPropertiesForKeys: nil)
            for directory in directories {
                if directory.hasDirectoryPath && directory.lastPathComponent != ".DS_Store" {
                    let name = directory.lastPathComponent

                    // Load the image
                    let imageFileURL = directory.appendingPathComponent("\(name).png")
                    let image: Image = fm.fileExists(atPath: imageFileURL.path) ? Image(uiImage: UIImage(contentsOfFile: imageFileURL.path) ?? UIImage()) : Image(systemName: "photo")

                    // Load the description
                    let nameL = name.lowercased()
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
        let ReadBooksURL = BaseDataURL.appendingPathComponent("BookKeepReviews")
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
    ReviewView()
}
