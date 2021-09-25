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

// Errors that can occur in the Nimbella SDK
public enum NimbellaError : Error, Equatable {
    case notImplemented(String)
    case noKeyValueStore
    case couldNotLoadProvider(String)
    case noObjectStoreCredentials
    case corruptObjectStoreCredentials(String)
    case insufficientEnvironment
    case noValidURL
    case insufficientCredentials
    case notDeleted(String)
    case multiple([NimbellaError])
    case incorrectInput(String)
    case couldNotOpen(String)
    case noSuchStorageProvider(String)
}

