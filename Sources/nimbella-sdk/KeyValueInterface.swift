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
import NIO

// Errors that can occur in the Nimbella Key value SDK
public enum NimbellaKeyValueError : Error, Equatable {
    case notImplemented(String)
    case noKeyValueStore
    case couldNotLoadProvider(String)
}

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
        throw NimbellaKeyValueError.notImplemented("key-value provider")
    }
}

// Obtain the KeyValueClient implementation, dynamically loading it if necessary
typealias KVProviderStub = @convention(c) () -> UnsafeMutableRawPointer
public func keyValueClient() throws -> KeyValueClient {
    if let handle = clientHandle {
        return handle
    }
    let env = ProcessInfo.processInfo.environment
    let prefix = env["NIMBELLA_SDK_PREFIX"] ?? "/usr/local/lib"
    let suffix = env["NIMBELLA_SDK_SUFFIX"] ?? ".so"
    let path = "\(prefix)/libnimbella-redis\(suffix)"
    let modHandle = dlopen(path, RTLD_NOW|RTLD_LOCAL)
    if modHandle != nil {
        defer {
            dlclose(modHandle)
        }
        if let rawProvider = dlsym(modHandle, "loadProvider") {
            let providerStub = unsafeBitCast(rawProvider, to: KVProviderStub.self)
            let client = try Unmanaged<KVProviderMaker>.fromOpaque(providerStub()).takeRetainedValue().make()
            clientHandle = client
            return client
        }
    }
    throw NimbellaKeyValueError.couldNotLoadProvider(String(format: "%s", dlerror()))
}
