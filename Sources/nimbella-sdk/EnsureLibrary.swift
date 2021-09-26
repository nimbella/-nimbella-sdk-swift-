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
public func ensureLibrary(_ name: String) throws {
    let env = ProcessInfo.processInfo.environment
    let nimBinary = env["NIM"] ?? "/usr/local/bin/nim"
    if env["HOME"] == nil || env["HOME"]?.count == 0 {
        setenv("HOME", "/root", 1)
    }
    let libName = "lib\(name).so"
    try shell("\(nimBinary) web get \(libName)")
    try shell("chmod +x \(libName)")
}

// Run a shell command in the target directory, throwing on error on non-zero exit.  Adapted from:
// https://stackoverflow.com/questions/26971240/how-do-i-run-a-terminal-command-in-a-swift-script-e-g-xcodebuild
func shell(_ command: String) throws {
    let task = Process()
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.executableURL = URL(fileURLWithPath: "/bin/bash")
    task.currentDirectoryURL = URL(fileURLWithPath: "/usr/local/lib")
    try task.run()
    task.waitUntilExit()
    if task.terminationStatus != 0 {
        var message = "\(command), rc=\(task.terminationStatus)"
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            message = "\(message), output=\(output)"
        }
        throw NimbellaError.shellFailed(message)
    }
}
