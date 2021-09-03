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
import SotoS3
import NIO

// Compute the actual name of a bucket.  Based on similar code in the nodejs SDK (with appropriate
// translation from TypeScript to Swift).
func computeBucketStorageName(_ apiHost: String, _ namespace: String, _ web: Bool) -> String {
    let deployment = apiHost.replacingOccurrences(of: "https://", with: "").split(separator: ".")[0]
    let bucketName = "\(namespace)-\(deployment)-nimbella-io"
    return web ? bucketName : "data-\(bucketName)"
}

// Compute the URL to use for web access to the bucket (only for web buckets).  Based on similar code in
// the nodejs SDK (with appropriate translation from TypeScript to Swift).
func computeBucketUrl(_ endpoint: String?, _ bucketName: String) -> String? {
    if (endpoint == nil) {
        return nil
    }
    guard let url = URL(string: endpoint!), url.host != nil else {
        return nil
    }
    return "http://\(bucketName).\(url.host!)"
}

struct Credentials {
    let accessKeyId: String?
    let secretAccessKey: String?
    init(_ dict: NSDictionary) {
        self.accessKeyId = dict["accessKeyId"] as? String
        self.secretAccessKey = dict["secretAccessKey"] as? String
    }
}

struct StorageKey {
    let credentials: Credentials
    let region: Region?
    let endpoint: String?
    let weburl: String?
    init(_ dict: NSDictionary) {
        self.credentials = Credentials(dict["credentials"] as? NSDictionary ?? NSDictionary())
        let region = dict["region"] as? String
        self.region = region?.count == 0 ? nil : Region(awsRegionName: region!)
        let endpoint = dict["endpoint"] as? String
        self.endpoint = endpoint?.count == 0 ? nil : endpoint
        self.weburl = dict["weburl"] as? String
    }
}

// The S3RemoteFile definition.  Based on similar code in the nodejs SDK (with appropriate translation from
// TypeScript to Swift).
class S3RemoteFile : RemoteFile {
    let name: String
    private let bucketName: String
    private let client: S3
    private let web: Bool
    private var eventLoop: EventLoop { client.client.httpClient.eventLoopGroup.next() }

    init(_ client: S3, _ bucketName: String, _ fileName: String, _ web: Bool) {
        self.name = fileName
        self.client = client
        self.bucketName = bucketName
        self.web = web
    }

    func save(_ data: Data, _ options: SaveOptions?) -> EventLoopFuture<Void> {
        let ACL: S3.ObjectCannedACL? = self.web ? .publicRead : nil
        let req = S3.PutObjectRequest(
          acl: ACL,
          body: .data(data),
          bucket: self.bucketName,
          cacheControl: options?.metadata?.cacheControl,
          contentType: options?.metadata?.contentType,
          key: self.name
        )
        return self.client.putObject(req).map {
            (result) -> Void in
        }
    }

    func setMetadata(_ meta: SettableFileMetadata) -> EventLoopFuture<Void> {
        let copySource = "\(self.bucketName)/\(self.name)"
        //let { cacheControl: CacheControl, contentType: ContentType } = meta
        let ACL: S3.ObjectCannedACL? = self.web ? .publicRead : nil
        let req = S3.CopyObjectRequest(
            acl: ACL,
            bucket: self.bucketName,
            cacheControl: meta.cacheControl,
            contentType: meta.contentType,
            copySource: copySource,
            key: self.name,
            metadataDirective: S3.MetadataDirective.replace
        )
        return self.client.copyObject(req).map {
            (result) -> Void in
        }
    }

    func getMetadata() -> EventLoopFuture<FileMetadata> {
        let req = S3.HeadObjectRequest(bucket: self.bucketName, key: self.name)
        let response = self.client.headObject(req)
        return response.map {
            (result) -> FileMetadata in
            let lastModDate = ISO8601DateFormatter().string(for: result.lastModified ?? Date(timeIntervalSince1970: 0))
            return FileMetadata(
                name: self.name,
                storageClass: result.storageClass?.rawValue,
                size: String(result.contentLength ?? 0),
                etag: result.eTag,
                updated: lastModDate)
        }
    }

