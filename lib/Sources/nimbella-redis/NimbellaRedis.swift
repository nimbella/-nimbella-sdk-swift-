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

// The visible entry point to the Nimbella SDK for redis

import RediStack
import Foundation
import NIO
import nimbella_sdk

// Retrieve a key-value client handle (which wraps a RedisClient, providing a simplified
// but limited interface).
func redis() throws -> RedisWrapper {
    let env = ProcessInfo.processInfo.environment
    guard let redisHost = env["__NIM_REDIS_IP"], !redisHost.isEmpty else {
        throw NimbellaError.noKeyValueStore
    }
    guard let redisPassword = env["__NIM_REDIS_PASSWORD"], !redisPassword.isEmpty else {
        throw NimbellaError.noKeyValueStore
    }
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let eventLoop = eventLoopGroup.next()
    let client = try RedisConnection.make(
        configuration: try .init(hostname: redisHost, port: 6379, password: redisPassword),
        boundEventLoop: eventLoop).wait()
    return RedisWrapper(client)
}

class RedisWrapper : KeyValueClient {
    let client: RedisClient
    init(_ client: RedisClient) {
        self.client = client
    }

    func del(_ keys: [String]) -> EventLoopFuture<Int> {
        return client.delete(keys.map { RedisKey($0) })
    }

    func expire(_ key: String, _ ttl: Int) -> EventLoopFuture<Int> {
        return client.expire(RedisKey(key), after: TimeAmount.seconds(Int64(ttl))).map {$0 ? 1 : 0}
    }

    func get(_ key: String) -> EventLoopFuture<String?> {
        return client.get(RedisKey(key)).map { $0?.string }
    }

    func scan(_ cursor: Int = 0, _ matching: String? = nil, _ count: Int? = nil) -> EventLoopFuture<(Int, [String])> {
        return client.scanKeys(startingFrom: cursor, matching: matching, count: count).map {
            ($0.0, $0.1.map { $0.rawValue })
        }
    }

    func llen(_ key: String) -> EventLoopFuture<Int> {
        return client.send(RedisCommand<Int>.llen(of: RedisKey(key)))
    }

    func lpush(_ key: String, _ value: String) -> EventLoopFuture<Int> {
        return client.send(RedisCommand<Int>.lpush(value, into: RedisKey(key)))
    }

    func lrange(_ key: String, _ start: Int, _ stop: Int) -> EventLoopFuture<[String]> {
        return client.send(RedisCommand<[RESPValue]>.lrange(from: RedisKey(key), firstIndex: start, lastIndex: stop)).map { $0.map { $0.string ?? "" }}
    }

    func rpush(_ key: String, _ value: String) -> EventLoopFuture<Int> {
        return client.send(RedisCommand<Int>.rpush(value, into: RedisKey(key)))
    }

    func set(_ key: String, _ value: String) -> EventLoopFuture<Void> {
        return client.set(RedisKey(key), to: value)
    }

    func ttl(_ key: String) -> EventLoopFuture<Int> {
        return client.send(RedisCommand<Int>.ttl(RedisKey(key))).map { convertToSeconds($0.timeAmount) }
    }

    func getImplementation() -> Any? {
        return client
    }
}

// Utility to convert the NIO TimeAmount abstraction to Int seconds
func convertToSeconds(_ amt: TimeAmount?) -> Int {
    let nanos = amt?.nanoseconds ?? 0
    return Int(nanos / 1000000000)
}

// Bootstrapping

var savedClient: KeyValueClient? = nil
var clientMakingError: Error? = nil
var savedMaker: KVProviderMaker? = nil

public final class Maker : KVProviderMaker {
    public override func make() throws -> KeyValueClient {
        if let err = clientMakingError {
            throw err
        }
        if let client = savedClient {
            return client
        }
        do {
            let client = try redis()
            savedClient = client
            return client
        } catch {
            clientMakingError = error
            throw error
        }
    }
}

@_cdecl("loadProvider")
public func loadProvider() -> UnsafeMutableRawPointer {
    let maker = Maker()
    savedMaker = maker
    do {
        savedClient = try redis()
    } catch {
        clientMakingError = error
    }
    return Unmanaged<KVProviderMaker>.passRetained(maker).toOpaque()
}
