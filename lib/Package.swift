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
    name: "nimbella-libs",
    platforms: [.iOS("13.0"), .macOS("10.15")],
    products: [
        .library(name: "nimbella-s3", type: .dynamic, targets: ["nimbella-s3"]),
        .library(name: "nimbella-gcs", type: .dynamic, targets: ["nimbella-gcs"])
    ],
    dependencies: [
        .package(url: "https://github.com/soto-project/soto.git", from: "5.0.0"),
		.package(name: "nimbella-sdk", path: "..")
    ],
    targets: [
        .target(name: "nimbella-s3", dependencies: [.product(name: "nimbella-object", package: "nimbella-sdk"),
                                                    .product(name: "SotoS3", package: "soto")]),
        .target(name: "nimbella-gcs", dependencies: [.product(name: "nimbella-object", package: "nimbella-sdk")])
        ]
    )
