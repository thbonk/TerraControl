import XCTest
@testable import TerraControl

final class TerraControlTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(TerraControl().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
