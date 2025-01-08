import SwiftUI

struct AddTTSView: View {
    @State private var bookName: String = ""
    @State private var description: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var pdfUploaded: Bool = false
    @State private var showImagePicker = false
    @State private var showPDFPicker = false
    @State private var pdfURL: URL? = nil
    @Binding var books: [TTSBookItem] // Refreshing the view after adding the book
    @StateObject private var viewModel = BookViewModel()
    @Environment(\.presentationMode) var presentationMode // To dismiss view

    var body: some View {
        VStack {
            // Static Header with Save Button
            HStack {
                Spacer()
                Button(action: saveTTSBook) {
                    Image(systemName: "checkmark")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .zIndex(1) // Keeps button on top

            ScrollView {
                VStack(spacing: 20) {
                    // AddTTSBook Section
                    VStack(spacing: 20) {
                        // Image Upload Section
                        Button(action: {
                            showImagePicker = true
                        }) {
                            if let selectedImage = selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 150, height: 150)
                                    .clipShape(Circle())
                            } else {
                                VStack {
                                    Image(systemName: "arrow.up.to.line")
                                        .font(.system(size: 40))
                                    Text("Upload cover image")
                                        .font(.caption)
                                }
                                .frame(width: 150, height: 150)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
                            }
                        }
                        .sheet(isPresented: $showImagePicker) {
                            ImagePicker(image: $selectedImage)
                        }

                        // Book Name Input
                        TextField("Book Name", text: $bookName)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .frame(maxWidth: .infinity)

                        // Description Input
                        TextField("Description", text: $description)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .frame(maxWidth: .infinity)

                        // PDF Upload Section
                        Button(action: {
                            showPDFPicker = true
                        }) {
                            Text(pdfUploaded ? "PDF Uploaded" : "Upload PDF")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(pdfUploaded ? Color.green : Color.blue)
                                .cornerRadius(8)
                        }
                        .sheet(isPresented: $showPDFPicker) {
                            PDFPicker(onPDFSelected: { selectedPDFURL in
                                pdfURL = selectedPDFURL
                                pdfUploaded = true
                            })
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGroupedBackground))
                    .cornerRadius(12)

                    // lastapiView Section
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
                                            presentationMode.wrappedValue.dismiss()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }

    func saveTTSBook() {
        guard !bookName.isEmpty, let image = selectedImage, pdfUploaded, let pdfURL = pdfURL else {
            print("Error: Missing book name, image, or PDF")
            return
        }

        let fm = FileManager.default
        guard let baseURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Unable to access document directory")
            return
        }

        let ttsBooksURL = baseURL.appendingPathComponent("BookKeepTTSBooks")
        let bookDirectoryURL = ttsBooksURL.appendingPathComponent(bookName)

        do {
            // Create the book directory
            try fm.createDirectory(at: bookDirectoryURL, withIntermediateDirectories: true, attributes: nil)

            // Save the cover image
            let imageURL = bookDirectoryURL.appendingPathComponent("\(bookName).png")
            if let pngData = image.pngData() {
                try pngData.write(to: imageURL)
            }

            // Save the JSON data
            let jsonURL = bookDirectoryURL.appendingPathComponent("\(bookName)_data.json")
            let jsonData = try JSONSerialization.data(withJSONObject: ["description": description, "pageNumber": 0], options: .prettyPrinted)
            try jsonData.write(to: jsonURL)

            // Save the PDF
            let pdfDestinationURL = bookDirectoryURL.appendingPathComponent("\(bookName).pdf")
            try fm.copyItem(at: pdfURL, to: pdfDestinationURL)

            // Add to items for UI refresh
            let newItem = TTSBookItem(name: bookName, image: Image(uiImage: selectedImage ?? UIImage()), description: description, path: bookDirectoryURL)
            books.append(newItem)

            // Dismiss the view
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving TTS book: \(error.localizedDescription)")
        }
    }
}

#Preview {
    CombinedView(books: .constant([]))
}