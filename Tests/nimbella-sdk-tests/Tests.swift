import nimbella_sdk
import XCTest
import RediStack
import DotEnv

class BasicTests : XCTestCase {
    func testSDK() {
        self.continueAfterFailure = false
        // Requires local redis instance to be started and use the indicated password
        setenv("__NIM_REDIS_IP", "localhost", 1)
        setenv("__NIM_REDIS_PASSWORD", "3b37b7", 1)
        // Requires that `storage.env` be generated using `nim auth env` and placed in your Nimbella directory
        let env = ProcessInfo.processInfo.environment
        let nimbellaDir = env["NIMBELLA_DIR"] ?? "\(env["HOME"]!)/.nimbella"
        let storageEnvFile = "\(nimbellaDir)/storage.env"
        do {
            try DotEnv.load(path: storageEnvFile)
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
        let nimbellaError = thrownError as! NimbellaError
        XCTAssertTrue(
            nimbellaError == .notImplemented,
            "\(String(describing: thrownError)) instead of .notImplemented")
    }
}
