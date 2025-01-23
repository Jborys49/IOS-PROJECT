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

    func testApiSpeed() {
       //let expectation = self.expectation(description:"api load in reasonable side")
        viewModel.searchText = "Pride and Prejudice"

        
        let expectation = self.expectation(description: "api should return in reasonable time")

        
        viewModel.searchBooks()

        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { // Provide a buffer for network call
            XCTAssertFalse(self.viewModel.books.isEmpty, "Books array should not be empty for valid search text.")
            //XCTAssertFalse(self.viewModel.isLoading, "isLoading should be set to false after fetching data.")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testProfileDetailsTime() throws{
        let profileView = ProfileView()

        
        measure(metrics: [XCTClockMetric()]) {
            // Perform data loading
            let expectation = XCTestExpectation(description: "Profile data should load within 10 seconds")

            DispatchQueue.global(qos: .userInitiated).async {
                profileView.loadProfileData()
                expectation.fulfill()
            }

            // Wait for the expectation to be fulfilled or timeout after 10 seconds
            wait(for: [expectation], timeout: 10.0)
        }
    }
}
