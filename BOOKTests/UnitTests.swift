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
}
