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
public enum NimbellaError : Error, Equatable {
    case notImplemented
    case noKeyValueStore
    case noObjectStoreCredentials
    case corruptObjectStoreCredentials(String)
    case insufficientEnvironment
}

// Retrieve a redis client handle
public func redis() throws -> RedisClient {
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
    return client
}

// Retrieve a storageClient handle
public func storageClient(_ web: Bool) throws -> StorageClient {
    let env = ProcessInfo.processInfo.environment
    guard let rawCreds = env["__NIM_STORAGE_KEY"], !rawCreds.isEmpty else {
        throw NimbellaError.noObjectStoreCredentials
    }
    guard let namespace = env["__OW_NAMESPACE"], let apiHost = env["__OW_API_HOST"],
          !namespace.isEmpty, !apiHost.isEmpty else {
        throw NimbellaError.insufficientEnvironment
    }
    guard let credsData = rawCreds.data(using: .utf8),
          let parsedCreds = try? JSONSerialization.jsonObject(with: credsData, options: []) as? NSDictionary else {
        throw NimbellaError.corruptObjectStoreCredentials(rawCreds)
    }
    let provider = parsedCreds["provider"] as? String ?? "@nimbella/storage-gcs"
    let providerImpl = try getStorageProvider(provider)
    let creds = providerImpl.prepareCredentials(parsedCreds)
    return providerImpl.getClient(namespace, apiHost, web, creds)
}
