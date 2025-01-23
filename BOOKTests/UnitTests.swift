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
            // Load the BookIcon from the assets because if i dont provide a legit image the program shits itself
                guard let bookIconImage = UIImage(named: "BookIcon"),
                      let bookIconData = bookIconImage.pngData() else {
                    XCTFail("Failed to load BookIcon from assets")
                    return
                }

                // Save the image temporarily to create a valid URL
                let tempDirectory = FileManager.default.temporaryDirectory
                let bookIconURL = tempDirectory.appendingPathComponent("BookIcon.png")
                try bookIconData.write(to: bookIconURL)

                // Mock a valid book with the local URL for the cover
                let book = BookAPI(
                    title: "Test Book",
                    author: "Test Author",
                    coverURL: bookIconURL.absoluteString, // Use the local URL as the coverURL
                    textURL: "https://example.com/test_book.txt",
                    description: "Author: Test Author"
                )

                let expectation = self.expectation(description: "Save book should complete successfully")

                // Call saveBook and validate the result
                viewModel.saveBook(book) { savedBook in
                    XCTAssertEqual(savedBook.name, book.title, "Saved book title should match original book title.")
                    XCTAssertEqual(savedBook.description, book.description, "Saved book description should match original book description.")

                    // Verify the saved book's image matches the original asset
                    if let savedImageData = try? Data(contentsOf: savedBook.path.appendingPathComponent("\(book.title).png")),
                       let savedImage = UIImage(data: savedImageData) {
                        XCTAssertEqual(savedImage.pngData(), bookIconData, "Saved book cover image should match the original image.")
                    } else {
                        XCTFail("Failed to verify the saved book cover image")
                    }

                    expectation.fulfill()
                }

                waitForExpectations(timeout: 10, handler: nil)
        }

        func testFileCreator() throws {
         let fileManager = FileManager.default
         let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            AppFileManager.shared.setupDirectoriesAndFiles()
            let folders = ["BookKeepGoals", "BookKeepReviews", "BookKeepTTSBooks","BookKeepProfile"]
            for folder in folders {
                XCTAssertTrue(fileManager.fileExists(atPath:documents.appendingPathComponent(folder).path), "Folder not created")
            }
        }

        func testItemDecoding() throws {
              // Example JSON to test decoding
                      let json = """
                      {
                          "books": [
                              {
                                  "name": "Book One",
                                  "status": true
                              },
                              {
                                  "name": "Book Two",
                                  "status": false
                              }
                          ],
                          "startDate": "2025-01-01T00:00:00Z",
                          "endDate": "2025-12-31T23:59:59Z"
                      }
                      """.data(using: .utf8)!

                      // Expected date format is ISO8601
                      let decoder = JSONDecoder()
                      decoder.dateDecodingStrategy = .iso8601

                      do {
                          // Decode the JSON into ItemDescription
                          let itemDescription = try decoder.decode(ItemDescription.self, from: json)

                          // Assertions to verify the decoded data
                          XCTAssertEqual(itemDescription.books.count, 2)
                          XCTAssertEqual(itemDescription.books[0].name, "Book One")
                          XCTAssertEqual(itemDescription.books[0].status, true)
                          XCTAssertEqual(itemDescription.books[1].name, "Book Two")
                          XCTAssertEqual(itemDescription.books[1].status, false)
                          XCTAssertEqual(itemDescription.startDate, ISO8601DateFormatter().date(from: "2025-01-01T00:00:00Z"))
                          XCTAssertEqual(itemDescription.endDate, ISO8601DateFormatter().date(from: "2025-12-31T23:59:59Z"))
                      } catch {
                          XCTFail("Failed to decode ItemDescription: \(error)")
                      }
        }
}
