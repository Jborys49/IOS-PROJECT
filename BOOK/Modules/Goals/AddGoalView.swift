import SwiftUI

struct AddGoalView: View {
    @State private var goalName: String = ""
    @State private var goalEndDate: Date = Date()
    @State private var books: [String] = [] 
    @State private var newBook: String = ""
    @State private var goalImage: UIImage? = nil
    @State private var showImagePicker = false

    @Environment(\.presentationMode) var presentationMode
    @Binding var items: [GoalItem]

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
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
                    ForEach(books, id: \.self) { book in
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
                        .padding(.vertical, 4)
                    }
                }
                .padding()
            }
            .padding(.bottom, 80) // To avoid overlapping with the button

            // Save Button
            VStack {
                Spacer()
                Button(action: saveGoal) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .padding()
                        .shadow(radius: 4)
                }
                .padding(.bottom, 20) // Add padding from the bottom so it dont collide with contentview
            }
        }
        .navigationTitle("Add Goal")
    }

    // Save goal data
    func saveGoal() {
        guard !goalName.isEmpty else { return } // Ensure goal name is not empty

        let fileManager = FileManager.default
        guard let goalsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("BookKeepGoals") else {
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

        let newitem = GoalItem(name: goalName,
                               image: Image(uiImage: goalImage ?? UIImage()),
                               completed: 0,
                               startDate: startDate,
                               endDate: goalEndDate,
                               url: goalDirectory)
        // Dismiss the view
        items.append(newitem)
        presentationMode.wrappedValue.dismiss()
    }
}
