import nimbella_sdk
import XCTest
import RediStack

class BasicTests : XCTestCase {
    func testSDK() {
        // Requires local redis instance to be started and use the indicated password
        setenv("__NIM_REDIS_IP", "localhost", 1)
        setenv("__NIM_REDIS_PASSWORD", "3b37b7", 1)
        self.continueAfterFailure = false
        do {
            let redisClient = try redis()
            try redisClient.set("foo", to: "bar").wait()
            let result = try redisClient.get("foo").wait()?.string
            XCTAssertEqual(result, "bar")
            let deleted = try redisClient.delete(["foo"]).wait()
            XCTAssertEqual(deleted, 1)
            let newResult = try redisClient.get("foo").wait()
            XCTAssertEqual(newResult, nil)
        } catch {
            XCTFail("\(error)")
        }
        var thrownError: Error?
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
