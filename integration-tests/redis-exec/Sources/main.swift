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

import nimbella_key_value
import DotEnv
import Foundation

runThis()
func runThis() {
    do {
        let env = ProcessInfo.processInfo.environment
        let nimbellaDir = env["NIMBELLA_DIR"] ?? "\(env["HOME"]!)/.nimbella"
        let storageEnvFile = "\(nimbellaDir)/swift-sdk-tests.env"
        try DotEnv.load(path: storageEnvFile)
        let redisClient = try redis()
        print("client created")
        try redisClient.set("foo", to: "bar").wait()
        print("foo set to bar")
        let result = try redisClient.get("foo").wait()?.string
        if (result != "bar") {
            print("error: result of get was not 'bar'")
            return
        }
        print("value retrieved successfully")
        let deleted = try redisClient.delete(["foo"]).wait()
        if (deleted != 1) {
            print("error: result of delete was not '1'")
            return
        }
        let newResult = try redisClient.get("foo").wait()
        if (newResult != nil) {
            print("error: delete did not have the desired effect")
            return
        }
    } catch {
        print("error: \(error)")
        return
    }
    print("Success")
}
