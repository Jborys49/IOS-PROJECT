import SwiftUI

struct AddGoalView: View {
    @Environment(\.presentationMode) var presentationMode // To dismiss the view

    @State private var goalName: String = ""
    @State private var goalEndDate: Date = Date()
    @State private var books: [String] = [] // List of books
    @State private var newBook: String = "" // Text for new book input
    @State private var goalImage: UIImage? = nil // Goal image
    @State private var showImagePicker = false // To show the image picker

    var body: some View {
        VStack(spacing: 16)
        {
            // Upload Picture Section
            Button(action: { showImagePicker = true }) {
                if let image = goalImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                } else {
                    VStack {
                        Image(systemName: "arrow.up.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Upload picture here")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    .frame(width: 150, height: 150)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $goalImage)
            }

            // Goal Name TextField
            TextField("Enter goal name", text: $goalName)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

            // Calendar to select the goal end date
            DatePicker("Select goal deadline", selection: $goalEndDate, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()

            // Add Books Section
            HStack {
                TextField("Add a book", text: $newBook)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)

                Button(action: {
                    if !newBook.isEmpty {
                        books.append(newBook)
                        newBook = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                }
            }

            // Display list of books
            List {
                ForEach(books, id: \"\".self) { book in
                    HStack {
                        Text(book)
                        Spacer()
                        Button(action: {
                            if let index = books.firstIndex(of: book) {
                                books.remove(at: index)
                            }
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }

            Spacer()

            // Save Button
            Button(action: saveGoal) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
            }
        }
        .padding()
        .navigationTitle("Add Goal")
    }

    // Save goal data
    func saveGoal() {
        guard !goalName.isEmpty else { return } // Ensure goal name is not empty

        let fileManager = FileManager.default
        guard let goalsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Goals") else {
            return
        }

        let goalDirectory = goalsDirectory.appendingPathComponent(goalName)

        // Create the directory for the goal
        do {
            try fileManager.createDirectory(at: goalDirectory, withIntermediateDirectories: true)
        } catch {
            print("Error creating goal directory: \(error)")
            return
        }

        // Save the image
        if let image = goalImage {
            let imageData = image.jpegData(compressionQuality: 0.8)
            let imageURL = goalDirectory.appendingPathComponent("\(goalName.lowercased()).png")
            try? imageData?.write(to: imageURL)
        }

        // Save the JSON data
        let startDate = Date()
        let bookEntries = books.map { BookEntry(name: $0, status: false) }
        let goalData = ItemDescription(books: bookEntries, startDate: startDate, endDate: goalEndDate)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        do {
            let jsonData = try encoder.encode(goalData)
            let jsonURL = goalDirectory.appendingPathComponent("\(goalName.lowercased())data.json")
            try jsonData.write(to: jsonURL)
        } catch {
            print("Error saving goal data: \(error)")
        }

        // Dismiss the view
        presentationMode.wrappedValue.dismiss()
    }
}

// Image Picker for selecting an image
struct ImagePicker: UIViewControllerRepresentable {
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// Preview
#Preview {
       AddGoalView()
}