import SwiftUI

struct AddTTSBook: View {
    @State private var bookName: String = ""
    @State private var description: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var pdfUploaded: Bool = false
    @State private var showImagePicker = false
    @State private var showPDFPicker = false
    @State private var pdfURL: URL? = nil
    @Environment(\.presentationMode) var presentationMode // To dismiss view
    @Binding var books: [TTSBookItem] // Refreshing the view after adding the book

    var body: some View {
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
                .overlay(
                    HStack {
                        Spacer()
                        if !bookName.isEmpty {
                            Button(action: { bookName = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
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
                                                 pdfUploaded = true // Indicate a PDF has been selected
                                             }
                )
            }

            Spacer()

            // Confirm Button
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
        .navigationTitle("Add TTS Book")
    }

    func saveTTSBook() {
        guard !bookName.isEmpty, let image = selectedImage, pdfUploaded,let pdfURL=pdfURL else { //the let = is to make it not optional
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
            let newItem = TTSBookItem(name: bookName, image: Image(uiImage: selectedImage ?? UIImage()),description: description,path:bookDirectoryURL)
            books.append(newItem)

            // Dismiss the view
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving TTS book: \(error.localizedDescription)")
        }
    }
}

// PDF Picker for selecting a PDF
struct PDFPicker: UIViewControllerRepresentable {
    var onPDFSelected: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: PDFPicker

        init(_ parent: PDFPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                parent.onPDFSelected(url)
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
    }
}
