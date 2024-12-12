import SwiftUI
struct GoalItem: Identifiable {
    let id = UUID()
    let name: String
    let image: Image
    var completed: Double
    let startDate: Date
    let endDate: Date
    let url: URL

}

struct ItemDescription: Decodable, Encodable {
    var books: [BookEntry]
    var startDate: Date
    var endDate: Date
}

struct BookEntry: Decodable, Encodable {
    var name: String
    var status: Bool
}

struct GoalsView: View {
    @State var items: [GoalItem] = []
    @State private var loaded = false
    @State private var showAlert = false
    @State private var goalToDelete: GoalItem?

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(items) { item in
                            HStack {
                                NavigationLink(destination: IndGoalView(directoryURL: item.url, updateProgress: updateProgress)) {
                                    VStack(alignment: .leading) {
                                        // Image
                                        HStack{
                                            item.image
                                                .resizable()
                                                .scaledToFit()
                                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 100, maxHeight: 100)
                                            
                                            Button(action: {
                                                goalToDelete = item
                                                showAlert = true
                                            }) {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                                    .padding()
                                            }
                                        }
                                        
                                        // Goal Name
                                        Text(item.name)
                                            .font(.headline)
                                        
                                        // Progress View
                                        ProgressView(value: item.completed)
                                            .accentColor(item.completed == 1.0 ? .green : .blue)
                                        
                                        // Dates
                                        HStack {
                                            Text("End: \(formattedDate(item.endDate))")
                                                .foregroundColor(endDateColor(item.endDate))
                                                .font(.caption)
                                                .padding(.leading, 5)
                                            
                                            Spacer()
                                            
                                            Text("Start: \(formattedDate(item.startDate))")
                                                .foregroundColor(.gray)
                                                .font(.caption)
                                                .padding(.trailing, 5)
                                        }
                                    }
                                    .padding()
                                    .frame(width: 260, height: 170)
                                    .background(item.completed == 1.0 ? Color.green.opacity(0.2) : Color.white)
                                    .cornerRadius(10)
                                    .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .onAppear(perform: ensureLoadOnce)
                .navigationTitle("Your Goals")
                    Spacer()
                    HStack {
                        Spacer()
                        NavigationLink(destination: AddGoalView(items:$items)) {
                            Image(systemName: "plus")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding()
                        Spacer()
                    }
                
            }
        }
        .alert("Are you sure?", isPresented: $showAlert) {
            Button("Delete", role: .destructive) {
                if let goal = goalToDelete {
                    deleteGoal(goal)
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    func ensureLoadOnce() {
        if !loaded {
            loadGoals()
            loaded = true
        }
    }

    func loadGoals() {
        let fm = FileManager.default

                guard let baseDataURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    return
                }
        //let goalsURL = Bundle.main.resourceURL!.appendingPathComponent("Goals")
        //perhaps works and i dont have to use the damn documents directory
                let goalsURL = baseDataURL.appendingPathComponent("Goals") // Base directory for goals

                do {
                    // Get the list of directories in the base URL
                    let directories = try fm.contentsOfDirectory(at:goalsURL,includingPropertiesForKeys: nil)

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
                            var completed: Double = 0
                            var startDate = Date()
                            var endDate = Date()

                            if let jsonData = FileManager.default.contents(atPath: descriptionFileURL.path) {
                                let decoder = JSONDecoder()
                                decoder.dateDecodingStrategy = .iso8601
                                do {
                                    let decoded = try decoder.decode(ItemDescription.self, from: jsonData)

                                    // Calculate progress: Count true statuses
                                    let totalBooks = decoded.books.count
                                    let completedBooks = decoded.books.filter { $0.status }.count
                                    completed = Double(completedBooks) / Double(totalBooks)

                                    // Assign dates
                                    startDate = decoded.startDate
                                    endDate = decoded.endDate
                                } catch {
                                    print("\(error)")
                                }
                            }

                            // Append to items
                            items.append(GoalItem(name: actname, image: image, completed: completed, startDate: startDate, endDate: endDate, url: directory))
                        }
                    }
                } catch {
                    print("Error reading directory: \(error.localizedDescription)")
                }
    }

    func deleteGoal(_ goal: GoalItem) {
        items.removeAll { $0.id == goal.id }
        // Delete directory or files associated with the goal if needed
    }

    func updateProgress(for url: URL, completed: Double) {
        if let index = items.firstIndex(where: { $0.url == url }) {
            items[index].completed = completed
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    func endDateColor(_ endDate: Date) -> Color {
        let now = Date()
        if endDate < now {
            return .red
        } else if Calendar.current.dateComponents([.day], from: now, to: endDate).day ?? 0 < 7 {
            return .orange
        } else {
            return .gray
        }
    }
}
#Preview{
    GoalsView()
}
