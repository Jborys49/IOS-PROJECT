import SwiftUI

struct Book: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let coverURL: URL?
}

struct APITESTView: View {
    @State private var searchQuery: String = ""
    @State private var books: [Book] = []
    @State private var isLoading: Bool = false

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
                                BookRow(book: book)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Your Books")
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
                        Book(
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
}

struct BookRow: View {
    let book: Book

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
