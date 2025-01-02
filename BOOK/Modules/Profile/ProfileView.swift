import SwiftUI

struct ProfileView: View {
    @State private var profileImage: UIImage = UIImage(named: "ProfileDefPic")! // Default profile picture
    @State private var username: String = "User"// Default username
    @State private var installationDate: String = ""
    @State private var reviews: Int = 0
    @State private var goalsCompleted: Int = 0
    
    @State private var showImagePicker = false
    @State private var newImage: UIImage? = nil

    var body: some View {
        NavigationView {
            VStack {
                // Editable Profile Picture
                Button(action: {
                    showImagePicker = true
                }) {
                    Image(uiImage: profileImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 300, height: 300)
                        .clipShape(Rectangle())
                        .overlay(Rectangle().stroke(Color.gray, lineWidth: 2))
                        .shadow(radius: 5)
                }
                .padding()
                .sheet(isPresented: $showImagePicker, onDismiss: loadImage) {
                    ImagePicker(image: $newImage)
                }
                
                // Editable Username
                TextField("Enter Username", text: $username)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal, 40)

                // Display Profile Information
                VStack(alignment: .leading, spacing: 10) {
                    Text("Date of Installation: \(installationDate)")
                    Text("Number of reviews written: \(reviews)")
                    Text("Goals completed: \(goalsCompleted)")
                }
                .font(.body)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Profile")
            .onAppear(perform: loadProfileData)
            .onDisappear(perform: saveProfileData)
        }
    }
    
    // Load profile data from BookKeepProfile directory
    func loadProfileData() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let profileDirectory = documentsURL.appendingPathComponent("BookKeepProfile")
        let imageFile = profileDirectory.appendingPathComponent("profile.png")
        let jsonFile = profileDirectory.appendingPathComponent("profile_data.json")

        // Load profile image
        if let imageData = try? Data(contentsOf: imageFile), let loadedImage = UIImage(data: imageData) {
            profileImage = loadedImage
        }

        // Load JSON data
        if let jsonData = try? Data(contentsOf: jsonFile) {
            if let decodedData = try? JSONDecoder().decode(ProfileData.self, from: jsonData) {
                username = decodedData.username
                installationDate = decodedData.date
                reviews = decodedData.reviews
                goalsCompleted = decodedData.goalsc
            }
        }
    }

    // Save profile data to BookKeepProfile directory
    func saveProfileData() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let profileDirectory = documentsURL.appendingPathComponent("BookKeepProfile")
        let imageFile = profileDirectory.appendingPathComponent("profile.png")
        let jsonFile = profileDirectory.appendingPathComponent("profile_data.json")

        // Save profile image
        if let newImage = newImage {
            if let imageData = newImage.pngData() {
                try? imageData.write(to: imageFile)
            }
        }

        // Save JSON data
        let profileData = ProfileData(username: username, date: installationDate, reviews: reviews, goalsc: goalsCompleted)
        if let jsonData = try? JSONEncoder().encode(profileData) {
            try? jsonData.write(to: jsonFile)
        }
    }

    // Function to load the image after selecting from the picker
    func loadImage() {
        if let newImage = newImage {
            profileImage = newImage
        }
    }
}

// Profile Data Structure (matches JSON structure)
struct ProfileData: Codable {
    var username: String
    var date: String
    var reviews: Int
    var goalsc: Int
}

// Preview for SwiftUI Canvas
#Preview{
    ProfileView()
}
