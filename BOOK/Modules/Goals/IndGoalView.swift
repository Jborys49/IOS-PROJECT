import SwiftUI

struct Book: Identifiable {
    let id = UUID() // To make it Identifiable for use in ForEach
    var title: String
    var isCompleted: Bool
}

struct IndGoalView: View {
    let directoryURL: URL

    @State private var books: [Book] = []
    @State private var image: Image? = nil
    @Environment(\.presentationMode) var presentationMode // To detect when the view is exited

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

            // Title for books
            Text("Books")
                .font(.headline)
                .padding(.top)

            // List of books with toggles
            List {
                ForEach($books) { $book in
                    HStack {
                        Text(book.title)
                        Spacer()
                        // Toggle to mark as completed or not
                        Toggle("", isOn: $book.isCompleted)
                            .labelsHidden()
                    }
                }
            }

            Spacer()

            // Completion Summary
            Text("Books Completed: \(completed)/\(books.count)")
                .font(.subheadline)
                .padding()
        }
        .onAppear(perform: loadData) // Load data when the view appears
        .onDisappear(perform: saveData) // Save data when the view is exited
        .padding()
    }

    // Load data from JSON and image
    func loadData() {
        let fm = FileManager.default
        let name = directoryURL.lastPathComponent

        // Load the image
        let imageFileURL = directoryURL.appendingPathComponent("\(name.lowercased()).png")
        image = fm.fileExists(atPath: imageFileURL.path) ? Image(uiImage: UIImage(contentsOfFile: imageFileURL.path) ?? UIImage()) : Image(systemName: "photo")

        // Load the JSON
        let descriptionFileURL = directoryURL.appendingPathComponent("\(name.lowercased())data.json")
        if let jsonData = fm.contents(atPath: descriptionFileURL.path) {
            let decoder = JSONDecoder()
            do {
                // Decode the JSON
                let decoded = try decoder.decode(ItemDescription.self, from: jsonData)
                completed = decoded.completed

                // Map JSON books to `Book` objects
                books = decoded.books.map { Book(title: $0.name, isCompleted: $0.status) }
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }
    }

    // Save updated data back to JSON
    func saveData() {
        let fm = FileManager.default
        let name = directoryURL.lastPathComponent
        let descriptionFileURL = directoryURL.appendingPathComponent("\(name.lowercased())data.json")

        // Update the JSON model with new data
        let updatedBooks = books.map { BookEntry(name: $0.title, status: $0.isCompleted) }
        let newDescription = ItemDescription( books: updatedBooks, startDate: Date(), endDate: Date()) // Update dates if necessary

        // Encode the updated JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        do {
            let jsonData = try encoder.encode(newDescription)
            try jsonData.write(to: descriptionFileURL)
        } catch {
            print("Error saving JSON: \(error)")
        }
    }

    // Recalculate the completion count dynamically
}