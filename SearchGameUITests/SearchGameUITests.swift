import XCTest

final class SearchGameUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testAppLaunches() throws {
        // Verify the app launches without crashing
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }
    
    // TODO: Add more UI tests as features are implemented
    // - testPanGesture
    // - testFindAllItems
    // - testLevelComplete
}
