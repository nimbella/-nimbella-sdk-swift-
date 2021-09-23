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

# This script builds a specialized docker image which in which the "remote" builds for
# the integration tests can be run.  This is a workaround, because actual remote builds
# have been terminating in an abrupt and unexplained failure.
#
# The script and Dockerfile may also be adapted to run builds of non-test actions that
# use the SDK
#
# A docker daemon must be installed an you must have a local action-swift-v5.4 available,
# mirroring to the extent possible what Nimbella is running remotely.

pushd redis-lite/packages/test-redis-lite/test
rm -fr .build Action Package.resolved
popd
pushd storage-lite/packages/test-storage-lite/test
rm -fr .build Action Package.resolved
popd
cp ~/.nimbella/credentials.json .
docker build -t swift-sdk-tests .
rm -f credentials.json
