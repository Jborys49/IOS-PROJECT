import SwiftUI

// Define the data model for the books inside the JSON
struct Book: Identifiable, Decodable {
    let id = UUID() // To make it Identifiable for use in ForEach
    let title: String
    let isCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case title = "key"
        case isCompleted = "value"
    }
}

struct IndGoalView: View {
    let directoryURL: URL

    @State private var books: [Book] = []
    @State private var image: Image? = nil

    var body: some View {
        VStack {
            // Display image if available
            if let image = image {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 350, height: 200)
                    .cornerRadius(10)
                    .padding()
            }

            // Title for notifications
            Text("Notifications")
                .font(.headline)
                .padding(.top)

            // List of books with checkboxes
            List(books) { book in
                HStack {
                    Text(book.title)
                    Spacer()
                    // Checkbox (Toggle) displaying completion status
                    Toggle("", isOn: .constant(book.isCompleted))
                        .labelsHidden()
                        .toggleStyle(CheckboxToggleStyle())
                }
            }

            Spacer()
        }
        .onAppear(perform: loadData) // Load data when the view appears
        .padding()
    }

    func loadData() {
        // Load the image
        let imageURL = directoryURL.appendingPathComponent("image.png") // Assume the image is named "image.png"
        if let uiImage = UIImage(contentsOfFile: imageURL.path) {
            image = Image(uiImage: uiImage)
        }

        // Load the JSON file
        let jsonURL = directoryURL.appendingPathComponent("books.json") // Assume the JSON file is named "books.json"
        if let data = try? Data(contentsOf: jsonURL) {
            let decoder = JSONDecoder()
            do {
                // Decode the JSON into the list of books
                let decodedBooks = try decoder.decode([Book].self, from: data)
                books = decodedBooks
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }
    }
}