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

// The primary entry point to the Nimbella SDK.  Has 'redis' and 'storageClient
// functions as in other SDKs.

import RediStack
import Foundation
import NIO

// Errors that can occur.
public enum NimbellaError : Error {
    case notImplemented
    case noKeyValueStore
    // TODO add storage related errors
}

// Retrieve a redis client handle
public func redis() throws -> RedisClient {
    let env = ProcessInfo.processInfo.environment
    let redisHost = env["__NIM_REDIS_IP"]
    if redisHost == nil || redisHost?.count == 0 {
        throw NimbellaError.noKeyValueStore
    }
    let redisPassword = env["__NIM_REDIS_PASSWORD"]
    if (redisPassword == nil || redisPassword?.count == 0) {
        throw NimbellaError.noKeyValueStore
    }
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let eventLoop = eventLoopGroup.next()
    let client = try RedisConnection.make(
        configuration: try .init(hostname: redisHost!, port: 6379, password: redisPassword),
        boundEventLoop: eventLoop).wait()
    return client
}

// Retrieve a storageClient handle
public func storageClient(_ web: Bool) throws -> StorageClient {
    throw NimbellaError.notImplemented
}
