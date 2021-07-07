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

// Errors that can occur.
enum NimbellaError : Error {
    case notImplemented
    // TODO
}

// Retrieve a redis client handle
public func redis() throws -> RedisConnection {
    throw NimbellaError.notImplemented
}

// Retrieve a storageClient handlel
public func storageClient(_ web: Bool) throws -> StorageClient {
    throw NimbellaError.notImplemented
}
