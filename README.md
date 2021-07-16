# Nimbella SDK for Swift

A Swift library to interact with [`nimbella.com`](https://nimbella.com) services.

## Installation

_As of this writing, the Nimbella Swift runtime has maximum version 4.2 whereas this SDK requires 5.3.  So, this SDK is not yet operational for its intended purpose.  There is a plan to resolve this.  This package can be installed locally and tested with local redis instances meanwhile._

- `macOS` 10.15 and XCode 12 is assumed in the following.

- In `Package.swift`:

```swift
let package = Package(
    ...
    dependencies: [
       .package(url: "https://github.com/nimbella/nimbella-sdk-swift.git", .branch("master"), name: NimbellaSDK)
       ...
    ],
    ...
)
```
- When XCode is open on the resulting project, the package manager should incorporate the dependency automatically as needed.

- To develop without using XCode, use `swift build`, `swift package` etc. as per Swift Package Manager documentation.

## Usage

```swift
import NimbellaSDK
import RediStack

class ...
    func testRedis() {
        do {
            let redisClient = try redis()
            try redisClient.set("foo", to: "bar").wait()
            ...
            let result = try redisClient.get("foo").wait()?.string
            ...  
            let deleted = try redisClient.delete(["foo"]).wait()
            ...
            let newResult = try redisClient.get("foo").wait()
            ...
        } catch {
            ...
        }
    }
    func testStorage() {
        do {
            let storageClient = try storageClient(false)
        } catch {
            // Currently throws NimbellaError.notImplemented
        }
    }
}
```

You can lightly exercise this functionality using `swift test`.

## Notes

The purpose of the SDK is to support key-value storage and object storage for code running in serverless functions ("actions") in the Nimbella stack.  Usage in other contexts is possible but may require understanding limitations that come from the original design point.

To use the code in Nimbella actions, the Swift package manager root directory (containing `Package.swift` and `Sources`) must be deployed using the Nimbella [deployer](https://docs.nimbella.com/deployer-overview), specifying [_remote build_](https://docs.nimbella.com/building#remote-builds).

#### Key-Value

Key-value storage in Nimbella is provided via `redis` instances.  Redis support is provided via the [`RediStack` client](https://gitlabhttps://github.com/Mordil/RediStack).  The Nimbella SDK adds support for Nimbella's internal authentication conventions.   To use the code outside of a Nimbella action, set the environment variables `__NIM_REDIS_IP` and `__NIM_REDIS_PASSWORD` as in the unit tests of this package.  It is not possible to use the Nimbella client with a redis instance that does not require a password.  In that situation it is more straightforward to use the `RediStack` client directly.

#### Object store

Object store support is not present at this time but the intended interface is present in `StorageInterface.swift`.   Attempting to initiate object store access will cause `NimbellaError.notImplemented` to be thrown.   Adding working object store support is a future objective.

## Support

We're always happy to help you with any issues you encounter. You may want to [join our Slack community](https://nimbella-community.slack.com/) to engage with us for a more rapid response.

## License

Apache-2.0. See [LICENSE](LICENSE) to learn more.
