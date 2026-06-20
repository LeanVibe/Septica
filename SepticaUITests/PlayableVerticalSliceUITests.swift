import XCTest

final class PlayableVerticalSliceUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("UI_TESTING")
        app.launchArguments.append("--uitesting")
        app.launchEnvironment["UI_TESTING"] = "1"
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testMenuStartsLocalPlayableRound() throws {
        let startGame = element("main-menu-start-game")
        XCTAssertTrue(startGame.waitForExistence(timeout: 5))
        startGame.tap()

        let startLocalGame = element("game-setup-start-local-game")
        XCTAssertTrue(startLocalGame.waitForExistence(timeout: 5))
        startLocalGame.tap()

        XCTAssertTrue(element("game-board").waitForExistence(timeout: 8))

        let firstCard = element("player-card-0")
        XCTAssertTrue(firstCard.waitForExistence(timeout: 5))
        firstCard.tap()

        let playButton = element("play-selected-card")
        XCTAssertTrue(playButton.waitForExistence(timeout: 3))
        XCTAssertTrue(playButton.isEnabled)
        playButton.tap()

        XCTAssertTrue(element("game-board").waitForExistence(timeout: 3))
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }
}
