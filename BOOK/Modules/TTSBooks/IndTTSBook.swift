import SwiftUI
import PDFKit
import AVFoundation

class TTSBookManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var currentPageIndex: Int = 0
    @Published var isPlayingTTS: Bool = false

    private let synthesizer = AVSpeechSynthesizer()
    var pdfDocument: PDFDocument?
    private let bookPath: URL
    private var bookDescription: String = ""
    private var lastSpokenRange: NSRange? //for resuming
    private var currentPageContent: String?
    var currentUtterance: AVSpeechUtterance?

    init(bookPath: URL) {
        self.bookPath = bookPath
        super.init()
        synthesizer.delegate = self
        loadBook()
    }

    func loadBook() {
        // Load PDF
        let pdfPath = bookPath.appendingPathComponent("\(bookPath.lastPathComponent).pdf")
        pdfDocument = PDFDocument(url: pdfPath)

        // Load JSON
        let jsonPath = bookPath.appendingPathComponent("\(bookPath.lastPathComponent)_data.json")
        if let jsonData = try? Data(contentsOf: jsonPath),
           let bookData = try? JSONDecoder().decode(BookDataTTS.self, from: jsonData) {
            bookDescription = bookData.description
            currentPageIndex = bookData.pageNumber
        }
    }

    func nextPage() {
        guard let pdfDocument = pdfDocument else { return }
        if currentPageIndex == pdfDocument.pageCount - 1{
            currentPageIndex = 0
        }
        else {
            currentPageIndex += 1
        }
    }

    func previousPage() {
        guard let pdfDocument = pdfDocument else { return }
        if currentPageIndex == 0
        {
            currentPageIndex = pdfDocument.pageCount - 1
        } else {
            currentPageIndex -= 1
        }
    }

    func startTTS() {
        guard !isPlayingTTS, let pdfDocument = pdfDocument else { return }
        guard let page = pdfDocument.page(at: currentPageIndex) else {return}

        let pageContent = page.string
        currentPageContent=pageContent?.isEmpty == false ? pageContent! : "   "

        // Stop any existing TTS before starting
        stopTTS()

        isPlayingTTS = true
        let utterance = AVSpeechUtterance(string: currentPageContent!)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5 // Adjust the speed as needed
        currentUtterance = utterance
        synthesizer.speak(utterance)
    }

    func stopTTS() {
            guard synthesizer.isSpeaking else { return }
            synthesizer.stopSpeaking(at: .immediate)
            isPlayingTTS = false
    }

    func resumeTTS() {
            guard !synthesizer.isSpeaking, let content = currentPageContent else { return }
            if let range = lastSpokenRange {
                let substring = (content as NSString).substring(from: range.location)
                let utterance = AVSpeechUtterance(string: substring)
                utterance.rate = 0.5
                synthesizer.speak(utterance)
            } else {
                startTTS() // Start from the beginning if no range is available
            }
            isPlayingTTS = true
        }

    func saveCurrentPage() {
        let jsonPath = bookPath.appendingPathComponent("\(bookPath.lastPathComponent)_data.json")
        let updatedData = BookDataTTS(description: bookDescription, pageNumber: currentPageIndex)

        do {
            let jsonData = try JSONEncoder().encode(updatedData)
            try jsonData.write(to: jsonPath)
        } catch {
            print("Error saving current page: \(error)")
        }
    }

    // AVSpeechSynthesizerDelegate Methods
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
         if isPlayingTTS {
            isPlayingTTS=false
            currentPageContent=nil
            lastSpokenRange=nil
            nextPage()
            startTTS()
        }
    }

     func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
            lastSpokenRange = characterRange // Update the range as the synthesizer progresses
        }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isPlayingTTS = false
    }
}

struct IndTTSBook: View {
    @StateObject var bookManager: TTSBookManager

    init(bookPath: URL) {
        _bookManager = StateObject(wrappedValue: TTSBookManager(bookPath: bookPath))
    }

    var body: some View {
        VStack {
            // PDF Viewer
            if let pdfDocument = bookManager.pdfDocument {
                PDFViewUI(pdfDocument: pdfDocument, currentPageIndex: $bookManager.currentPageIndex)
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.width < 0 {
                                    // Swipe Right -> Forward
                                    bookManager.nextPage()
                                } else if value.translation.width > 0 {
                                    // Swipe Left -> Backward
                                    bookManager.previousPage()
                                }
                            }
                    )
            } else {
                Text("Unable to load PDF")
                    .foregroundColor(.red)
            }

            Spacer()

            // TTS Play Button
            HStack {
                Spacer()
                Button(action: toggleTTS) {
                    Image(systemName: bookManager.isPlayingTTS ? "stop.fill" : "play.fill")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                .padding()
            }
        }
        .onDisappear {
            bookManager.saveCurrentPage()
            bookManager.stopTTS()
        }
        .navigationTitle("Reading Book")
    }

    private func toggleTTS() {
        if bookManager.isPlayingTTS {
            bookManager.stopTTS()
        } else {
            if let _ = bookManager.currentUtterance {
                print("resume")
                bookManager.resumeTTS()  // If speech was stopped, resume it
            } else {
                bookManager.startTTS()  // If not started, start speech
                print("start")
            }
        }
    }
}
