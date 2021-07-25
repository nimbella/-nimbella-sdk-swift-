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
public protocol SettableFileMetadata {
    var contentType: String? { get set }
    var cacheControl: String? { get set }
}

// Options that may be passed to deleteFiles
public protocol DeleteFilesOptions {
    var force: Bool? { get set }
    var prefix: String? { get set }
}

// Options that may be passed to upload
public protocol UploadOptions {
    var destination: String? { get set }
    var gzip: Bool? { get set }
    var metadata: SettableFileMetadata? { get set }
}

// Options that may be passed to getFiles
public protocol GetFilesOptions {
    var prefix: String? { get set }
}

// Options that may be passed to save
public protocol SaveOptions {
    var metadata: SettableFileMetadata? { get set }
}

// Options that may be passed to download
public protocol DownloadOptions {
    var destination: String? { get set }
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
public protocol SignedUrlOptions {
    var version: SignedUrlVersion { get set }
    var action: SignedUrlAction { get set }
    var expires: Int { get set }
    var contentType: String? { get set }
}

// Options for setting website characteristics
public protocol WebsiteOptions {
    var mainPageSuffix: String? { get set }
    var notFoundPage: String? { get set }
}

// Per object (file) metadata
public protocol FileMetadata {
    var name: String { get set }
    var storageClass: String? { get set }
    var size: String { get set }
    var etag: String? { get set }
    var updated: String? { get set }
}

// The behaviors required of a file handle (part of storage provider)
public protocol RemoteFile {
    // The name of the file
    var name: String { get }
    // Save data into the file
    func save(data: Data, options: SaveOptions) -> EventLoopFuture<Void>
    // Set the file metadata
    func setMetadata(meta: SettableFileMetadata) -> EventLoopFuture<Void>
    // Get the file metadata
    func getMetadata() -> EventLoopFuture<FileMetadata>
    // Test whether file exists
    func exists() -> EventLoopFuture<Bool>
    // Delete the file
    func delete() -> EventLoopFuture<Void>
    // Obtain the contents of the file
    func download(options: DownloadOptions?) -> EventLoopFuture<Data>
    // Get a signed URL to the file
    func getSignedUrl(options: SignedUrlOptions) -> EventLoopFuture<String>
    // Get the underlying implementation for provider-dependent operations
    func getImplementation() -> AnyObject
}

// The behaviors required of a storage client (part of storage provider)
public protocol StorageClient {
    // Get the root URL if the client is for web storage (return falsey for data storage)
    func getURL() -> String
    // Set website information
    func setWebsite(website: WebsiteOptions) -> EventLoopFuture<Void>
    // Delete files from the store
    func deleteFiles(options: DeleteFilesOptions?) -> EventLoopFuture<Void>
    // Add a local file (specified by path)
    func upload(path: String, options: UploadOptions?) -> EventLoopFuture<Void>
    // Obtain a file handle in the store.  The file may or may not exist
    func file(destination: String) -> RemoteFile
    // Get files from the store
    func getFiles(options: GetFilesOptions?) -> EventLoopFuture<[RemoteFile]>
    // Get the underlying implementation for provider-dependent operations
    func getImplementation() -> AnyObject
}

// The top-level signature of a storage provider
public protocol StorageProvider {
    // Provide the appropriate client handle for accessing a type file store (web or data) in a particular namespace
    func getClient(_ namespace: String, _ apiHost: String, _ web: Bool, _ credentials: NSDictionary) -> StorageClient
    // Convert an object containing credentials as stored in couchdb into the proper form for the credential store
    // Except for GCS, which is grandfathered as the default, the result must include a 'provider' field denoting
    // a valid npm-installable package
    func prepareCredentials(_ original: NSDictionary) -> NSDictionary
    // Unique identifier for this storage provider, e.g. @nimbella/storage-provider.
    // Used by factory function to perform dynamic lookups for provider impl at runtime.
    var identifier: String { get }
}

// Obtain the storage provide for a given provider string
public func getStorageProvider(_ provider: String) throws -> StorageProvider {
    throw NimbellaError.notImplemented
}
