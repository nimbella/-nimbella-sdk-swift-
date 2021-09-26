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
    if env["HOME"] == nil || env["HOME"]?.count == 0 {
        setenv("HOME", "/root", 1)
    }
    let nimBinary = env["NIM"] ?? "/usr/local/bin/nim"
    try ensureCredentials(nimBinary, env)
    let libName = "lib\(name).so"
    try shell("\(nimBinary) web get \(libName)")
    try shell("chmod +x \(libName)")
}

// Make sure that the credentials are there for the current namespace.  In practice, either
// they already are (and the function does nothing) or the code is running inside an action,
// making it possible to bootstrap credentials using 'nim' and the various __OW_* environment
// variables.  If there are no credentials AND the required environment variables are also
// missing, the function throws.
func ensureCredentials(_ nimBinary: String, _ env: [String: String]) throws {
    let creds = try shell("\(nimBinary) auth list")
    if creds.count > 0 {
        return
    }
    guard let apiHost = env["__OW_API_HOST"], let auth = env["__OW_API_KEY"] else {
        throw NimbellaError.insufficientCredentials
    }
    try shell("\(nimBinary) auth login --auth \(auth) --apihost \(apiHost)")
    try shell("\(nimBinary) auth refresh")
}

// Run a shell command in the target directory, throwing on error on non-zero exit.  Adapted from:
// https://stackoverflow.com/questions/26971240/how-do-i-run-a-terminal-command-in-a-swift-script-e-g-xcodebuild
@discardableResult
func shell(_ command: String) throws -> String {
    let task = Process()
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.executableURL = URL(fileURLWithPath: "/bin/bash")
    task.currentDirectoryURL = URL(fileURLWithPath: "/usr/local/lib")
    try task.run()
    task.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""
    if task.terminationStatus != 0 {
        var message = "\(command), rc=\(task.terminationStatus)"
        if output.count > 0 {
            message = "\(message), output=\(output)"
        }
        throw NimbellaError.shellFailed(message)
    }
    return output
}
