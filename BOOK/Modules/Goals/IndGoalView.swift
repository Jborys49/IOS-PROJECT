import SwiftUI

// Define the data model for the books inside the JSON
struct Book: Identifiable {
    let id = UUID() // To make it Identifiable for use in ForEach
    let title: String
    let isCompleted: Bool
}
struct JSONobject:Decodable{
    let completed:Int
    let books:[String]
    let status:[Bool]
}
struct IndGoalView: View {
    let directoryURL: URL

    @State private var books: [Book] = []
    @State private var image: Image? = nil
    @State private var completed: Int? = 0
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
                        //.toggleStyle(CheckboxToggleStyle())
                }
            }

            Spacer()
        }
        .onAppear(perform: loadData) // Load data when the view appears
        .padding()
    }

    func loadData() {
            let fm = FileManager.default
            let name = directoryURL.lastPathComponent
            // Load the image
        let imageFileURL = directoryURL.appendingPathComponent("\(name.lowercased()).png")
            image = fm.fileExists(atPath: imageFileURL.path) ? Image(uiImage: UIImage(contentsOfFile: imageFileURL.path) ?? UIImage()) : Image(systemName: "photo")

            // Load the description
            
        let descriptionFileURL = directoryURL.appendingPathComponent("\(name.lowercased())data.json")
            //print(descriptionFileURL)
        var booksRead:[String] = []
        var completion:[Bool] = []
        if let jsonData = fm.contents(atPath: descriptionFileURL.path) {
                let decoder = JSONDecoder()
                do {
                    let decoded = try decoder.decode(JSONobject.self,from:  jsonData)
                    booksRead=decoded.books
                    completion=decoded.status
                    completed=decoded.completed
                }
                catch{print("\(error)")}
            }
            // Append to items
        for (bok,state) in zip(booksRead,completion) {
            books.append(Book(title: bok, isCompleted: state))
        }
        
        
    }
}
