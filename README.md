# Nimbella SDK for Swift

A Swift library to interact with [`nimbella.com`](https://nimbella.com) services.  

Currently, only key-value storage (provided by `redis`) is supported by the SDK.  Adding object store support is a future objective.

There is both a unit test (using a local `redis`) and an integration test (using the Nimbella Swift runtime and your personal `redis` in the Nimbella cloud).

There are some issues with diagnosing and reporting developer errors, both in the Nimbella builder actions and the Nimbella Swift runtime.  Related PRs are open to address those issues.  Until they are addressed, you may find that developing for the Swift SDK is a little bit painful unless you are lucky enough to write error-free code.

## Temporary: install alternative builder actions

To use the Swift SDK conveniently, you will want to build your Swift actions using `--remote-build`.  Until Nimbella expands the memory available to builder actions, this will fail.  You can circumvent this by installing your own builder actions from https://github.com/joshuaauerbachwatson/remoteBuildAction as described in the README there.

## Installation and usage

To use the SDK you must structure your Swift code for the Swift Package Manager (with a `Package.swift` and a `Sources` directory containing at least a `main.swift`).   You declare the dependency on the Nimbella SDK in `Package.swift`.

```
import PackageDescription

let repo = "https://github.com/..."
let branch = "..."

let package = Package(
    ...
    dependencies: [
        .package(name: "nimbella-sdk", url: "\(repo)", .branch("\(branch)"))
    ],
    targets: [
      .executableTarget(
        name: "...",
        dependencies: [ .product(name: "nimbella-key-value", package: "nimbella-sdk") ]
      )
    ]
)
```

Note that the example uses symbols for the repository and branch containing the SDK.  In production, set the repository to `https://github.com/nimbella/nimbella-sdk-swift` and the branch to `master`.  Release numbering should follow in the near future.  For testing prior to the merge of this functionality, set these symbols to the fork and branch containing the to-be-merged code.

In your action, wherever you rely on key-value functionality from the SDK, you will need

```
import nimbella_key_value
import RediStack
```

The `RediStack` project provides `redis` support for Swift.  This SDK adds the needed authentication layer for the Nimbella stack.  To get a `RediStack` client handle, use code like the following.

```
let redisClient = try redis() // This can throw; enclose in do/catch or use try?
```

Remaining details are covered by [RediStack documentation](https://docs.redistack.info/index.html).

## Running the Unit Tests

1. `macOS` 10.15 and `XCode 12` are assumed in the following.  Whether it will work in other environments is unknown at this time.  The ultimate intent is that XCode should not be required if you have Swift 5.4 installed.  You should be able to use any text editor and the `swift` CLI to compile and test.

2. To set up for the key-value test
    1. Install `redis` on your machine as [explained here](https://phoenixnap.com/kb/install-redis-on-mac).
    2. Start the `redis` server and enable the `requirepass` option with the canned password (used for local testing only) of `3b37b7`.  
       - Note that by default a local redis instance does not listen on any external ports, so you are not depending on this password to secure your machine.

3.  Checkout this repo, then open XCode on the resulting project.  The package manager should incorporate the dependencies of the SDK itself and of the unit tests.

6.  Use `Product -> Build` first to ensure that the SDK is built.

7.  Then use `Product -> Test` to run the unit tests under XCode.

## Running the integration test

To run the key-value integration test

1.  Checkout this repo, then switch to directory `integration-tests`.
2.  `./testSDK.sh redis-lite`

If you look at the code of the test, it illustrates the API discussed above, but it also includes some workarounds for deficiencies in the Swift runtime.  These should go away when related PRs are merged.

### Building your own actions

It should be possible to build your own actions using the `nimbella-key-value` library.  Use the integration test (code and scripts) as a model and adapt them as needed.

## Support

We're always happy to help you with any issues you encounter. You may want to [join our Slack community](https://nimbella-community.slack.com/) to engage with us for a more rapid response.

## License

Apache-2.0. See [LICENSE](LICENSE) to learn more.
