#!/bin/bash
set -e
swift build -c release
mv .build/*/release/Action .
