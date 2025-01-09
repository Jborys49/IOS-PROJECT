//
//  Models.swift
//  BOOK
//
//  Created by IOSLAB on 09/01/2025.
//
import SwiftUI
import Combine
import PDFKit
import Foundation
//Response from Book Api
struct BookAPI: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let coverURL: String
    let textURL: String
    let description: String
}
//Position in TTSBookView with link to actual content
struct TTSBookItem: Identifiable {
    let id = UUID()
    let name: String
    let image: Image
    let description: String
    let path: URL
}

//position in GoalsView
struct GoalItem: Identifiable {
    let id = UUID()
    let name: String
    let image: Image
    var completed: Double
    let startDate: Date
    let endDate: Date
    let url: URL

}

//the json file for goals
struct ItemDescription: Decodable, Encodable {
    var books: [BookEntry]
    var startDate: Date
    var endDate: Date
}

struct BookEntry: Decodable, Encodable {
    var name: String
    var status: Bool
}

//goals book
struct Book: Identifiable {
    let id = UUID()
    var title: String
    var isCompleted: Bool
}

// Profile Data (json)
struct ProfileData: Codable {
    var username: String
    var date: String
    var reviews: Int
    var goalsc: Int
}

//pdf viewer for ttsbooks
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
// Data structure for book data for ttsbooks
struct BookDataTTS: Codable {
    let description: String
    let pageNumber: Int
}
