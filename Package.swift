// swift-tools-version:5.3
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

import PackageDescription

let package = Package(
    name: "nimbella-sdk",
    platforms: [.iOS("13.0"), .macOS("10.15")],
    products: [
        .library(name: "nimbella-sdk", targets: ["nimbella-sdk"])
    ],
    dependencies: [
        .package(url: "https://gitlab.com/mordil/RediStack.git", .branch("master")),
        .package(url: "https://github.com/swiftpackages/DotEnv.git", from: "2.0.0"),
        .package(url: "https://github.com/soto-project/soto.git", from: "5.0.0")
    ],
    targets: [
        .target(name: "nimbella-sdk", dependencies: ["RediStack",
          .product(name: "SotoS3", package: "soto") ]),
        .testTarget(name: "nimbella-sdk-tests", dependencies: ["nimbella-sdk", "DotEnv"])
    ]
)
