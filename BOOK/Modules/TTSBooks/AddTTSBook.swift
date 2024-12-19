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
        // Construct the Open Library API URL for the selected book
        let openLibraryURLString = "https://openlibrary.org/search.json?title=\(book.title)"
        guard let openLibraryURL = URL(string: openLibraryURLString) else {
            alertMessage = "Invalid URL."
            showAlert = true
            return
        }

        // Fetch book details from Open Library
        URLSession.shared.dataTask(with: openLibraryURL) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    alertMessage = "Error fetching book data."
                    showAlert = true
                }
                return
            }

            do {
                // Decode the response to get book's data
                let result = try JSONDecoder().decode(OpenLibraryResponse.self, from: data)
                if let firstDoc = result.docs.first, let coverID = firstDoc.cover_i {
                    // Construct the PDF download URL if available
                    let pdfURLString = "https://openlibrary.org/\(firstDoc.key)/fulltext"
                    guard let pdfURL = URL(string: pdfURLString) else {
                        DispatchQueue.main.async {
                            alertMessage = "No download link available for this book."
                            showAlert = true
                        }
                        return
                    }

                    // Proceed to download the PDF
                    downloadBookPDF(pdfURL: pdfURL, book: book)
                } else {
                    DispatchQueue.main.async {
                        alertMessage = "PDF not available for this book."
                        showAlert = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    alertMessage = "Error decoding Open Library data."
                    showAlert = true
                }
            }
        }.resume()
    }

    func downloadBookPDF(pdfURL: URL, book: BookTTS) {
        // Simulate downloading the PDF from the constructed URL
        let resourcesURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let bookDirectory = resourcesURL.appendingPathComponent("TTSBooks/\(book.title)")

        do {
            // Create the directory for the book if it doesn't exist
            try FileManager.default.createDirectory(at: bookDirectory, withIntermediateDirectories: true)

            // Download the PDF
            let pdfData = try Data(contentsOf: pdfURL)
            let pdfPath = bookDirectory.appendingPathComponent("\(book.title).pdf")
            try pdfData.write(to: pdfPath)

            // Optionally, download the cover image
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

            DispatchQueue.main.async {
                alertMessage = "Book downloaded successfully."
                showAlert = true
            }
        } catch {
            DispatchQueue.main.async {
                alertMessage = "Error downloading book: \(error.localizedDescription)"
                showAlert = true
            }
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
    let key: String  // This is used to construct the PDF URL for full text download
}

#Preview {
    APITESTView()
}