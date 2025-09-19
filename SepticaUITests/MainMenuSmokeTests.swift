import XCTest

final class MainMenuSmokeTests: XCTestCase {
    func testMainMenuDisplaysRomanianPlayButton() throws {
        let app = XCUIApplication()
        app.launch()

        let playButton = app.staticTexts["JOACĂ"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 10), "Expected JOACĂ button on main menu")
    }
}
