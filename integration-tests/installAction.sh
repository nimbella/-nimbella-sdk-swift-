#!/bin/bash
#
# Copyright (c) 2021 - present Joshua Auerbach
#
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.
#

# This script installs a single action, using the docker image created by 'buildImage.sh'.
# See that script for more information.
#
# The 'buildImage.sh' script must previously have been run with the latest versions
# of the test code.
#
# It should not necessary to use this script to build actions: by design, a deployer remote
# build should build them.  However, historically, the builder actions for Swift do not
# run with enough memory to complete successfully.  You can circumvent that by installing your
# own builder actions as described in https://github.com/joshuaauerbachwatson/remoteBuildAction.
# Alternatively, you can continue to use this script.

docker run -it --entrypoint /bin/bash swift-sdk-tests nim project deploy /root/$1 --verbose-build --env /root/.nimbella/swift-sdk-tests.env


