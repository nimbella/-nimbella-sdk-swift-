import nimbella_sdk
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

    // The storage test runs on whatever namespace is current.  To test both S3 and GCS you need to run it twice with
    // different namespaces.
    func testStorage() {
        self.continueAfterFailure = false
        // Requires that `storage.env` be generated using `nim auth env` and placed in your Nimbella directory
        let env = ProcessInfo.processInfo.environment
        let nimbellaDir = env["NIMBELLA_DIR"] ?? "\(env["HOME"]!)/.nimbella"
        let storageEnvFile = "\(nimbellaDir)/storage.env"
        do {
            try DotEnv.load(path: storageEnvFile)
        } catch {
            XCTFail("\(error)")
        }
        do  {
            // Initial tests assume that the web bucket contains the expected 404.html
            var client = try storageClient(true)
            let url = client.getURL()
            XCTAssertNotEqual(url, nil)
            var file = client.file("404.html")
            let result = try file.getMetadata().wait()
            XCTAssertTrue(
                result.name == "404.html",
                "Expected file metadata for 404.html but got \(result)"
            )
            var contents = String(decoding: try file.download(nil).wait(), as: UTF8.self)
            XCTAssertTrue(
                contents.contains("Nimbella"),
                "contents of 404.html were not as expected"
            )
            // Switch to data bucket for some other tests
            client = try storageClient(false)
            let testData = "this is a test"
            file = client.file("testfile")
            try file.save(Data(testData.utf8), nil).wait()
            contents = String(decoding: try file.download(nil).wait(), as: UTF8.self)
            XCTAssertEqual(contents, testData)
            try file.delete().wait()
            let exists = try file.exists().wait()
            XCTAssertFalse(exists)
        } catch {
            XCTFail("\(error)")
        }
    }
}
