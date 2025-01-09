import SwiftUI
import Combine
import PDFKit
import Foundation


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
    
    //have to pass a function here so it will update the list
    func saveBook(_ book: BookAPI, onSuccess: @escaping (TTSBookItem) -> Void) {
        DispatchQueue.global(qos: .background).async {
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
                let metadata: [String: Any] = ["description": book.description, "pageNumber": 0]
                let metadataURL = bookDir.appendingPathComponent("\(book.title)_data.json")
                let metadataData = try JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted)
                try metadataData.write(to: metadataURL)
                
                // Save text content
                if let textData = try? Data(contentsOf: URL(string: book.textURL)!), let textString = String(data: textData, encoding: .utf8) {
                    let textURL = bookDir.appendingPathComponent("\(book.title).pdf")
                    createPDF(from: textString, to: textURL)
                }
                
                // Create the TTSBookItem to append
                let newItem = TTSBookItem(name: book.title, image: Image(uiImage: UIImage(data: try! Data(contentsOf: URL(string: book.coverURL)!)) ?? UIImage()), description: book.description, path: bookDir)
                
                // Call the onSuccess closure to append the book
                DispatchQueue.main.async {
                    onSuccess(newItem)
                }

                print("Book saved successfully!")
            } catch {
                print("Error saving book: \(error)")
            }
        }
    }
}

private func createPDF(from text: String, to url: URL) {

    let pageBounds = CGRect(x: 0, y: 0, width: 612, height: 792) // Standard US Letter size in points

    let textRect = pageBounds.insetBy(dx: 20, dy: 20)

    let textStorage = NSTextStorage(string: text)

    let textLayout = NSLayoutManager()

    let textContainer = NSTextContainer(size: textRect.size)



    textStorage.addLayoutManager(textLayout)

    textLayout.addTextContainer(textContainer)



    UIGraphicsBeginPDFContextToFile(url.path, pageBounds, nil)

    UIGraphicsBeginPDFPage()
    
    textLayout.drawGlyphs(forGlyphRange: NSRange(location: 0, length: textStorage.length), at: CGPoint(x: textRect.origin.x, y: textRect.origin.y))

    UIGraphicsEndPDFContext()

}
