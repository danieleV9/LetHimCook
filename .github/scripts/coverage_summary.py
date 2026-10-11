#!/usr/bin/env python3
"""Write the app's code coverage to the GitHub job summary.

Usage: coverage_summary.py <bundle.xcresult> [--min PERCENT]

Coverage is measured on the app's logic only: SwiftUI views and the app
entry point are excluded, since unit tests do not exercise them. With
--min, exits 1 when coverage falls below that percentage.
"""
import argparse
import json
import os
import subprocess

EXCLUDED = ("LetHimCook/Presentation/Views/", "LetHimCook/App/")

parser = argparse.ArgumentParser()
parser.add_argument("bundle")
parser.add_argument("--min", type=float, default=0)
args = parser.parse_args()

report = json.loads(subprocess.check_output(
    ["xcrun", "xccov", "view", "--report", "--json", args.bundle]
))

app = next(t for t in report["targets"] if t["name"] == "LetHimCook.app")
workspace = os.environ.get("GITHUB_WORKSPACE", os.getcwd()).rstrip("/") + "/"

files = []
for f in app["files"]:
    path = f["path"].removeprefix(workspace)
    if not path.startswith(EXCLUDED):
        files.append((path, f["coveredLines"], f["executableLines"]))

covered = sum(c for _, c, _ in files)
executable = sum(e for _, _, e in files)
coverage = 100 * covered / executable if executable else 100

lines = [
    f"### Code coverage: {coverage:.1f}% (minimum {args.min:g}%)",
    "",
    f"{covered} of {executable} lines of app logic; views and `App/` excluded.",
    "",
    "<details><summary>Per file</summary>",
    "",
    "| File | Coverage | Lines |",
    "| --- | ---: | ---: |",
]
for path, c, e in sorted(files, key=lambda f: f[1] / f[2] if f[2] else 1):
    lines.append(f"| `{path}` | {100 * c / e if e else 100:.1f}% | {c}/{e} |")
lines += ["", "</details>", ""]

text = "\n".join(lines)
print(text)
summary = os.environ.get("GITHUB_STEP_SUMMARY")
if summary:
    with open(summary, "a") as out:
        out.write(text + "\n")

if coverage < args.min:
    print(f"::error::Code coverage {coverage:.1f}% is below the {args.min:g}% minimum")
    raise SystemExit(1)
