# Nimbella SDK for Swift

A Swift library to interact with [`nimbella.com`](https://nimbella.com) services.  

To better manage binary size, the SDK is provided as a Swift _package_ (`nimbella-sdk`) with two library _products_ (`nimbella-key-value` and `nimbella-object`).  The latter library is implemented for S3 on AWS.  Support for object stores on GCP is a future objective.

As of this writing
- The key-value library (by itself) can be used to produce binaries of acceptable size.  The action can use key-value storage but not object storage.
- The object library (whether by itself or in combination with the key-value library) will result in a binary that is too large to be installed as an action.  This problem is being worked on.
- Building the Swift binary action is somewhat painful because there are problems with remote build in the Swift runtime.   These are being investigated.  The current workaround build procedure is documented below.

There are unit tests and integration tests for both library components.
- Unit tests will pass for key-value functionality and for object store functionality when provided by S3 on AWS.  
  - These tests must be run on a mac.
- The integration test for key-value passes.  It requires the workaround build procedure as documented below.
- The integration test for object store builds (using the workaround procedure) but the resulting binary is slightly too large to install as an action.  It is likely to pass once it can be installed since the code is similar to code that passes in the unit test.

## Installation and usage

The SDK is not installed per se.   Rather, you declare the desired library or libraries as illustrated in the two integration tests (`Tests/Integration/redis-lite` and `Tests/Integration/storage-lite`).   The `Package.swift` file shows the syntax for denoting the package and products.  The `import` statement for the component modules are illustrated in the `main.swift` files.

## Running the Unit Tests

1.  `macOS` 10.15 and `XCode 12` are assumed in the following.  Whether it will work in other environments is unknown at this time.  The ultimate intent is that XCode should not be required if you have Swift 5.4 installed.  You should be able to use any text editor and the `swift` CLI to compile and test.

2.  The unit test for object store requires
    - that your namespace be on an AWS system (if not, the object store test will fail but the key-value one should still succeed)
    - that your `nim` CLI provide the command `nim auth env`.
      - as of version 1.17.0, this was not yet the case but the code is actually merged in the repo (just not released)
      - if you are willing to build `nim` from scratch
        - clone its repo (https://github.com/nimbella/nimbella-cli.git)
        - build it according to the provided instructions and install it temporarily
        - use it to execute `nim auth env` in next step
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

## Alternative build procedure

This procedure should only be in effect until we resolve problems with remote build in the Swift runtime.  It requires that `docker` be installed locally.  The first step is to build the runtime image `action-swift-v5.4`.  It should only be necessary to do this one time.  Then, to run the integration tests use the scripts in `Tests/Integration`, which employ `docker` to build and install the test actions.

### Building a local copy of `action-swift-v5.4` (one time)

1.  Clone the repo https://github.com/joshuaauerbach/openwhisk-runtime-swift.
    - this code is the subject of a PR should eventually be in the upstream repo in `nimbella-corp`.
3.  Checkout the `dev` branch.
4.  In the root of the working tree run `./gradlew core:swift54Action:distDocker`
5.  Using `docker image ls` or a similar command check that you now have a copy of `action-swift-v5.4`.

### Building an image to install the integration tests

In the `Tests/Integration` directory run `./buildImage.sh`.   This should create the image `swift-sdk-tests`.  The image is based on the `action-swift-v5.4` image but incorporates the integration test projects and your Nimbella credentials.

### Installing an integration test

There are two integration tests.  
1.  To install the key-value one, run `./installAction.sh redis-lite`.   This should work.  
2.  You can also do `./installAction.sh storage-lite`.   It will get through the build step but will fail the install because the action is too large.

### Running the integration test

To run the key-value integration test, `nim action invoke test-redis-lite/test`.  You should get a success return.   The object integration test could be run in a similar way once it installs.

### Building your own actions

It should be possible to build your own actions using the `nimbella-key-value` library.  Use the integration test (code and scripts) as a model and adapt them as needed.

## Support

We're always happy to help you with any issues you encounter. You may want to [join our Slack community](https://nimbella-community.slack.com/) to engage with us for a more rapid response.

## License

Apache-2.0. See [LICENSE](LICENSE) to learn more.
