#!/bin/bash
# TEMP needed for workaround
set -e
swift build -c release
mv .build/*/release/Action .
