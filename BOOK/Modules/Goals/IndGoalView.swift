import SwiftUI

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
        // Same loading logic as original
    }

    func saveData() {
        // Save logic as original

        recalculateProgress()
    }

    func recalculateProgress() {
        let total = books.count
        let completed = books.filter { $0.isCompleted }.count
        let progress = total > 0 ? Double(completed) / Double(total) : 0.0
        updateProgress(directoryURL, progress)
    }
}