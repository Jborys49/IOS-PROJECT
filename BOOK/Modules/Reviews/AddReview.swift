import SwiftUI

struct AddReview: View {
    @State private var bookName: String = ""
    @State private var description: String = ""
    @State private var tags: [String] = []
    @State private var newTag: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @Environment(\.presentationMode) var presentationMode // To dismiss view
    @Binding var items:[DirectoryItem]//refreshing the thingimajig when creation is over
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
                        Text("Upload picture here")
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
            TextField("Book", text: $bookName)
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
                .overlay(
                    HStack {
                        Spacer()
                        if !description.isEmpty {
                            Button(action: { description = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
                .frame(maxWidth: .infinity)
            
            // Add Tag Section
            HStack {
                TextField("Add tag", text: $newTag)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                
                Button(action: {
                    if !newTag.isEmpty {
                        tags.append(newTag)
                        newTag = ""
                    }
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .clipShape(Circle())
                }
            }
            
            // Display Tags
            ScrollView(.horizontal) {
                HStack {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .padding(.horizontal)
                            .padding(.vertical, 5)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        if let index = tags.firstIndex(of: tag) {
                                            tags.remove(at: index)
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                            .padding(.trailing, 5)
                                    }
                                }
                            )
                    }
                }
            }
            
            Spacer()
            
            // Confirm Button
            Button(action: saveReview) {
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
        .navigationTitle("Add Review")
    }
    
    func saveReview() {
        guard !bookName.isEmpty, let image = selectedImage else {
            print("Error: Missing book name or image")
            return
        }
        
        let fm = FileManager.default
        guard let baseURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Unable to access document directory")
            return
        }
        
        let readBooksURL = baseURL.appendingPathComponent("ReadBooks")
        let bookDirectoryURL = readBooksURL.appendingPathComponent(bookName)
        
        do {
            // Create the book directory
            try fm.createDirectory(at: bookDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            
            // Save the image
            let imageURL = bookDirectoryURL.appendingPathComponent("\(bookName).png")
            if let pngData = image.pngData() {
                try pngData.write(to: imageURL)
            }
            
            // Save the description and tags as JSON
            let descriptionData = GoalDescription(description: description, tags: tags)
            let jsonURL = bookDirectoryURL.appendingPathComponent("\(bookName.lowercased())_data.json")
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(descriptionData)
            try jsonData.write(to: jsonURL)
            let newItem = DirectoryItem(
                            name: bookName,
                            image: Image(uiImage: selectedImage ?? UIImage()),
                            description: description,
                            tags: tags
                        )
            items.append(newItem)
            // Dismiss the view
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving review: \(error.localizedDescription)")
        }
    }
}

// ImagePicker for selecting an image
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}