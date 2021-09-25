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

// Utility function to ensure the presence of a dynamic library (or replace the one in the container
// with a newer one).

func ensureLibrary(_ name: String, _ from: String) throws {
    guard let fromURL = URL(string: from + "/" + name) else {
        throw NimbellaError.incorrectInput("arguments '\(name)' and/or '\(from)'")
    }
    // Warning: the following requires the contents of the library to fit in memory
    guard let libData = NSData(contentsOf: fromURL) else {
        throw NimbellaError.couldNotOpen(fromURL.absoluteString)
    }
    let dest = "/usr/local/lib/" + name
    if !libData.write(toFile: dest, atomically: true) {
        throw NimbellaError.couldNotLoadProvider(fromURL.absoluteString)
    }
}
