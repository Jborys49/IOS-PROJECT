import SwiftUI
import PDFKit
import AVFoundation

struct IndTTSBook: View {
    let bookPath: URL

    @State private var pdfDocument: PDFDocument?
    @State private var currentPageIndex: Int = 0
    @State private var isPlayingTTS: Bool = false

    private let ttsManager = TTSManager()

    @State private var bookDescription: String = ""
    @State private var pageNumber: Int = 0

    var body: some View {
        VStack {
            // PDF Viewer
            if let pdfDocument = pdfDocument {
                PDFViewUI(pdfDocument: pdfDocument, currentPageIndex: $currentPageIndex)
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.width < 0 {
                                    // Swipe Right -> Forward
                                    nextPage()
                                } else if value.translation.width > 0 {
                                    // Swipe Left -> Backward
                                    previousPage()
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
                    Image(systemName: isPlayingTTS ? "stop.fill" : "play.fill")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                .padding()
            }
        }
        .onAppear(perform: loadBook)
        .onDisappear {
            saveCurrentPage()
            stopTTS()
        }
        .navigationTitle("Reading Book")
    }

    private func loadBook() {
        // Load PDF
        let pdfPath = bookPath.appendingPathComponent("\(bookPath.lastPathComponent).pdf")
        pdfDocument = PDFDocument(url: pdfPath)

        // Load JSON data
        let jsonPath = bookPath.appendingPathComponent("\(bookPath.lastPathComponent)_data.json")
        if let jsonData = try? Data(contentsOf: jsonPath),
           let bookData = try? JSONDecoder().decode(BookDataTTS.self, from: jsonData) {
            bookDescription = bookData.description
            pageNumber = bookData.pageNumber

            // Set initial page
            currentPageIndex = pageNumber
        }
    }

    private func nextPage() {
        guard let pdfDocument = pdfDocument else { return }
        if currentPageIndex < pdfDocument.pageCount - 1 {
            currentPageIndex += 1
        }
    }

    private func previousPage() {
        if currentPageIndex > 0 {
            currentPageIndex -= 1
        }
    }

    private func toggleTTS() {
        if isPlayingTTS {
            stopTTS()
        } else {
            startTTS()
        }
    }

    private func startTTS() {
        guard let pdfDocument = pdfDocument,
              let page = pdfDocument.page(at: currentPageIndex),
              let pageContent = page.string else { return }

        isPlayingTTS = true
        ttsManager.startSpeaking(text: pageContent) { [weak self] finished in
            guard let self = self else { return }
            if finished {
                self.nextPage()
                self.startTTS()
            }
        }
    }

    private func stopTTS() {
        ttsManager.stopSpeaking()
        isPlayingTTS = false
    }

    private func saveCurrentPage() {
        let jsonPath = bookPath.appendingPathComponent("\(bookPath.lastPathComponent)_data.json")
        let updatedData = BookData(description: bookDescription, pageNumber: currentPageIndex)

        do {
            let jsonData = try JSONEncoder().encode(updatedData)
            try jsonData.write(to: jsonPath)
        } catch {
            print("Error saving current page: \(error)")
        }
    }
}

struct PDFViewUI: UIViewRepresentable {
    let pdfDocument: PDFDocument
    @Binding var currentPageIndex: Int

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.displayMode = .singlePage
        pdfView.autoScales = true
        pdfView.document = pdfDocument
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let page = pdfDocument.page(at: currentPageIndex) {
            pdfView.go(to: page)
        }
    }
}

// Data structure for book data
struct BookDataTTS: Codable {
    let description: String
    let pageNumber: Int
}

// TTS Manager for Speech Handling
class TTSManager: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var completion: ((Bool) -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func startSpeaking(text: String, completion: @escaping (Bool) -> Void) {
        self.completion = completion
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        completion?(true)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        completion?(false)
    }
}