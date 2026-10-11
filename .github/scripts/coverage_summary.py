#!/usr/bin/env python3
"""Write the app's code coverage to the GitHub job summary."""
import json
import os
import subprocess
import sys

bundle = sys.argv[1]
report = json.loads(subprocess.check_output(
    ["xcrun", "xccov", "view", "--report", "--json", bundle]
))

app = next(t for t in report["targets"] if t["name"] == "LetHimCook.app")
workspace = os.environ.get("GITHUB_WORKSPACE", os.getcwd()).rstrip("/") + "/"

lines = [
    f"### Code coverage: {app['lineCoverage']:.1%}",
    "",
    f"{app['coveredLines']} of {app['executableLines']} lines in LetHimCook.app",
    "",
    "<details><summary>Per file</summary>",
    "",
    "| File | Coverage | Lines |",
    "| --- | ---: | ---: |",
]
for f in sorted(app["files"], key=lambda f: f["lineCoverage"]):
    path = f["path"].removeprefix(workspace)
    lines.append(f"| `{path}` | {f['lineCoverage']:.1%} | {f['coveredLines']}/{f['executableLines']} |")
lines += ["", "</details>", ""]

text = "\n".join(lines)
print(text)
summary = os.environ.get("GITHUB_STEP_SUMMARY")
if summary:
    with open(summary, "a") as out:
        out.write(text + "\n")
