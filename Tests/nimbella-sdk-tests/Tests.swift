import nimbella_sdk
import XCTest

class BasicTests : XCTestCase {
    func testUnimplementedFunctions() {
        var thrownError: Error?
        XCTAssertThrowsError(try redis()) {
            thrownError = $0
        }
        XCTAssertTrue(
          thrownError is NimbellaError,
          "Error is not NimbellaError"
        )
        XCTAssertEqual(thrownError as? NimbellaError, .notImplemented)
        XCTAssertThrowsError(try storageClient(false)) {
            thrownError = $0
        }
        XCTAssertTrue(
          thrownError is NimbellaError,
          "Error is not NimbellaError"
        )
        XCTAssertEqual(thrownError as? NimbellaError, .notImplemented)
    }
}
