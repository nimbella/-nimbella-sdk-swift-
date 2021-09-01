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

// Metadata that can be set on a file
public struct SettableFileMetadata {
    public var contentType: String?
    public var cacheControl: String?
}

// Options that may be passed to deleteFiles
public struct DeleteFilesOptions {
    public var force: Bool?
    public var prefix: String?
}

// Options that may be passed to upload
public struct UploadOptions {
    public var destination: String?
    public var gzip: Bool?
    public var metadata: SettableFileMetadata?
}

// Options that may be passed to getFiles
public struct GetFilesOptions {
    public var prefix: String?
}

// Options that may be passed to save
public struct SaveOptions {
    public var metadata: SettableFileMetadata?
}

// Options that may be passed to download
public struct DownloadOptions {
    public var destination: String?
}

// Types used with signed URLs
public enum SignedUrlVersion: String {
    case v2 = "v2"
    case v4 = "v4"
}
public enum SignedUrlAction: String {
    case read = "read"
    case write = "write"
    case delete = "delete"
}

// Options that may be passed to getSignedUrl
public struct SignedUrlOptions {
    public var version: SignedUrlVersion
    public var action: SignedUrlAction
    public var expires: Int
    public var contentType: String?
}

// Options for setting website characteristics
public struct WebsiteOptions {
    public var mainPageSuffix: String?
    public var notFoundPage: String?
}

// Per object (file) metadata
public struct FileMetadata {
    public var name: String
    public var storageClass: String?
    public var size: String
    public var etag: String?
    public var updated: String?
}

// The behaviors required of a file handle (part of storage provider)
public protocol RemoteFile {
    // The name of the file
    var name: String { get }
    // Save data into the file
    func save(_ data: Data, _ options: SaveOptions?) -> EventLoopFuture<Void>
    // Set the file metadata
    func setMetadata(_ meta: SettableFileMetadata) -> EventLoopFuture<Void>
    // Get the file metadata
    func getMetadata() -> EventLoopFuture<FileMetadata>
    // Test whether file exists
    func exists() -> EventLoopFuture<Bool>
    // Delete the file
    func delete() -> EventLoopFuture<Void>
    // Obtain the contents of the file
    func download(_ options: DownloadOptions?) -> EventLoopFuture<Data>
    // Get a signed URL to the file
    func getSignedUrl(_ options: SignedUrlOptions) -> EventLoopFuture<String>
    // Get the underlying implementation for provider-dependent operations
    func getImplementation() -> Any?
}

// The behaviors required of a storage client (part of storage provider)
public protocol StorageClient {
    // Get the root URL if the client is for web storage (return falsey for data storage)
    func getURL() -> String?
    // Set website information
    func setWebsite(_ website: WebsiteOptions) -> EventLoopFuture<Void>
    // Delete files from the store
    func deleteFiles(_ options: DeleteFilesOptions?) -> EventLoopFuture<[String]>
    // Add a local file (specified by path)
    func upload(_ path: String, _ options: UploadOptions?) -> EventLoopFuture<Void>
    // Obtain a file handle in the store.  The file may or may not exist.  This operation is purely local.
    func file(_ destination: String) -> RemoteFile
    // Get files from the store
    func getFiles(_ options: GetFilesOptions?) -> EventLoopFuture<[RemoteFile]>
    // Get the underlying implementation for provider-dependent operations
    func getImplementation() -> Any?
}

// The top-level signature of a storage provider
public protocol StorageProvider {
    // Provide the appropriate client handle for accessing a type file store (web or data) in a particular namespace
    func getClient(_ namespace: String, _ apiHost: String, _ web: Bool, _ credentials: NSDictionary) throws -> StorageClient
    // Convert an object containing credentials as stored in couchdb into the proper form for the credential store
    // Except for GCS, which is grandfathered as the default, the result must include a 'provider' field denoting
    // a valid npm-installable package
    func prepareCredentials(_ original: NSDictionary) throws -> NSDictionary
    // Unique identifier for this storage provider, e.g. @nimbella/storage-provider.
    // Used by factory function to perform dynamic lookups for provider impl at runtime.
    var identifier: String { get }
}

let s3StorageProvider: StorageProvider = S3Provider()
let gcsStorageProvider: StorageProvider = GCSProvider()

let providers = Dictionary<String, StorageProvider>(uniqueKeysWithValues: [
    (s3StorageProvider.identifier, s3StorageProvider),
    (gcsStorageProvider.identifier, gcsStorageProvider)
])

// Obtain the storage provider for a given provider string
public func getStorageProvider(_ provider: String) throws -> StorageProvider {
    guard let provider = providers[provider] else {
        throw NimbellaObjectError.noSuchStorageProvider(provider)
    }
    return provider
}
