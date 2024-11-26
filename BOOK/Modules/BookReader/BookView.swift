//
//  BookView.swift
//  BOOK
//
//  Created by IOSLAB on 14/11/2024.
//
/*
import SwiftUI
import AVFoundation
import AVKit

struct BookView: View {
    
    @State private var folderNames: [String] = []
    var body: some View {
        NavigationView {
            VStack {
                // List to display folder names
                List(folderNames, id: \.self) { folder in
                    Button(action: {
                        TTSRead(folderName: folder)
                    }) {
                        Text(folder)
                    }
                }
                .onAppear(perform: fetchFolderNames)
                Spacer() // Pushes buttons to the bottom
                
                HStack {
                    NavigationLink(destination: BookView()) {
                        Image("BookIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                    }
                    .padding()
                    
                    NavigationLink(destination: BookListView()) {
                        Image("BookIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                    }
                    .padding()
                    
                    NavigationLink(destination: GoalsView()) {
                        Image("ListIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                    }
                    .padding()
                    
                    NavigationLink(destination: ProfileView()) {
                        Image("ProfileIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                    }
                    .padding()
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("BookReader")
        }
    }
    // Function to fetch folder names
    private func fetchFolderNames() {
        let fileManager = FileManager.default
            // Path to the "ttsbooks" folder inside the main bundle
            guard let ttsbooksPath = Bundle.main.resourcePath?.appending("/ttsbooks")

        else {
                print("Unable to locate ttsbooks directory.")
                return
            }
            do {
                let items = try fileManager.contentsOfDirectory(atPath: ttsbooksPath)
                // Filter to include only folders
                folderNames = items.filter { item in
                    var isDirectory: ObjCBool = false
                    let fullPath = ttsbooksPath + "/\(item)"
                    fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory)
                    return isDirectory.boolValue
                }
            } catch {
                print("Error fetching folder names: \(error.localizedDescription)")
            }
    }
    
    // Function to fetch and parse JSON from folder
    private func TTSRead(folderName: String) {
        let basePath = Bundle.main.resourcePath! + "/ttsbooks"
        let folderPath = basePath + "/\(folderName)"
        let jsonFilePath = folderPath + "/data_\(folderName.lowercased()).json" // Example naming
        // Assuming JSON file is named `data.json`
        
        let fileManager = FileManager.default
        
        // Check if the file exists
        guard fileManager.fileExists(atPath: jsonFilePath) else {
            print("JSON file not found in folder: \(folderName)")
            return
        }
        
        do {
            // Read the JSON file contents
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: jsonFilePath))
            
            // Decode JSON into a Swift model
            let decodedData = try JSONDecoder().decode(Book.self, from: jsonData)
            let utterance = AVSpeechUtterance(string:decodedData.text)
            utterance.voice = AVSpeechSynthesisVoice(language:decodedData.language)
            
            let TTS = AVSpeechSynthesizer()
            TTS.speak(utterance)
            //print("JSON Decoded Successfully: \(decodedData)")
        } catch {
            print("Error reading or decoding JSON: \(error.localizedDescription)")
        }
    }
}
// Example Swift model to decode JSON into
struct Book: Codable {
    let language: String
    let text: String
}

#Preview{
    BookView()
}
*/
