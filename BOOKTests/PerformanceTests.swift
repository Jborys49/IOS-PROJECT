import XCTest
@testable import BOOK
final class PerformanceTests: XCTestCase {
    func testApiSpeed() {
       let expectation = self.expectation(description:"api load in reasonable side")
        var viewModel = BookViewModel()
        viewModel.searchText = "Pride and prejudice"

        let startTime = Date()
        viewModel.searchBooks()
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0){
        let elapsedTime = Date().timeIntervalSince(startTime)
        XCTAssert(elapsedTime<10,"Load too long")
            XCTAssert(viewModel.books.isEmpty, "API Books not updated")
        expectation.fulfill()
        }

        wait(for: [expectation],timeout: 10)
    }

    func testProfileDetailsTime(){
        let expectation = self.expectation(description:"profile data loads in reasonable time")

        let tester = ProfileView()
        let startTime = Date()

        tester.loadProfileData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0){
            let elapsedTime = Date().timeIntervalSince(startTime)
            XCTAssert(elapsedTime<1,"Load too long")
            expectation.fulfill()
        }
        wait(for: [expectation],timeout: 1)
    }
}
