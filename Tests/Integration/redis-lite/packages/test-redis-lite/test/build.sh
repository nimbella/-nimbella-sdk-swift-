#!/bin/bash
# Currently configured to reveal information about the build.  The build will actually fail.
#set -e
cp /swiftAction/Sources/_Whisk.swift Sources
swift build -c release
mv .build/*/release .
