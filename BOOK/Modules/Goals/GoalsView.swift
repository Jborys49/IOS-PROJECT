//
//  GoalsView.swift
//  BOOK
//
//  Created by IOSLAB on 14/11/2024.
//

import SwiftUI

struct GoalItem: Identifiable {
    let id = UUID()
    let name: String
    let image: Image
    let completed: Double
    let url:String
}
struct ItemDescription: Decodable{
    var completed: String
    var books:[String]
}
struct GoalsView: View {
    var body: some View {
       @State var items: [GoalItems] = []
       @State private var loaded = false
        NavigationView{
                VStack{
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(items) { item in
                                NavigationLink(destination: IndGoalView(
                                    image: item.image,
                                    books: item.books
                                    )) {
                                    VStack {
                                        // Image
                                        item.image
                                            .resizable()
                                            .frame(width: 50, height: 50)
                                            .clipShape(Circle())
                                         Text(item.name)
                                         .font(.headline)
                                    ProgressView(value:item.completed)
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
                    .navigationTitle("Your Goals")
                }
                Spacer()

            }

    }
    func ensureLoadOnce(){
            if (!loaded){
                loadGoals()
                loaded=true
            }
    }
    func loadGoals()
    {
            let fm = FileManager.default

            guard let BaseDataURL = fm.urls(for: .documentDirectory, //base url for storing data such as reviews or goals
                                                 in:.userDomainMask).first else
                    {
                        return
                    }
            let GoalsURL=BaseDataURL.appendingPathComponent("Goals") //base directory for storing reviews

            do {
                // Get the list of directories in the base URL
                let directories = try fm.contentsOfDirectory(at: GoalsURL, includingPropertiesForKeys: nil)

                // Iterate over each directory
                for directory in directories {
                    if directory.hasDirectoryPath && directory.lastPathComponent != ".DS_Store" {
                        var name = directory.lastPathComponent

                        // Load the image
                        let imageFileURL = directory.appendingPathComponent("\(name).png")
                        let image: Image = fm.fileExists(atPath: imageFileURL.path) ? Image(uiImage: UIImage(contentsOfFile: imageFileURL.path) ?? UIImage()) : Image(systemName: "photo")

                        // Load the description
                        name=name.lowercased()
                        let descriptionFileURL = directory.appendingPathComponent("\(name)data.json")
                        //print(descriptionFileURL)
                        var completed = 0.0
                        var books:[(key:String,value:Bool)] = []
                        var url=""
                        if let jsonData = FileManager.default.contents(atPath: descriptionFileURL.path) {
                            let decoder = JSONDecoder()
                            do {
                                let decoded = try decoder.decode(ItemDescription.self,from:  jsonData)
                                completed=decoded.completed/decoded.books.count
                                url=directory
                            }
                            catch{print("\(error)")}
                        }

                        // Append to items
                        items.append(GoalItem(name: name, image: image, completed: completed,url:url))
                    }
                }
            } catch {
                print("Error reading directory: \(error.localizedDescription)")
            }
    }
}

#Preview{
    GoalsView()
}
