/**
 * Copyright (c) 2021-present, Joshua Auerbach
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import NIOCore

// The interface to key-value services.  Based on the redis implementation but
// avoids using redis-specific types.  To access the RediStack client handle
// (type RedisClient) call getImplementation() and cast the value to RedisClient.
// This requires importing RediStack which the simplified interface does not.
public protocol KeyValueClient {
    func del(_ keys: [String]) -> EventLoopFuture<Int>
    func expire(_ key: String, _ ttl: Int) -> EventLoopFuture<Int>
    func get(_ key: String) -> EventLoopFuture<String?>
    func scan(_ cursor: Int, _ matching: String?, _ count: Int?) -> EventLoopFuture<(Int, [String])>
    func llen(_ key: String) -> EventLoopFuture<Int>
    func lpush(_ key: String, _ value: String) -> EventLoopFuture<Int>
    func lrange(_ key: String, _ start: Int, _ stop: Int) -> EventLoopFuture<[String]>
    func rpush(_ key: String, _ value: String) -> EventLoopFuture<Int>
    func set(_ key: String, _ value: String) -> EventLoopFuture<Void>
    func ttl(_ key: String) -> EventLoopFuture<Int>
    func getImplementation() -> Any?
}

// Store a pointer to the one true KeyValueClient instance, dynamically loaded
var clientHandle: KeyValueClient? = nil

// This class is used to aid in dynamic loading and instantiation of the one (redis) key-value provider
open class KVProviderMaker {
    public init() {}
    open func make() throws -> KeyValueClient {
        throw NimbellaError.notImplemented("KVProviderMaker")
    }
}
// Obtain the KeyValueClient implementation, dynamically loading it if necessary
typealias KVProviderStub = @convention(c) () -> UnsafeMutableRawPointer
public func keyValueClient() throws -> KeyValueClient {
    print("keyValueClient called")
    if let handle = clientHandle {
        print("keyValueClient fouhd client handle already loaded")
        return handle
    }
    let env = ProcessInfo.processInfo.environment
    let prefix = env["NIMBELLA_SDK_PREFIX"] ?? "/usr/local/lib"
    let suffix = env["NIMBELLA_SDK_SUFFIX"] ?? ".so"
    let path = "\(prefix)/libnimbella-redis\(suffix)"
    if let modHandle = dlopen(path, RTLD_NOW|RTLD_LOCAL) {
        print("\(path) was successfully opened")
        defer {
            dlclose(modHandle)
        }
        if let rawProvider = dlsym(modHandle, "loadProvider") {
            print("'loadProvider' symbol resolved")
            let providerStub = unsafeBitCast(rawProvider, to: KVProviderStub.self)
            print("symbol pointer cast (unsafely) to KVProviderStub")
            let opaquePointer = providerStub()
            print("providerStub() was called, returning an opaque pointer")
            let clientMaker =  Unmanaged<KVProviderMaker>.fromOpaque(opaquePointer).takeRetainedValue()
            print("opaque pointer cast to a KVProviderMaker")
            print(String(describing: clientMaker))
            let client = try clientMaker.make()
            print("called 'make' function to get the actual client handle")
            clientHandle = client
            print("client handle stored for next time")
            return client
        }
    }
    throw NimbellaError.couldNotLoadProvider(String(format: "%s", dlerror()))
}
