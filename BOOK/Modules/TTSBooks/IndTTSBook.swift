import SwiftUI
import PDFKit
import AVFoundation

struct IndTTSBook: View {
    let bookPath: URL

    @State private var pdfDocument: PDFDocument?
    @State private var currentPageIndex: Int = 0
    @State private var isPlayingTTS: Bool = false
    @State private var synthesizer = AVSpeechSynthesizer()

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
           let bookData = try? JSONDecoder().decode(BookData.self, from: jsonData) {
            bookDescription = bookData.description
            pageNumber = bookData.pageNumber

            // Set initial page
            currentPageIndex = pageNumber
            pdfDocument?.go(to: pdfDocument?.page(at: currentPageIndex) ?? PDFPage())
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
        let utterance = AVSpeechUtterance(string: pageContent)
        utterance.rate = 0.5
        synthesizer.delegate = self
        synthesizer.speak(utterance)
    }

    private func stopTTS() {
        synthesizer.stopSpeaking(at: .immediate)
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

extension IndTTSBook: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        guard isPlayingTTS else { return }
        nextPage()
        startTTS()
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

struct BookData: Codable {
    let description: String
    let pageNumber: Int
}

#Preview {
    IndTTSBook(bookPath: URL(string: "example/path/to/book")!)
}