import nimbella_object
import nimbella_key_value
import XCTest
import DotEnv

class BasicTests : XCTestCase {
    override class func setUp() {
        let env = ProcessInfo.processInfo.environment
        let nimbellaDir = env["NIMBELLA_DIR"] ?? "\(env["HOME"]!)/.nimbella"
        let storageEnvFile = "\(nimbellaDir)/swift-sdk-tests.env"
        do {
            try DotEnv.load(path: storageEnvFile)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testRedis() {
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
    }

    // The storage test runs on whatever namespace is current.  To test both S3 and GCS you need to run it twice with
    // different namespaces.
    func testStorage() {
        self.continueAfterFailure = false
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

    // Rename this test to run it.  It is potentially destructive since it operates on /usr/local/lib.
    func testEnsureLibrary() {
        try? FileManager.default.removeItem(atPath: "/usr/local/lib/libnimbella-gcs.so")
        try? FileManager.default.removeItem(atPath: "/usr/local/lib/libnimbella-s3.so")
        try? FileManager.default.removeItem(atPath: "/usr/local/lib/libnimbella-redis.so")
        XCTAssert(!FileManager.default.fileExists(atPath: "/usr/local/lib/libnimbella-gcs.so"))
        XCTAssert(!FileManager.default.fileExists(atPath: "/usr/local/lib/libnimbella-s3.so"))
        XCTAssert(!FileManager.default.fileExists(atPath: "/usr/local/lib/libnimbella-redis.so"))
        do {
            try ensureLibrary("nimbella-gcs")
            try ensureLibrary("nimbella-s3")
            try ensureLibrary("nimbella-redis")
        } catch {
            XCTFail("\(error)")
        }
        XCTAssert(FileManager.default.fileExists(atPath: "/usr/local/lib/libnimbella-gcs.so"))
        XCTAssert(FileManager.default.fileExists(atPath: "/usr/local/lib/libnimbella-s3.so"))
        XCTAssert(FileManager.default.fileExists(atPath: "/usr/local/lib/libnimbella-redis.so"))
    }
}
