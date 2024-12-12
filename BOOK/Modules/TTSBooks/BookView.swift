import SwiftUI

struct BookItem: Identifiable {
    let id = UUID()
    let name: String
    let image: Image
    let description: String
    let url: URL
}

struct BooksView: View {
    @State var items: [BookItem] = []
    @State private var loaded = false

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(items) { item in
                            HStack {
                                NavigationLink(destination: BookDetailView(directoryURL: item.url)) {
                                    VStack(alignment: .leading) {
                                        // Image
                                        HStack {
                                            item.image
                                                .resizable()
                                                .scaledToFit()
                                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 100, maxHeight: 100)

                                            Spacer()
                                        }

                                        // Book Name
                                        Text(item.name)
                                            .font(.headline)

                                        // Description
                                        Text(item.description)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .frame(width: 260, height: 170)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .onAppear(perform: ensureLoadOnce)
                .navigationTitle("Your Books")
            }
            Spacer()
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

        guard let baseDataURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        let booksURL = baseDataURL.appendingPathComponent("TTSBooks") // Base directory for books

        do {
            // Get the list of directories in the base URL
            let directories = try fm.contentsOfDirectory(at: booksURL, includingPropertiesForKeys: nil)

            // Iterate over each directory
            for directory in directories {
                if directory.hasDirectoryPath && directory.lastPathComponent != ".DS_Store" {
                    let bookName = directory.lastPathComponent

                    // Load the image
                    let imageFileURL = directory.appendingPathComponent("cover.png")
                    let image: Image = fm.fileExists(atPath: imageFileURL.path) ? Image(uiImage: UIImage(contentsOfFile: imageFileURL.path) ?? UIImage()) : Image(systemName: "photo")

                    // Load the description
                    let descriptionFileURL = directory.appendingPathComponent("description.txt")
                    let description = (try? String(contentsOf: descriptionFileURL)) ?? "No description available"

                    // Append to items
                    items.append(BookItem(name: bookName, image: image, description: description, url: directory))
                }
            }
        } catch {
            print("Error reading directory: \(error.localizedDescription)")
        }
    }
}

struct BookDetailView: View {
    let directoryURL: URL

    var body: some View {
        VStack {
            Text("Book Directory: \(directoryURL.path)")
                .padding()
                .navigationTitle("Book Details")
        }
    }
}

#Preview {
    BooksView()
}
