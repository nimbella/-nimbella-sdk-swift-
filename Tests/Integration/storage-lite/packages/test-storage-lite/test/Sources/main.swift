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

import nimbella_object

func main(args: [String:Any]) -> [String:Any] {
    do {
        // Initial tests assume that the web bucket contains the expected 404.html
        var client = try storageClient(true)
        let url = client.getURL()
        if (url == nil) {
            return [ "error": "URL not found for web bucket" ]
				}
        var file = client.file("404.html")
        let result = try file.getMetadata().wait()
        if (result.name != "404.html") {
            return [ "error":  "Expected file metadata for 404.html but got \(result)" ]
				}
        var contents = String(decoding: try file.download(nil).wait(), as: UTF8.self)
        if (!contents.contains("Nimbella")) {
            return [ "error":  "contents of 404.html were not as expected" ]
				}
        // Switch to data bucket for some other tests
        client = try storageClient(false)
        let testData = "this is a test"
        file = client.file("testfile")
        try file.save(Data(testData.utf8), nil).wait()
        contents = String(decoding: try file.download(nil).wait(), as: UTF8.self)
        if (contents != testData) {
            return [ "error":  "contents of 'testfile' did not equal '\(testData)'" ]
				}
        try file.delete().wait()
        let exists = try file.exists().wait()
        if (exists) {
					 return [ "error": "file was not deleted as expected" ]
				}
    } catch {
        return [ "error": "\(error)"]
    }
    return [ "success": true ]
}
