/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
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
import nimbella_object
import DotEnv

runThis()
func runThis() {
    do {
        let env = ProcessInfo.processInfo.environment
        let nimbellaDir = env["NIMBELLA_DIR"] ?? "\(env["HOME"]!)/.nimbella"
        let storageEnvFile = "\(nimbellaDir)/swift-sdk-tests.env"
        try DotEnv.load(path: storageEnvFile)
        try ensureLibrary("nimbella-s3") // need for this is temporary
        // Initial tests assume that the web bucket contains the expected 404.html
        let webClient = try storageClient(true)
        let url = webClient.getURL()
        if (url == nil) {
            print("error: URL not found for web bucket")
            return
        }
        print("url retrieved")
        var file = webClient.file("404.html")
        let result = try file.getMetadata().wait()
        if (result.name != "404.html") {
            print("error: Expected file metadata for 404.html but got \(result)")
            return
        }
        print("404.html metadata retrieved")
        var contents = String(decoding: try file.download(nil).wait(), as: UTF8.self)
        if (!contents.contains("Nimbella")) {
            print("error: contents of 404.html were not as expected")
            return
        }
        print("404.html contents retrieved")
        // Switch to data bucket for some other tests
        let dataClient = try storageClient(false)
        print("Switched to data bucket")
        let testData = "this is a test"
        file = dataClient.file("testfile")
        try file.save(Data(testData.utf8), nil).wait()
        print("Uploaded to testfile")
        contents = String(decoding: try file.download(nil).wait(), as: UTF8.self)
        if (contents != testData) {
            print("error:  contents of 'testfile' did not equal '\(testData)'")
            return
        }
        print("Downloaded and verified testfile contents")
        try file.delete().wait()
        print("Deleted testfile")
        let exists = try file.exists().wait()
        if (exists) {
            print("error: file was not deleted as expected")
            return
        }
    } catch {
        print("error: \(error)")
        return
    }
    print("Success")
}
