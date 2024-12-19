import SwiftUI
import PDFKit
import AVFoundation

class TTSBookManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var currentPageIndex: Int = 0
    @Published var isPlayingTTS: Bool = false

    private let synthesizer = AVSpeechSynthesizer()
    var pdfDocument: PDFDocument?
    private var completion: ((Bool) -> Void)?
    private let bookPath: URL
    private var bookDescription: String = ""

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
        if currentPageIndex < pdfDocument.pageCount - 1 {
            currentPageIndex += 1
        }
    }

    func previousPage() {
        if currentPageIndex > 0 {
            currentPageIndex -= 1
        }
    }

    func startTTS() {
        guard !isPlayingTTS, let pdfDocument = pdfDocument else { return }
        guard let page = pdfDocument.page(at: currentPageIndex),
              let pageContent = page.string else { return }

        isPlayingTTS = true
        let utterance = AVSpeechUtterance(string: pageContent)
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }

    func stopTTS() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlayingTTS = false
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
        nextPage()
        startTTS()
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
            bookManager.startTTS()
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
