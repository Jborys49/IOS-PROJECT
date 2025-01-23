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
        let expectation = self.expectation(description: "SearchBooks should complete within 15 seconds")
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
            wait(for: [expectation], timeout: 15.0)
        }
    }

    func testApiSpeed() {
       let expectation = self.expectation(description:"api load in reasonable side")
        var viewModel = BookViewModel()
        viewModel.searchText = "Pride and prejudice"

        let startTime = Date()
        viewModel.searchBooks()
        DispatchQueue.main.asyncAfter(deadline: .now() + 60.0){
        let elapsedTime = Date().timeIntervalSince(startTime)
        XCTAssert(elapsedTime<120,"Load too long")
        XCTAssert(viewModel.books.isEmpty, "API Books not updated")
        expectation.fulfill()
        }

        wait(for: [expectation],timeout: 60)
    }

    func testProfileDetailsTime(){
        let expectation = self.expectation(description:"profile data loads in reasonable time")

        let tester = ProfileView()
        let startTime = Date()

        tester.loadProfileData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0){
            let elapsedTime = Date().timeIntervalSince(startTime)
            XCTAssert(elapsedTime<10,"Load too long")
            expectation.fulfill()
        }
        wait(for: [expectation],timeout: 10)
    }
}
