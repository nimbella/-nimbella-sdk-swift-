#!/bin/bash
# TEMP do not use default build while we diagnose various problems
set -e
cp sim-build/add-to-sources Sources/_Whisk.swift
cat Sources/main.swift sim-build/append-to-main > tmp.swift
mv tmp.swift Sources/main.swift
echo "Action" > .include
swift build -c release
mv .build/*/release/Action .
