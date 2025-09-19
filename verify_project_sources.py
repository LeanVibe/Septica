#!/usr/bin/env python3
"""Verify critical Swift files are referenced in the Xcode project."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path
import shutil

CRITICAL_DIRS = [
    Path("Septica/Rendering/Professional"),
    Path("Septica/Services/CloudKit"),
]

DERIVED_DATA = Path("DerivedData/ProjectAudit")


def collect_swift_file_list() -> set[Path]:
    """Run a lightweight build to collect the Swift file list used by Xcode."""

    if DERIVED_DATA.exists():
        shutil.rmtree(DERIVED_DATA)

    print("🔍 Running audit build to capture Swift file list…", file=sys.stderr)
    result = subprocess.run(
        [
            "xcodebuild",
            "-project",
            "Septica.xcodeproj",
            "-scheme",
            "Septica",
            "-configuration",
            "Debug",
            "-destination",
            "platform=iOS Simulator,name=iPhone 16 Pro",
            "-derivedDataPath",
            str(DERIVED_DATA),
            "build",
        ],
        check=False,
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        sys.stderr.write(result.stdout)
        sys.stderr.write(result.stderr)
        sys.stderr.write("❌ Failed to build project for audit\n")
        sys.exit(result.returncode)

    swift_lists = list(
        DERIVED_DATA.glob(
            "**/Septica.build/Debug-iphonesimulator/Septica.build/Objects-normal/arm64/Septica.SwiftFileList"
        )
    )
    if not swift_lists:
        sys.stderr.write("❌ Could not locate Swift file list in DerivedData\n")
        sys.exit(1)

    files: set[Path] = set()
    for file_list in swift_lists:
        for line in file_list.read_text().splitlines():
            trimmed = line.strip()
            if trimmed:
                files.add(Path(trimmed).resolve())
    return files


def main() -> None:
    files_in_build = collect_swift_file_list()
    project_root = Path.cwd().resolve()

    missing: list[str] = []
    for directory in CRITICAL_DIRS:
        if not directory.exists():
            continue
        for file in directory.glob("**/*.swift"):
            absolute = (project_root / file).resolve()
            if absolute not in files_in_build:
                missing.append(str(file))

    if missing:
        sys.stderr.write("❌ Critical Swift files missing from build:\n")
        for item in sorted(missing):
            sys.stderr.write(f"  - {item}\n")
        sys.exit(1)

    print("✅ All critical Swift files participate in the build")


if __name__ == "__main__":
    main()
