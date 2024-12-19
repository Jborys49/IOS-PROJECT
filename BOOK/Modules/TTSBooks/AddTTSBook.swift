import SwiftUI
import Foundation

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
        // Show an alert indicating switching to Gutenberg
        DispatchQueue.main.async {
            alertMessage = "Fetching PDF from Gutenberg..."
            showAlert = true
        }

        fetchAndDownloadFromGutenberg(bookTitle: book.title, book: book)
    }

    func fetchAndDownloadFromGutenberg(bookTitle: String, book: BookTTS) {
        let gutenbergSearchURLString = "https://gutendex.com/books/?search=\(bookTitle)"
        guard let gutenbergSearchURL = URL(string: gutenbergSearchURLString) else {
            alertMessage = "Invalid URL for Gutenberg."
            showAlert = true
            return
        }

        URLSession.shared.dataTask(with: gutenbergSearchURL) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    alertMessage = "Error fetching Gutenberg book data."
                    showAlert = true
                }
                return
            }

            do {
                let result = try JSONDecoder().decode(GutenbergResponse.self, from: data)
                if let firstBook = result.results.first, let pdfDownloadURLString = firstBook.formats["application/pdf"] {
                    guard let pdfDownloadURL = URL(string: pdfDownloadURLString) else {
                        DispatchQueue.main.async {
                            alertMessage = "Invalid PDF download link for this book."
                            showAlert = true
                        }
                        return
                    }

                    // Proceed to download the PDF
                    downloadPDF(downloadURL: pdfDownloadURL, book: book)
                } else {
                    DispatchQueue.main.async {
                        alertMessage = "No PDF available for this book."
                        showAlert = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    alertMessage = "Error decoding Gutenberg data."
                    showAlert = true
                }
            }
        }.resume()
    }

    func downloadPDF(downloadURL: URL, book: BookTTS) {
        let resourcesURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let bookDirectory = resourcesURL.appendingPathComponent("TTSBooks/\(book.title)")

        do {
            // Create the directory for the book if it doesn't exist
            try FileManager.default.createDirectory(at: bookDirectory, withIntermediateDirectories: true)

            // Download the PDF
            let pdfData = try Data(contentsOf: downloadURL)
            let pdfPath = bookDirectory.appendingPathComponent("\(book.title).pdf")
            try pdfData.write(to: pdfPath)

            DispatchQueue.main.async {
                alertMessage = "PDF downloaded successfully."
                showAlert = true
            }
        } catch {
            DispatchQueue.main.async {
                alertMessage = "Error downloading PDF: \(error.localizedDescription)"
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
}

struct GutenbergResponse: Decodable {
    let results: [GutenbergBook]
}

struct GutenbergBook: Decodable {
    let title: String
    let formats: [String: String]
}

#Preview {
    APITESTView()
}