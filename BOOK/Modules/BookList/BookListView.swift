import SwiftUI

struct DirectoryItem: Identifiable {
    let id = UUID()
    let name: String
    let image: Image
    let description: String
    let tags: [String]
}
struct GoalDescription: Decodable{
    var description: String
    var tags:[String]
}

struct BookListView: View {
    @State var items: [DirectoryItem] = []
    @State private var loaded = false
    var body: some View {
        NavigationView{
        VStack{
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(items) { item in
                        NavigationLink(destination: ReviewView(
                            image: item.image,
                            description: item.description,
                            tags: item.tags
)) {
                            HStack {
                                // Image
                                item.image
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                
                                // Text information
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.headline)
                                    
                                    Text(item.description)
                                        .font(.subheadline)
                                        .lineLimit(2) // Limit to 2 lines
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding()
                            .frame(width: 300, height: 80)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                        }
                    }
                }
                .padding()
            }
            .onAppear(perform:ensureLoadOnce)
            .navigationTitle("Saved Reviews")
        }
        Spacer()
    
    }
    }
    func ensureLoadOnce(){
        if (!loaded){
            loadDirectoryItems()
            loaded=true
        }
    }
    func loadDirectoryItems() {
        let fm = FileManager.default

        guard let BaseDataURL = fm.urls(for: .documentDirectory, //base url for storing data such as reviews or goals
                                             in:.userDomainMask).first else
                {
                    return
                }
        let ReadBooksURL=BaseDataURL.appendingPathComponent("ReadBooks") //base directory for storing reviews
        print(BaseDataURL)
        do {
            // Get the list of directories in the base URL
            let directories = try fm.contentsOfDirectory(at: ReadBooksURL, includingPropertiesForKeys: nil)
           
            // Iterate over each directory
            for directory in directories {
                if directory.hasDirectoryPath && directory.lastPathComponent != ".DS_Store" {
                    var name = directory.lastPathComponent
                   
                    // Load the image
                    let imageFileURL = directory.appendingPathComponent("\(name).png")
                    let image: Image = fm.fileExists(atPath: imageFileURL.path) ? Image(uiImage: UIImage(contentsOfFile: imageFileURL.path) ?? UIImage()) : Image(systemName: "photo")
                   
                    // Load the description
                    name=name.lowercased()
                    let descriptionFileURL = directory.appendingPathComponent("\(name)_data.json")
                    //print(descriptionFileURL)
                    var description = "No description available"
                    var tags:[String] = []
                    if let jsonData = FileManager.default.contents(atPath: descriptionFileURL.path) {
                        let decoder = JSONDecoder()
                        do {
                            let decoded = try decoder.decode(GoalDescription.self,from:  jsonData)
                            description=decoded.description
                            tags=decoded.tags
                        }
                        catch{print("\(error)")}
                    }
                   
                    // Append to items
                    items.append(DirectoryItem(name: name, image: image, description: description,tags:tags))
                }
            }
        } catch {
            print("Error reading directory: \(error.localizedDescription)")
        }
    }
}


#Preview{
    BookListView()
}
