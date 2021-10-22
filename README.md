# Nimbella SDK for Swift

A Swift library to interact with [`nimbella.com`](https://nimbella.com) services.  

As of this writing, the object store component works only on accounts in an AWS cloud.  Accounts in a Google cloud have only key-value support.

## Instructions for use in Nimbella actions.

To use the SDK you must structure your Swift action code as a [Swift Package Manager](https://swift.org/package-manager) package.   This requires a source file called `Package.swift` and a peer directory called `Sources` in which the actual Swift source of your action will be found.  The main source file of your action must be `main.swift` (you can have additional source files).  The `Package.swift` file should resemble the following.

```swift
import PackageDescription

// The following is temporary until the PR for the Swift SDK is merged. 
let repo = "https://github.com/joshuaauerbachwatson/nimbella-sdk-swift.git"
let branch = "dev"
// After merge:
// let repo = "https://github.com/nimbella/nimbella-sdk-swift.git"
// let branch = "master"

let package = Package(
    name: "Action",
    // The platform designation helps with testing on a laptop.  The actual runtime is Linux and does not need to be declared.
    platforms: [.macOS("10.15")],
    products: [
      .executable(
        name: "Action",
        targets:  ["Action"]
      )
    ],
    dependencies: [
        .package(name: "nimbella-sdk", url: "\(repo)", .branch("\(branch)"))
    ],
    targets: [
      .executableTarget(
        name: "Action",
        // Use either or both of the following, depending on whether you use
        // the object store or key-value libraries or both.
        dependencies: [ .product(name: "nimbella-object", package: "nimbella-sdk"),
                      .product(name: "nimbella-key-value", package: nimbella-sdk")
        ],
        path: ".",
        exclude: [ "build.sh", "sim-build" ]
      )
    ]
)
```
You may have additional dependencies depending on what your action does.

In the code of your action, where you want to use the capabilities of the SDK

```swift
// Use either or both of the following
import nimbella_object
import nimbella_key_value
```

## Building the code

You must build the code using the `swift` command line (outside of XCode).  This will ensure that the dynamic libraries are realized in their expected location.
To run the tests under XCode (recommended) you will build the non-dynamic code a second time.

```
cd /path/to/clone/of/this/repo
cd lib
swift build -c release
```

Afterwards, check in `lib/.build/release` for the libraries `libnimbella-gcs.<suffix>` and `libnimbella-s3.<suffix>`.  On MacOS, the suffix is `.dylib`.  On Linux, it is `.so`.

## Running the Unit Tests

This is verified working on `macOS` 10.15 and on Linux.  I have not used Swift for Windows at all.

If your current namespace is on an AWS system, all unit tests should succeed.  Otherwise, the object store test will fail but the key-value test should succeed.  
### Setting up for testing just key-value

Install `redis` on your machine as [explained here](https://phoenixnap.com/kb/install-redis-on-mac).

Start the `redis` server and enable the `requirepass` option with password of your choosing.
- Even though password protection is not really required for a local `redis` (it does not listen on any external ports), `requirepass` is necessary for the test.
- You can optionally edit the configuration file before starting `redis` but I just set the password manually by running `redis-cli`, then `config set requirepass <your-choice>` then `quit`.

Create the file `~/.nimbella/swift-sdk-tests.env` containing

```
NIMBELLA_SDK_SUFFIX=<suffix>
NIMBELLA_SDK_PREFIX=/path/to/clone/of/this/repo/lib/.build/release
__NIM_REDIS_IP=localhost
__NIM_REDIS_PASSWORD=<your-choice>
```

The suffix is `.so` for Linux and `.dylib` for Mac.  The Linux setting is the default so the entire line may be omitted in that case.  The choice of password here must match what you set up in your local redis.

### Setting up for testing both key-value and object store

Check whether your `nim` CLI provides the command `nim auth env`.
- as of version 1.17.0, this was not yet the case.
- You can install the preview version of `nim` using npm or yarn, globally, from https://preview-apigcp.nimbella.io/nimbella-cli.tgz.
- Or, build and locally install your own `nim` as described in the README in https://github.com/nimbella/nimbella-cli.
- This will become unnecessary when a version later than 1.17.0 is released.

Next, set up `~/.nimbella/swift-sdk-tests.env` as described in the previous section.  Then

```
nim auth env >> ~/.nimbella/swift-sdk-tests.env
```

This adds additional entries to the test-time environment for object store.

### Running the tests using the `swift` CLI

If you have built the dynamic libraries as described earlier using `swift build`, you can run the tests using `swift test`.   Note however, that the test run will include many messages of the form `Class ... is implemented in both ... and ...`.  These are harmless but I don't know how to suppress them.  The messages that matter will be at the end of the run, saying whether the tests succeeded.  It is a somewhat better experience to run the tests under XCode, if you have it.

### Running the tests using Xcode

XCode 12.x is assumed in the following.  I have XCode 12.5.1.

Just open XCode on your clone of this repo (it will be recognized as an XCode project).  The package manager should incorporate the dependencies of the SDK itself and of the unit tests.

Use `Product -> Build` first to ensure that the SDK is built for debug in XCode's preferred location.  This is _in addition_ to building the `lib` folder with `swift build` as described above to ensure that the dynamic libraries are present in the expected place.

Then use `Product -> Test` to run the unit tests under XCode.

## Integration tests

There are two integration tests, one for object store and one for key-value.  Running these tests requires simulating the effects of several other pending PRs in other repositories.  Instructions will be provided when running the tests becomes more feasible.

## Support

We're always happy to help you with any issues you encounter. You may want to [join our Slack community](https://nimbella-community.slack.com/) to engage with us for a more rapid response.

## License

Apache-2.0. See [LICENSE](LICENSE) to learn more.
