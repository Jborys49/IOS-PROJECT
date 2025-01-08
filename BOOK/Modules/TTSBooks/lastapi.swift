import SwiftUI
import Combine
import PDFKit

struct BookAPI: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let coverURL: String
    let textURL: String
    let description: String
}

class BookViewModel: ObservableObject {
    @Published var books: [BookAPI] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false

    func searchBooks() {
        guard !searchText.isEmpty else { return }
        isLoading = true

        let query = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://gutendex.com/books/?search=\(query)"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }

            guard let data = data, error == nil else { return }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let results = json["results"] as? [[String: Any]] {

                    let books: [BookAPI] = results.compactMap { result in
                        guard let title = result["title"] as? String,
                              let authors = result["authors"] as? [[String: Any]],
                              let authorName = authors.first?["name"] as? String,
                              let formats = result["formats"] as? [String: String],
                              let textURL = formats["text/plain"] ?? formats["text/plain; charset=utf-8"],
                              let coverURL = formats["image/jpeg"] else {
                            return nil
                        }

                        return BookAPI(
                            title: title,
                            author: authorName,
                            coverURL: coverURL,
                            textURL: textURL,
                            description: "Author: \(authorName)"
                        )
                    }

                    DispatchQueue.main.async {
                        self.books = books
                    }
                }
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }.resume()
    }

    func saveBook(_ book: BookAPI) {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let bookDir = documentsURL.appendingPathComponent("BookKeepTTSBooks/\(book.title)", isDirectory: true)

        do {
            try fileManager.createDirectory(at: bookDir, withIntermediateDirectories: true, attributes: nil)

            // Save cover image
            if let coverData = try? Data(contentsOf: URL(string: book.coverURL)!) {
                let coverURL = bookDir.appendingPathComponent("\(book.title).png")
                try coverData.write(to: coverURL)
            }

            // Save metadata
            let metadata: [String: Any] = ["description": book.description, "pagenumber": 0]
            print(book.description)
            let metadataURL = bookDir.appendingPathComponent("\(book.title)_data.json")
            let metadataData = try JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted)
            try metadataData.write(to: metadataURL)

            // Save text content
            if let textData = try? Data(contentsOf: URL(string: book.textURL)!) {
                print(book.textURL)
                let textURL = bookDir.appendingPathComponent("\(book.title).pdf")
                createPDF(from: textData, to: textURL)
            }

            print("Book saved successfully!")
        } catch {
            print("Error saving book: \(error)")
        }
    }
}

private func createPDF(from text: String, to url: URL) {
    let pdfDocument = PDFDocument()
    let pdfPage = PDFPage()

    // Create a text content for the PDF
    let pageBounds = CGRect(x: 0, y: 0, width: 612, height: 792) // Standard US Letter size in points
    let textRect = pageBounds.insetBy(dx: 50, dy: 50) // Add some padding
    let textStorage = NSTextStorage(string: text)
    let textLayout = NSLayoutManager()
    let textContainer = NSTextContainer(size: textRect.size)

    textStorage.addLayoutManager(textLayout)
    textLayout.addTextContainer(textContainer)

    UIGraphicsBeginPDFContextToFile(url.path, pageBounds, nil)
    UIGraphicsBeginPDFPage()

    let currentContext = UIGraphicsGetCurrentContext()
    currentContext?.translateBy(x: 0, y: pageBounds.height)
    currentContext?.scaleBy(x: 1.0, y: -1.0)

    textLayout.drawGlyphs(forGlyphRange: NSRange(location: 0, length: textStorage.length), at: CGPoint(x: textRect.origin.x, y: textRect.origin.y))

    UIGraphicsEndPDFContext()
}

struct lastapiView: View {
    @StateObject private var viewModel = BookViewModel()

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search books", text: $viewModel.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button(action: {
                        viewModel.searchBooks()
                    }) {
                        Text("Search")
                    }
                    .padding()
                }

                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack {
                            ForEach(viewModel.books) { book in
                                HStack {
                                    AsyncImage(url: URL(string: book.coverURL)) { image in
                                        image.resizable()
                                    } placeholder: {
                                        Color.gray
                                    }
                                    .frame(width: 60, height: 80)
                                    .cornerRadius(8)

                                    VStack(alignment: .leading) {
                                        Text(book.title)
                                            .font(.headline)

                                        Text(book.description)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()
                                }
                                .padding()
                                .onTapGesture {
                                    viewModel.saveBook(book)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Books Read")
        }
    }
}

#Preview {
    lastapiView()
}
