# Nimbella SDK for Swift

A Swift library to interact with [`nimbella.com`](https://nimbella.com) services.

As of this writing

- Unit tests will pass for key-value functionality and for object store functionality when provided by S3 on AWS.  
	- Support for object stores on GCP will be added in the future.   
	- These tests must be run on a mac.
- There is an incomplete integration test for key-value.  Development is currently blocked by remote build problems.  The test does not yet run.
- The SDK is not yet functional for its stated purpose due to remote build problems.

## Installation

To be explained systematically once a working integration test is available.  The dependency clause in `Tests/Integration/redis-list/packages/test-redis-lite/test/Package.swift` is probably correct and should give a clue to how it's going to work.

## Usage

Usage instructions for "real world" usage will be provided once a working integration test is available.

To run the unit test

1.  `macOS` 10.15 and `XCode 12` are assumed in the following.  Whether it will work in other environments is unknown at this time.  The ultimate intent is that XCode should not be required if you have Swift 5.4 installed.  You should be able to use any text editor and the `swift` CLI to compile and test.

2.  The unit test for object store requires
    - that your namespace be on an AWS system (if not, the object store test will fail but the key-value one should still succeed)
    - that your `nim` CLI provide the command `nim auth env`.
        - as of version 1.17.0, this was not yet the case.
        - if are adept with building `nim` from scratch and are willing to hand-merge PR 150, you can build your own copy
        - otherwise, assume the object store test will fail; the key-value test should still succeed.
       
3.  To set up for the object store test (assuming you meet the pre-reqs)
```
nim auth env > ~/.nimbella/storage.env
```

4.  To set up for the key-value test

   1. Install `redis` on your machine as [explained here](https://phoenixnap.com/kb/install-redis-on-mac).
   2. Start the `redis` server and enable the `requirepass` option with the canned password (used for local testing only) of `3b37b7`.  
       - Note that by default a local redis instance does not listen on any external ports, so you are not depending on this password to secure your machine.  It's just that Nimbella redis support requires that there be a password and this canned one is used by the test.  You can change it to any desired value in the code of the test if it makes you feel better.

5.  Checkout this repo, then open XCode on the resulting project.  The package manager should incorporate the dependencies of the SDK itself and of the unit tests.

6.  Use `Product -> Build` first to ensure that the SDK is built.

7.  Then use `Product -> Test` to run the unit tests under XCode.

## Notes

The purpose of the SDK is to support key-value storage and object storage for code running in serverless functions ("actions") in the Nimbella stack.  Usage in other contexts is possible but may require understanding limitations that come from the original design point.

To use the code in Nimbella actions, the Swift package manager root directory (containing `Package.swift` and `Sources`) must be deployed using the Nimbella [deployer](https://docs.nimbella.com/deployer-overview), specifying [_remote build_](https://docs.nimbella.com/building#remote-builds).  _Sorry, this is currently failing.  Investigation is ongoing._

#### Key-Value

Key-value storage in Nimbella is provided via `redis` instances.  Redis support is provided via the [`RediStack` client](https://gitlabhttps://github.com/Mordil/RediStack).  The Nimbella SDK adds support for Nimbella's internal authentication conventions.   To use the code outside of a Nimbella action, set the environment variables `__NIM_REDIS_IP` and `__NIM_REDIS_PASSWORD` as in the unit tests of this package.  It is not possible to use the Nimbella client with a redis instance that does not require a password.  In that situation it is more straightforward to use the `RediStack` client directly.

#### Object store

Object store support uses the abstraction declared in `Sources/nimbella-sdk/StorageInterface.swift`.  This is closely based on the similar abstractions used in the `nodejs` and `Python` SDKs.  At present, it only works when the object store is S3.  Attempting to use it with a GCS object store will cause `NimbellaError.notImplemented` to be thrown.   Adding GCS support is a future objective.

## Support

We're always happy to help you with any issues you encounter. You may want to [join our Slack community](https://nimbella-community.slack.com/) to engage with us for a more rapid response.

## License

Apache-2.0. See [LICENSE](LICENSE) to learn more.
