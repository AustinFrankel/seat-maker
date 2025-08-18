import XCTest

final class OnboardingUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testInteractiveTourSkipsAndPersists() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasSeenTutorial", "YES", "-hasCompletedInteractiveOnboarding", "NO"]
        app.launch()

        // Expect overlay to appear and show first step
        let skip = app.buttons["Skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        skip.tap()

        // Relaunch should not show the overlay again
        app.terminate()
        app.launchArguments = ["-hasSeenTutorial", "YES"]
        app.launch()
        XCTAssertFalse(skip.waitForExistence(timeout: 2))
    }

    @MainActor
    func testAnchorsExist() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasSeenTutorial", "YES", "-hasCompletedInteractiveOnboarding", "NO"]
        app.launch()

        // The main buttons should have identifiers
        XCTAssertTrue(app.buttons["btn.getStarted"].exists || app.buttons["btn.managePeople"].exists)
        XCTAssertTrue(app.buttons["btn.tableManager"].exists)
        XCTAssertTrue(app.buttons["btn.share"].exists)
        XCTAssertTrue(app.buttons["btn.settings"].exists)
    }
}


