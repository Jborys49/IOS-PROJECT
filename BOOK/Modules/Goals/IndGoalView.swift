import SwiftUI
struct Book: Identifiable {
    let id = UUID() // To make it Identifiable for use in ForEach
    var title: String
    var isCompleted: Bool
}

struct IndGoalView: View {
    let directoryURL: URL
    let updateProgress: (URL, Double) -> Void // Callback to update progress in parent

    @State private var books: [Book] = []
    @State private var image: Image? = nil

    var body: some View {
        VStack {
            if let image = image {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 350, height: 200)
                    .cornerRadius(10)
                    .padding()
            }

            Text("Books")
                .font(.headline)
                .padding(.top)

            List {
                ForEach($books) { $book in
                    HStack {
                        Text(book.title)
                        Spacer()
                        Toggle("", isOn: $book.isCompleted)
                            .labelsHidden()
                            .onChange(of: book.isCompleted) { _ in
                                recalculateProgress()
                            }
                    }
                }
            }

            Spacer()
        }
        .onAppear(perform: loadData)
        .onDisappear(perform: saveData)
        .padding()
    }

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

                    decoder.dateDecodingStrategy = .iso8601

                    do {

                        // Decode the JSON

                        let decoded = try decoder.decode(ItemDescription.self, from: jsonData)

                        print("before")

                        // Map JSON books to Book objects

                        books = decoded.books.map { Book(title: $0.name, isCompleted: $0.status) }

                    } catch {

                        print("Error decoding JSON: \(error)")

                    }

                }
    }

    func saveData() {
        //let fm = FileManager.default

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

        recalculateProgress()
    }

    func recalculateProgress() {
        let total = books.count
        let completed = books.filter { $0.isCompleted }.count
        let progress = total > 0 ? Double(completed) / Double(total) : 0.0
        updateProgress(directoryURL, progress)
    }
}
