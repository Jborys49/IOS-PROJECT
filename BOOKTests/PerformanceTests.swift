import XCTest
import Combine
@testable import BOOK
final class PerformanceTests: XCTestCase {
    var viewModel: BookViewModel!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        viewModel = BookViewModel()
        cancellables = []
    }

    override func tearDown() {
        viewModel = nil
        cancellables = nil
        super.tearDown()
    }

    func testSearchBooksPerformance() {
        // Set up the expectation for the async operation
        let expectation = self.expectation(description: "SearchBooks should complete within reasonable time")
        viewModel.searchText = "Frankenstein"

        // Start the performance measurement
        self.measure {
            // Trigger the searchBooks method
            viewModel.searchBooks()

            // Wait for the books to be updated
            viewModel.$books
                .dropFirst() // Ignore the initial empty array
                .sink { books in
                    if !books.isEmpty {
                        expectation.fulfill() // Fulfill the expectation when books are updated
                    }
                }
                .store(in: &cancellables)

            // Wait up to 15 seconds for the operation to complete
            wait(for: [expectation], timeout: 30.0)
        }
    }

    func testApiSpeed() {
       //let expectation = self.expectation(description:"api load in reasonable side")
        viewModel.searchText = "Pride and Prejudice"

        // Expectation for asynchronous operation
        let expectation = self.expectation(description: "api should return in reasonable time")

        // Call the searchBooks method
        viewModel.searchBooks()

        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { // Provide a buffer for network call
            XCTAssertFalse(self.viewModel.books.isEmpty, "Books array should not be empty for valid search text.")
            //XCTAssertFalse(self.viewModel.isLoading, "isLoading should be set to false after fetching data.")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testProfileDetailsTime(){
        let expectation = self.expectation(description:"profile data loads in reasonable time")

        let tester = ProfileView()
        let startTime = Date()

        DispatchQueue.main.asyncAfter(deadline: .now() + 20.0){
            tester.loadProfileData()
            let elapsedTime = Date().timeIntervalSince(startTime)
            XCTAssert(elapsedTime<10,"Load too long")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}
