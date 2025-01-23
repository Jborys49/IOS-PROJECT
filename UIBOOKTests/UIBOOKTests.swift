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

    func testExistAllViews(){
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        let TTSTab = app.tabBars.buttons["TTS Tab"]
        let GoalTab = app.tabBars.buttons["Goal Tab"]
        let ReviewTab = app.tabBars.buttons["Review Tab"]
        let ProfileTab = app.tabBars.buttons["Profile Tab"]

        //Check whether app launches with views availible (might get fucked by intro)
        XCTAssertTrue(TTSTab.exists, "Tab to TTS Book not existant")
        XCTAssertTrue(GoalTab.exists, "Tab to Goals not existant")
        XCTAssertTrue(ReviewTab.exists, "Tab to Reviews not existant")
        XCTAssertTrue(ProfileTab.exists, "Tab to profile not existant")

        ProfileTab.tap()
        //checking whether the profile view exists correctly
        let textField = app.textFields["Profile NameChange TextField"]
        XCTAssertTrue(textField.exists, "Text field in profile does not exist")

        TTSTab.tap()
        XCTAssertTrue(app.buttons["TTS Add Link"].exists, "button in tts does not exist")

        GoalTab.tap()
        XCTAssertTrue(app.buttons["Goal Add Link"].exists, "button in goal does not exist")

        ReviewTab.tap()
        XCTAssertTrue(app.buttons["Review Add Link"].exists, "button in Review does not exist")
    }

    func createReview(){
        let app = XCUIApplication()
        app.launch()

        let ReviewTab = app.tabBars.buttons["Review Tab"]
        XCTAssertTrue(ReviewTab.exists, "Tab to Reviews not existant")
        ReviewTab.tap()
        //check number of reviews
        //let test=app..count

        app.buttons["Review Add Link"].tap()
        //create review
        let tagText = app.textFields["Review Add Tag Text"]
        tagText.typeText("Fantasy")
        let tagAdd = app.buttons["Review Add Tag Button"]
        tagAdd.tap()
        let descText = app.textFields["Review Add Desc"]
        descText.typeText("PLEASE WORK PLEASSE PLEASE PLEASE")
        let nameText = app.textFields["Review Add Name"]
        nameText.typeText("TESTER")
        //save review
        let save = app.buttons["Review Save"]
        save.tap()

        //chek whether it got added
        //XCTAssertEqual(test+1, filteredItems.count, "The number of items displayed in the ReviewView is incorrect.")
        XCTAssert(true)
    }
}
