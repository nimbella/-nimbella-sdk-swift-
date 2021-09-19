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
import nimbella_storage

class GCSProvider : StorageProvider {
    func getClient(_ namespace: String, _ apiHost: String, _ web: Bool, _ credentials: NSDictionary) throws ->         StorageClient {
        throw NimbellaObjectError.notImplemented("getClient")
    }

    func prepareCredentials(_ original: NSDictionary) throws -> NSDictionary {
        throw NimbellaObjectError.notImplemented("PrepareCredentials")
    }

    var identifier: String = "@nimbella/storage-gcs"
}

// Bootstrapping
public final class Maker : ProviderMaker {
    public override func make() -> StorageProvider {
        return GCSProvider()
    }
}

@_cdecl("loadProvider")
public func loadProvider() -> UnsafeMutableRawPointer {
    let maker = Maker()
    return Unmanaged.passRetained(maker).toOpaque()
}
