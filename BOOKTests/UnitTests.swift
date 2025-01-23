import XCTest
@testable import BOOK
final class UnitTests: XCTestCase {
    var viewModel: BookViewModel!

    override func setUpWithError() throws {
            try super.setUpWithError()
            viewModel = BookViewModel()
        }

    override func tearDownWithError() throws {
        viewModel = nil
        try super.tearDownWithError()
    }
    func testSearchBooks_EmptySearchText() {
            viewModel.searchText = ""

            viewModel.searchBooks()

            XCTAssertFalse(viewModel.isLoading, "isLoading should remain false for empty search text.")
            XCTAssertTrue(viewModel.books.isEmpty, "Books array should remain empty for empty search text.")
        }

    func testSearchBooks_ValidSearchText() throws {
        // Mock valid search text
        viewModel.searchText = "Pride and Prejudice"

        // Expectation for asynchronous operation
        let expectation = self.expectation(description: "Search books should return results")

        // Call the searchBooks method
        viewModel.searchBooks()

        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { // Provide a buffer for network call
            XCTAssertFalse(self.viewModel.books.isEmpty, "Books array should not be empty for valid search text.")
            XCTAssertFalse(self.viewModel.isLoading, "isLoading should be set to false after fetching data.")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 30, handler: nil)
    }
    
    func testSaveBook_ValidBook() throws {
            // Mock a valid book
            let book = BookAPI(
                title: "Test Book",
                author: "Test Author",
                coverURL: "https://example.com/test_cover.jpg",
                textURL: "https://example.com/test_book.txt",
                description: "Author: Test Author"
            )

            let expectation = self.expectation(description: "Save book should complete successfully")

            viewModel.saveBook(book) { savedBook in
                XCTAssertEqual(savedBook.name, book.title, "Saved book title should match original book title.")
                XCTAssertEqual(savedBook.description, book.description, "Saved book description should match original book description.")
                expectation.fulfill()
            }

            waitForExpectations(timeout: 10, handler: nil)
        }

        func testFileCreator() throws {
         let fileManager = FileManager.default
         let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
         let testee = AppFileManager()
         testee.setupDirectoriesAndFiles()
            let folders = ["BookKeepGoals", "BookKeepReviews", "BookKeepTTSBooks"]
            for folder in folders {
                XCTAssertTrue(fileManager.fileExists(atPath: documents.appendingPathComponent(folder)), "Folder not created")
            }
        }

        func testGoalItemDecoding() throws {
                // Sample JSON representation of a GoalItem
                let json = """
                {
                    "id": "6C98E2A3-8F5F-48D7-B104-CDA75EAF3B6A",
                    "name": "Learn Swift",
                    "image": "https://example.com/sample-image.png",
                    "completed": 0.5,
                    "startDate": "2025-01-01T00:00:00Z",
                    "endDate": "2025-12-31T23:59:59Z",
                    "url": "https://example.com"
                }
                """.data(using: .utf8)!

                // Use a JSONDecoder with appropriate date decoding strategy
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                do {
                    let decodedItem = try decoder.decode(GoalItem.self, from: json)

                    // Assert fields match expected values
                    XCTAssertEqual(decodedItem.id, UUID(uuidString: "6C98E2A3-8F5F-48D7-B104-CDA75EAF3B6A"))
                    XCTAssertEqual(decodedItem.name, "Learn Swift")
                    XCTAssertEqual(decodedItem.completed, 0.5)
                    XCTAssertEqual(decodedItem.startDate, ISO8601DateFormatter().date(from: "2025-01-01T00:00:00Z"))
                    XCTAssertEqual(decodedItem.endDate, ISO8601DateFormatter().date(from: "2025-12-31T23:59:59Z"))
                    XCTAssertEqual(decodedItem.url, URL(string: "https://example.com"))
                } catch {
                    XCTFail("Failed to decode JSON: \(error)")
                }
            }
}
