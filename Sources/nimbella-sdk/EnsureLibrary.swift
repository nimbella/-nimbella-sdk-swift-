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

public func ensureLibrary(_ name: String, _ from: String) throws {
    guard let fromURL = URL(string: from + "/" + name) else {
        throw NimbellaError.incorrectInput("args '\(name)' and/or '\(from)'")
    }
    var err: Error? = nil
    let sem = DispatchSemaphore.init(value: 0)
    let downloadTask = URLSession.shared.downloadTask(with: fromURL) {
        u, r, e in
        defer { sem.signal() }
        err = e
        if e != nil {
            return
        }
        guard let fileURL = u, let response = r as? HTTPURLResponse,
              response.statusCode >= 200, response.statusCode <= 299 else {
            err = NimbellaError.couldNotLoadProvider(fromURL.absoluteString)
            return
        }
        let savedURL = URL(fileURLWithPath: "/usr/local/lib/" + name)
        try? FileManager.default.removeItem(at: savedURL)
        do {
            var attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            attributes[.posixPermissions] = NSNumber(0o777)
            try FileManager.default.setAttributes(attributes, ofItemAtPath: fileURL.path)
            try FileManager.default.moveItem(at: fileURL, to: savedURL)
        } catch {
            err = error
        }
    }
    downloadTask.resume()
    sem.wait()
    if let toThrow = err {
        throw toThrow
    }
}