    func exists() -> EventLoopFuture<Bool> {
        let headObjectFuture = getMetadata()
        let maybeError = headObjectFuture.map {_ in
            true
        }
        return maybeError.flatMapError {_ in
            headObjectFuture.eventLoop.makeSucceededFuture(false)
        }
    }

    func delete() -> EventLoopFuture<Void> {
        let req = S3.DeleteObjectRequest(bucket: self.bucketName, key: self.name)
        return self.client.deleteObject(req).map {_ in
        }
    }

    func download(_ options: DownloadOptions?) -> EventLoopFuture<Data> {
        let cmd = S3.GetObjectRequest(bucket: self.bucketName, key: self.name)
        let result = self.client.getObject(cmd)
        return result.flatMap { output in
            var content = output.body?.asData() ?? Data()
            if let dest = options?.destination {
                guard let fh = FileHandle(forWritingAtPath: dest) else {
                    return self.eventLoop.makeFailedFuture(NimbellaObjectError.couldNotOpen(dest))
                }
                fh.write(content)
                try? fh.close()
                content = Data()
            }
            return self.eventLoop.makeSucceededFuture(content)
        }
    }

    func getSignedUrl(_ options: SignedUrlOptions) -> EventLoopFuture<String> {
        if (options.version != .v4) {
            let err = NimbellaObjectError.incorrectInput("Signing version v4 is required for s3")
            return eventLoop.makeFailedFuture(err)
        }
        let region = client.config.region.rawValue
        let url = URL(string: "https://\(self.bucketName).s3.\(region).amazonaws.com/\(self.name)")!
        let method: HTTPMethod
        switch (options.action) {
        case .read:
            method = .GET
        case .write:
            method = .PUT
        case .delete:
            method = .DELETE
        }
        let expiresEpochTime: TimeInterval = Double(options.expires) / 1000.0 // Convert millis to seconds
        let expiresIntervalFromNow = Date(timeIntervalSince1970: expiresEpochTime).timeIntervalSinceNow
        let expiresIn: TimeAmount = .seconds(Int64(expiresIntervalFromNow)) // TimeAmount from now
        return client.signURL(url: url, httpMethod: method, expires: expiresIn).map { url in
            url.absoluteString
        }
    }

    func getImplementation() -> Any? {
        return self.client
    }
}

// The S3Client definition.  Based on similar code in the nodejs SDK (with appropriate translation from
// TypeScript to Swift).
class S3Client : StorageClient {
    private let s3: S3
    private let bucketName: String
    private let url: String?
    private var eventLoop: EventLoop { s3.client.httpClient.eventLoopGroup.next() }
    init(_ s3: S3, _ bucketName: String, _ url: String? = nil) {
        self.s3 = s3
        self.bucketName = bucketName
        self.url = url
    }

    deinit {
        try? self.s3.client.syncShutdown()
    }

    func getURL() -> String? {
        return url
    }

    func getBucketName() -> String {
        return self.bucketName
    }

    func setWebsite(_ website: WebsiteOptions) -> EventLoopFuture<Void> {
        let errDoc = website.notFoundPage == nil ? nil : S3.ErrorDocument(key: website.notFoundPage!)
        let suffix = website.mainPageSuffix == nil ? nil : S3.IndexDocument(suffix: website.mainPageSuffix!)
        let config = S3.WebsiteConfiguration(errorDocument: errDoc, indexDocument: suffix)
        let request = S3.PutBucketWebsiteRequest(bucket: self.bucketName, websiteConfiguration: config)
        return s3.putBucketWebsite(request).map {_ in
        }
    }

