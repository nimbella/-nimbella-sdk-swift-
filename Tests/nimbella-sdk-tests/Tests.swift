import nimbella_key_value
import XCTest
import RediStack
import DotEnv

class BasicTests : XCTestCase {

    func testRedis() {
        self.continueAfterFailure = false
        // Requires local redis instance to be started and use the indicated password
        setenv("__NIM_REDIS_IP", "localhost", 1)
        setenv("__NIM_REDIS_PASSWORD", "3b37b7", 1)
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
    }
}
