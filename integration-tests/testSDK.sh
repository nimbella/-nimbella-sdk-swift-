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

# This script runs an individual integration test, specifically
#    testSDK.sh redis-lite
# or
#    testSDK.sh storage-lite

if [ "$1" == "" ]; then
		echo "An argument is required (the project containing the test to be run)"
    exit 1
fi
echo "Starting project deployment (which will remotely build the action)"
if ! nim project deploy $1 --remote-build; then
    echo "Build failed."
    exit 1
fi
echo "Build succeeded.  Invoking the action, which will exercise the SDK."
RESULT=$(nim action invoke test-$1/test | jq -r .success)
if [ "$RESULT" == "true" ]; then
    echo "Test succeeded"
    exit 0
else
    echo "Action invoke did not produce the expected response"
    exit 1
fi