    func deleteFiles(_ options: DeleteFilesOptions?) -> EventLoopFuture<[String]> {
        // The multi-object delete takes a list of objects.  So this takes two round trips.
        let listReq = S3.ListObjectsRequest(bucket: self.bucketName, prefix: options?.prefix)
        let listResult = self.s3.listObjects(listReq)
        let deleteResult = listResult.flatMap {
            (listOutput: S3.ListObjectsOutput) -> EventLoopFuture<S3.DeleteObjectsOutput> in
            let contents = listOutput.contents ?? []
            let objects = contents.map {
                S3.ObjectIdentifier(key: $0.key ?? "") // keys actually expected to be present always
            }
            let delete = S3.Delete(objects: objects)
            let deleteReq = S3.DeleteObjectsRequest(bucket: self.bucketName, delete: delete)
            return self.s3.deleteObjects(deleteReq)
        }
        return deleteResult.flatMapThrowing {r in
            let errors = (r.errors ?? []).map { NimbellaObjectError.notDeleted($0.message ?? "unknown reason")}
            let successes = (r.deleted ?? []).map { $0.key ?? "" } // keys actually expected to be present always
            if (errors.count == 0) {
                return successes
            } else {
                let error = NimbellaObjectError.multiple(errors)
                throw error
            }
        }
    }

    func upload(_ path: String, _ options: UploadOptions?) -> EventLoopFuture<Void> {
        let fh = FileHandle(forReadingAtPath: path)
        guard let data = fh?.availableData else {
            return eventLoop.makeFailedFuture(NimbellaObjectError.couldNotOpen(path))
        }
        let key = options?.destination ?? path
        // Set public read iff web bucket
        let ACL = self.url != nil ? S3.ObjectCannedACL.publicRead : nil
        let req = S3.PutObjectRequest(
            acl: ACL,
            body: AWSPayload.data(data),
            bucket: self.bucketName,
            cacheControl: options?.metadata?.cacheControl,
            contentType: options?.metadata?.contentType,
            key: key
        )
        return self.s3.putObject(req).map {_ in
        }
    }

    func file(_ destination: String) -> RemoteFile {
        return S3RemoteFile(s3, bucketName, destination, url != nil)
    }

    func getFiles(_ options: GetFilesOptions?) -> EventLoopFuture<[RemoteFile]> {
        let listReq = S3.ListObjectsRequest(bucket: self.bucketName, prefix: options?.prefix)
        let listResult = self.s3.listObjects(listReq)
        return listResult.map {
            let contents = $0.contents ?? []
            let objects = contents.map {
                $0.key ?? "" // keys actually expected to be present always
            }
            let result = objects.map {
                S3RemoteFile(self.s3, self.bucketName, $0, self.url != nil)
            }
            return result
        }
    }

    func getImplementation() -> Any? {
        return self.s3
    }
}

// The S3Provider definition.  Based on similar code in the nodejs SDK (with appropriate translation from
// TypeScript to Swift).
class S3Provider : StorageProvider {
    func getClient(_ namespace: String, _ apiHost: String, _ web: Bool, _ credentials: NSDictionary) throws ->         StorageClient {
        let storageKey = StorageKey(credentials)
        guard let keyId = storageKey.credentials.accessKeyId,
              let secret = storageKey.credentials.secretAccessKey else {
            throw NimbellaObjectError.insufficientCredentials
        }
        let client = AWSClient(credentialProvider: .static(accessKeyId: keyId, secretAccessKey: secret), httpClientProvider: .createNew)
        let s3 = S3(client: client, region: storageKey.region, endpoint: storageKey.endpoint)
        let bucketName = computeBucketStorageName(apiHost, namespace, web)
        if (web) {
            var url = storageKey.weburl
            if (url == nil) {
                url = computeBucketUrl(storageKey.endpoint, bucketName)
            }
            if (url == nil) {
                throw NimbellaObjectError.noValidURL
            }
          return S3Client(s3, bucketName, url)
        }

        return S3Client(s3, bucketName)
    }

    func prepareCredentials(_ original: NSDictionary) throws -> NSDictionary {
        // For s3 we will arrange to have the stored information be exactly what we need so
        // this function is an identity map
        return original
    }

    var identifier: String = "@nimbella/storage-s3"
}
