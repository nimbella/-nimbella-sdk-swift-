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

// The visible entry point to the Nimbella SDK for storage.

import Foundation

// Errors that can occur in the Nimbella Storage SDK
public enum NimbellaObjectError : Error, Equatable {
    case notImplemented(String)
    case noObjectStoreCredentials
    case corruptObjectStoreCredentials(String)
    case insufficientEnvironment
    case noValidURL
    case insufficientCredentials
    case notDeleted(String)
    case multiple([NimbellaObjectError])
    case incorrectInput(String)
    case couldNotOpen(String)
    case noSuchStorageProvider(String)
}

// Retrieve a storageClient handle
public func storageClient(_ web: Bool) throws -> StorageClient {
    let env = ProcessInfo.processInfo.environment
    guard let rawCreds = env["__NIM_STORAGE_KEY"], !rawCreds.isEmpty else {
        throw NimbellaObjectError.noObjectStoreCredentials
    }
    guard let namespace = env["__OW_NAMESPACE"], let apiHost = env["__OW_API_HOST"],
          !namespace.isEmpty, !apiHost.isEmpty else {
        throw NimbellaObjectError.insufficientEnvironment
    }
    guard let credsData = rawCreds.data(using: .utf8),
          let parsedCreds = try? JSONSerialization.jsonObject(with: credsData, options: []) as? NSDictionary else {
        throw NimbellaObjectError.corruptObjectStoreCredentials(rawCreds)
    }
    let provider = parsedCreds["provider"] as? String ?? "@nimbella/storage-gcs"
    let providerImpl = try getStorageProvider(provider)
    let creds = try providerImpl.prepareCredentials(parsedCreds)
    return try providerImpl.getClient(namespace, apiHost, web, creds)
}
