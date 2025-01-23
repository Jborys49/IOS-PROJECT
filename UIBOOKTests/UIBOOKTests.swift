//
//  UIBOOKTests.swift
//  UIBOOKTests
//
//  Created by IOSLAB on 16/01/2025.
//

import XCTest

final class UIBOOKTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testExistViews() {
        // Launch the app
        let app = XCUIApplication()
        app.launch()
        
        // Define the tab bar buttons
        let TTSTab = app.tabBars.buttons["TTS Tab"]
        let GoalTab = app.tabBars.buttons["Goal Tab"]
        let ReviewTab = app.tabBars.buttons["Review Tab"]
        let ProfileTab = app.tabBars.buttons["Profile Tab"]
        
        // Wait for elements to appear to ensure UI is fully loaded(was fucked by intro)
        XCTAssertTrue(TTSTab.waitForExistence(timeout: 5), "Tab to TTS Book does not exist")
        XCTAssertTrue(GoalTab.waitForExistence(timeout: 5), "Tab to Goals does not exist")
        XCTAssertTrue(ReviewTab.waitForExistence(timeout: 5), "Tab to Reviews does not exist")
        XCTAssertTrue(ProfileTab.waitForExistence(timeout: 5), "Tab to Profile does not exist")
        
        // Optional debug output if test fails
        if !TTSTab.exists || !GoalTab.exists || !ReviewTab.exists || !ProfileTab.exists {
            print("App debug description:")
            print(app.debugDescription)
        }
    }
    

    func testCreateReview(){
        let app = XCUIApplication()
        app.launch()

        let ReviewTab = app.tabBars.buttons["Review Tab"]
        XCTAssertTrue(ReviewTab.waitForExistence(timeout: 5), "Tab to Reviews does not exist")
        ReviewTab.tap()
        //check number of reviews
        //let test=app..count

        app.buttons["Review Add Link"].tap()
        //create review
        let tagText = app.textFields["Review Add Tag Text"]
        tagText.tap()
        tagText.typeText("Fantasy")
        let tagAdd = app.buttons["Review Add Tag Button"]
        tagAdd.tap()
        let descText = app.textFields["Review Add Desc"]
        descText.tap()
        descText.typeText("PLEASE WORK PLEASSE PLEASE PLEASE")
        let nameText = app.textFields["Review Add Name"]
        nameText.tap()
        nameText.typeText("TESTER")
        //save review
        let save = app.buttons["Review Save"]
        save.tap()

        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let books = documents.appendingPathComponent("BookKeepReviews")
        XCTAssertTrue(fileManager.fileExists(atPath:documents.appendingPathComponent("TESTER").path), "Review")
        //chek whether it got added
        //XCTAssertEqual(test+1, filteredItems.count, "The number of items displayed in the ReviewView is incorrect.")
    }
}
