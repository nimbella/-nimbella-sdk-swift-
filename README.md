# Nimbella SDK for Swift

A Swift library to interact with [`nimbella.com`](https://nimbella.com) services.

## Installation

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

Object store support is coming soon.

## Support

We're always happy to help you with any issues you encounter. You may want to [join our Slack community](https://nimbella-community.slack.com/) to engage with us for a more rapid response.

## License

Apache-2.0. See [LICENSE](LICENSE) to learn more.
