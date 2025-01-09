import SwiftUI
import Combine
import PDFKit

struct AddTTSView: View {
    @State private var bookName: String = ""
    @State private var description: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var pdfUploaded: Bool = false
    @State private var showImagePicker = false
    @State private var showPDFPicker = false
    @State private var pdfURL: URL? = nil
    @StateObject private var viewModel = BookViewModel()
    @Environment(\.presentationMode) var presentationMode
    @Binding var books: [TTSBookItem]

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Add TTS Book Section
                    VStack(spacing: 20) {
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

                        TextField("Description", text: $description)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .frame(maxWidth: .infinity)

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

                    // API Section Title
                    Text("Or search for free books on the Gutenberg Library! - you can download the first page from this app")
                        .font(.headline)
                        .padding(.top)

                    // API Section
                    LazyVStack {
                        TextField("Search books", text: $viewModel.searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)

                        Button(action: {
                            viewModel.searchBooks()
                        }) {
                            Text("Search")
                                .font(.headline)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 20)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.bottom)

                        if viewModel.isLoading {
                            ProgressView()
                                .padding()
                        } else {
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
                                    viewModel.saveBook(book){ savedBook in
                                        // Append the new saved book to the books array
                                        books.append(savedBook)
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 80) // To avoid overlapping with the button
            }

            // Fixed Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: saveTTSBook) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                            .shadow(radius: 4)
                    }
                    .padding(.bottom, 20)
                    .padding(.leading, 20)
                }
            }
        }
        .navigationTitle("Add TTS Book")
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
            try fm.createDirectory(at: bookDirectoryURL, withIntermediateDirectories: true, attributes: nil)

            let imageURL = bookDirectoryURL.appendingPathComponent("\(bookName).png")
            if let pngData = image.pngData() {
                try pngData.write(to: imageURL)
            }

            let jsonURL = bookDirectoryURL.appendingPathComponent("\(bookName)_data.json")
            let jsonData = try JSONSerialization.data(withJSONObject: ["description": description, "pageNumber": 0], options: .prettyPrinted)
            try jsonData.write(to: jsonURL)

            let pdfDestinationURL = bookDirectoryURL.appendingPathComponent("\(bookName).pdf")
            try fm.copyItem(at: pdfURL, to: pdfDestinationURL)

            let newItem = TTSBookItem(name: bookName, image: Image(uiImage: selectedImage ?? UIImage()), description: description, path: bookDirectoryURL)
            books.append(newItem)

            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving TTS book: \(error.localizedDescription)")
        }
    }
}

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
