import SwiftUI

struct BookTTS: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let coverURL: URL?
}

struct APITESTView: View {
    @State private var searchQuery: String = ""
    @State private var books: [BookTTS] = []
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    TextField("Search for a book", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button(action: searchBooks) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .padding()
                    }
                }

                // Display Results
                if isLoading {
                    ProgressView()
                        .padding()
                } else if books.isEmpty && !searchQuery.isEmpty {
                    Text("No results found.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(books) { book in
                                Button(action: {
                                    handleBookSelection(book: book)
                                }) {
                                    BookRow(book: book)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Your Books")
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    func searchBooks() {
        guard !searchQuery.isEmpty else { return }

        isLoading = true
        books.removeAll()

        let query = searchQuery.replacingOccurrences(of: " ", with: "+")
        let urlString = "https://openlibrary.org/search.json?title=\(query)"

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { isLoading = false }

            guard let data = data, error == nil else {
                print("Error fetching data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            do {
                let result = try JSONDecoder().decode(OpenLibraryResponse.self, from: data)
                DispatchQueue.main.async {
                    books = result.docs.map {
                        BookTTS(
                            title: $0.title,
                            author: $0.author_name?.first ?? "Unknown Author",
                            coverURL: $0.cover_i != nil ? URL(string: "https://covers.openlibrary.org/b/id/\($0.cover_i!)-M.jpg") : nil
                        )
                    }
                }
            } catch {
                print("Error decoding data: \(error)")
            }
        }.resume()
    }

    func handleBookSelection(book: BookTTS) {
        // Simulate checking the availability of the book and saving files
        guard let pdfURL = URL(string: "https://example.com/\(book.title).pdf"), // Simulate a URL for the book's PDF
              FileManager.default.fileExists(atPath: pdfURL.path) else {
            alertMessage = "Could not download book."
            showAlert = true
            return
        }

        do {
            let resourcesURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let bookDirectory = resourcesURL.appendingPathComponent("TTSBooks/\(book.title)")

            // Create the directory for the book
            try FileManager.default.createDirectory(at: bookDirectory, withIntermediateDirectories: true)

            // Save the cover image if available
            if let coverURL = book.coverURL, let coverData = try? Data(contentsOf: coverURL) {
                let coverPath = bookDirectory.appendingPathComponent("\(book.title).jpg")
                try coverData.write(to: coverPath)
            }

            // Save the book's metadata as JSON
            let metadata = [
                "description": book.author,
                "pageNumber": 0
            ] as [String: Any]
            let metadataPath = bookDirectory.appendingPathComponent("\(book.title)_data.json")
            let metadataData = try JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted)
            try metadataData.write(to: metadataPath)

            // Save the book's PDF
            let pdfPath = bookDirectory.appendingPathComponent("\(book.title).pdf")
            let pdfData = try Data(contentsOf: pdfURL)
            try pdfData.write(to: pdfPath)

            alertMessage = "Book downloaded."
            showAlert = true
        } catch {
            print("Error saving book: \(error)")
            alertMessage = "Could not download book."
            showAlert = true
        }
    }
}

struct BookRow: View {
    let book: BookTTS

    var body: some View {
        HStack {
            if let coverURL = book.coverURL {
                AsyncImage(url: coverURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 60, height: 60)
                    case .success(let image):
                        image
                            .resizable()
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                    case .failure:
                        Image(systemName: "book")
                            .frame(width: 60, height: 60)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "book")
                    .frame(width: 60, height: 60)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

struct OpenLibraryResponse: Decodable {
    let docs: [BookDoc]
}

struct BookDoc: Decodable {
    let title: String
    let author_name: [String]?
    let cover_i: Int?
}

#Preview {
    APITESTView()
}