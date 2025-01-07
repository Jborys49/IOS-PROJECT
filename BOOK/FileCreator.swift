import SwiftUI

class AppFileManager {
    static let shared = AppFileManager()

    private let fileManager = FileManager.default
    private let documentsURL: URL

    private init() {
        // Initialize the Documents directory URL
        documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    /// Ensures all required folders and files exist in the Documents directory
    func setupDirectoriesAndFiles() {
        // Define folder names
        let folders = ["BookKeepGoals", "BookKeepReviews", "BookKeepTTSBooks"]

        // Create folders if they don't exist
        for folder in folders {
            let folderURL = documentsURL.appendingPathComponent(folder)
            createDirectoryIfNeeded(at: folderURL)
        }

        // Handle the BookKeepProfile folder
        let profileFolderURL = documentsURL.appendingPathComponent("BookKeepProfile")
        createDirectoryIfNeeded(at: profileFolderURL)

        // Add profile image and JSON file if they don't exist
        addProfileImageIfNeeded(to: profileFolderURL)
        addProfileDataJSONIfNeeded(to: profileFolderURL)
    }

    /// Creates a directory at the given URL if it doesn't exist
    private func createDirectoryIfNeeded(at url: URL) {
        if !fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                print("Created directory: \(url.lastPathComponent)")
            } catch {
                print("Error creating directory \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
    }

    /// Adds the default profile image if it doesn't exist
    private func addProfileImageIfNeeded(to profileFolderURL: URL) {
        let profileImageURL = profileFolderURL.appendingPathComponent("profile.png")

        if !fileManager.fileExists(atPath: profileImageURL.path) {
            if let defaultImage = UIImage(named: "ProfileDefPic"),
               let imageData = defaultImage.pngData() {
                do {
                    try imageData.write(to: profileImageURL)
                    print("Added default profile image")
                } catch {
                    print("Error saving profile image: \(error.localizedDescription)")
                }
            } else {
                print("Default image 'ProfileDefPic' not found in assets")
            }
        }
    }

    /// Adds the default profile data JSON file if it doesn't exist
    private func addProfileDataJSONIfNeeded(to profileFolderURL: URL) {
        let profileDataURL = profileFolderURL.appendingPathComponent("profile_data.json")

        if !fileManager.fileExists(atPath: profileDataURL.path) {
            let currentDate = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none)
            let profileData: [String: Any] = [
                "username": "User",
                "date": currentDate,
                "goalsc": 0,
                "reviews": 0
            ]

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: profileData, options: .prettyPrinted)
                try jsonData.write(to: profileDataURL)
                print("Added default profile data JSON")
            } catch {
                print("Error saving profile data JSON: \(error.localizedDescription)")
            }
        }
    }
}
