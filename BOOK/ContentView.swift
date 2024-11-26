import SwiftUI

struct ContentView: View {
    
    @State private var outputText: String = ""
    
    var body: some View {
        VStack {
            Text("File Manager Output")
                .font(.title)
                .padding()
            
            Text(outputText)
                .padding()
                .foregroundColor(.blue)
            
            Spacer()
        }
        .onAppear(perform: loadFiles)
    }
    
    func loadFiles() {
        let fm = FileManager.default
        guard let url = fm.urls(for: .documentDirectory,
                                     in:.userDomainMask).first else
        {
            return
        }
        print(url)
        guard let path = Bundle.main.resourcePath?.appending("") else {
            outputText = "Failed to get the resource path."
            return
        }
        
        do {
            let path=url.appendingPathComponent("ReadBooks").appendingPathComponent("Test1")
            let items = try fm.contentsOfDirectory(atPath: path.path)
            
            var result = "Found files:\n"
            for item in items {
                result += "Found \(item)\n"
            }
            outputText = result
            
        } catch {
            outputText = "Failed to read directory – bad permissions, perhaps?"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
struct User:Codable{
    var language:String
    var text:String
}
