#!/usr/bin/env python3
"""Fail the build if the compiler reported warnings in our own code.

Reads the build results of an .xcresult bundle, prints each warning as a
GitHub annotation, writes a short summary and exits 1 if any were found.
Warnings from third-party Swift packages are ignored.
"""
import json
import os
import subprocess
import sys
from urllib.parse import unquote, urlparse

bundle = sys.argv[1]
results = json.loads(subprocess.check_output(
    ["xcrun", "xcresulttool", "get", "build-results", "--path", bundle]
))

workspace = os.environ.get("GITHUB_WORKSPACE", os.getcwd()).rstrip("/") + "/"
warnings = []
for warning in results.get("warnings", []):
    url = warning.get("sourceURL", "")
    if "/SourcePackages/" in url:
        continue
    parsed = urlparse(url)
    path = unquote(parsed.path).removeprefix(workspace)
    location = dict(p.split("=", 1) for p in parsed.fragment.split("&") if "=" in p)
    line = location.get("StartingLineNumber", "0")
    warnings.append((path, int(line) + 1 if line.isdigit() else 1, warning["message"]))

for path, line, message in warnings:
    print(f"::warning file={path},line={line}::{message}")

summary = os.environ.get("GITHUB_STEP_SUMMARY")
if summary:
    with open(summary, "a") as out:
        out.write(f"### Compiler warnings: {len(warnings)}\n\n")
        for path, line, message in warnings:
            out.write(f"- `{path}:{line}` {message}\n")

if warnings:
    print(f"::error::{len(warnings)} compiler warning(s) in our code")
    sys.exit(1)
print("No compiler warnings")
