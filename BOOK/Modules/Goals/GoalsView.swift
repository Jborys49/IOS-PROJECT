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
    let url:URL
}
struct ItemDescription: Decodable{
    var completed: Int
    var books:[String]
    var status:[Bool]
}
struct GoalsView: View {
    @State var items: [GoalItem] = []
    @State private var loaded = false
    var body: some View {
        NavigationView{
            VStack{
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(items) { item in
                            NavigationLink(destination: IndGoalView(
                                directoryURL:item.url
                            )) {
                                VStack {
                                    // Image
                                    item.image
                                        .resizable()
                                        .scaledToFit()
                                            .frame(
                                                minWidth: 0,
                                                maxWidth: .infinity,
                                                minHeight: 100,
                                                maxHeight: 100
                                        )
                                        
                                    Text(item.name)
                                        .font(.headline)
                                    ProgressView(value:item.completed)
                                    Spacer()
                                }
                                .padding()
                                .frame(width: 300, height: 150)
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
                        let actname = directory.lastPathComponent
                        let name = directory.lastPathComponent.lowercased()
                        // Load the image
                        let imageFileURL = directory.appendingPathComponent("\(name).png")
                        let image: Image = fm.fileExists(atPath: imageFileURL.path) ? Image(uiImage: UIImage(contentsOfFile: imageFileURL.path) ?? UIImage()) : Image(systemName: "photo")

                        // Load the description
                        
                        let descriptionFileURL = directory.appendingPathComponent("\(name)data.json")
                        //print(descriptionFileURL)
                        var completed:Double = 0
                        if let jsonData = FileManager.default.contents(atPath: descriptionFileURL.path) {
                            let decoder = JSONDecoder()
                            do {
                                let decoded = try decoder.decode(ItemDescription.self,from:  jsonData)
                                completed=(Double(decoded.completed) ?? 1)/Double(decoded.books.count)
                            }
                            catch{print("\(error)")}
                        }
                        print(String(completed)+"here it be bruh")
                        // Append to items
                        items.append(GoalItem(name: actname, image: image, completed: completed,url:directory))
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
