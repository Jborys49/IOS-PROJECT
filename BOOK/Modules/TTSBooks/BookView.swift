import SwiftUI

struct TTSBookItem: Identifiable {
    let id = UUID()
    let name: String
    let image: Image
    let description: String
    let path: URL
}

struct TTSBooksView: View {
    @State private var books: [TTSBookItem] = []
    @State private var loaded = false
    @State private var bookToDelete: TTSBookItem? = nil
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(books) { book in
                                HStack {
                                    NavigationLink(destination: IndTTSBook(bookPath: book.path)) {
                                        // Display cover image
                                        book.image
                                            .resizable()
                                            .frame(width: 50, height: 50)
                                            .clipShape(Circle())

                                        // Book details
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(book.name)
                                                .font(.headline)
                                            Text(book.description)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                                .lineLimit(2)
                                        }

                                        Spacer()
                                    }

                                    // Trash can button
                                    Button(action: {
                                        bookToDelete = book
                                        showDeleteConfirmation = true
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                            .font(.title2)
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                            }
                        }
                        .padding()
                    }
                    .onAppear(perform: ensureLoadOnce)
                }

                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        NavigationLink(destination: AddTTSBook(books: $books)) {
                            Image(systemName: "plus")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("TTS Books")
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Book"),
                    message: Text("Are you sure you want to delete \(bookToDelete?.name ?? "this book")?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let book = bookToDelete {
                            deleteBook(book)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    func ensureLoadOnce() {
        if !loaded {
            loadBooks()
            loaded = true
        }
    }

    func loadBooks() {
        let fm = FileManager.default

        guard let baseDirectory = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        let ttsBooksDirectory = baseDirectory.appendingPathComponent("BookKeepTTSBooks")

        do {
            let directories = try fm.contentsOfDirectory(at: ttsBooksDirectory, includingPropertiesForKeys: nil)
            for directory in directories {
                if directory.hasDirectoryPath && directory.lastPathComponent != ".DS_Store" {
                    let bookName = directory.lastPathComponent

                    // Load the book cover image
                    let coverPath = directory.appendingPathComponent("\(bookName).jpg")
                    let coverImage: Image = fm.fileExists(atPath: coverPath.path) ? Image(uiImage: UIImage(contentsOfFile: coverPath.path) ?? UIImage()) : Image(systemName: "book")

                    // Load the description from JSON
                    let dataFilePath = directory.appendingPathComponent("\(bookName)_data.json")
                    var bookDescription = "No description available"
                    if let jsonData = fm.contents(atPath: dataFilePath.path) {
                        do {
                            let decodedData = try JSONDecoder().decode(BookData.self, from: jsonData)
                            bookDescription = decodedData.description
                        } catch {
                            print("Error decoding JSON for \(bookName): \(error.localizedDescription)")
                        }
                    }

                    // Add to books array
                    books.append(TTSBookItem(name: bookName, image: coverImage, description: bookDescription, path: directory))
                }
            }
        } catch {
            print("Error reading TTSBooks directory: \(error.localizedDescription)")
        }
    }

    func deleteBook(_ book: TTSBookItem) {
        let fm = FileManager.default

        do {
            // Delete the directory
            try fm.removeItem(at: book.path)
            // Remove from the books array
            books.removeAll { $0.id == book.id }
        } catch {
            print("Error deleting book \(book.name): \(error.localizedDescription)")
        }
    }
}

struct BookData: Codable {
    let description: String
    let pageNumber: Int
}

#Preview {
    TTSBooksView()
}
