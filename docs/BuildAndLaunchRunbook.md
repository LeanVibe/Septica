# Septica Build & Launch Runbook

Use this checklist whenever you cut a build or investigate UI regressions.

## 1. Build & Smoke Validation
1. Run the automated smoke script:
   ```bash
   ./run_smoke_validation.sh
   ```
   This performs a clean Debug build, installs the app on the `iPhone 16 Pro` simulator, launches it, and drops a timestamped screenshot in `performance_screenshots/smoke/`.
2. Confirm the script log shows `🚀 Launching Septica with SepticaGameViewController root controller` at launch.

## 2. UI Regression Guard
1. Execute the UI smoke test from Xcode or CLI:
   ```bash
   xcodebuild -project Septica.xcodeproj -scheme SepticaUITests \
     -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test \
     -only-testing:SepticaUITests/MainMenuSmokeTests/testMainMenuDisplaysRomanianPlayButton
   ```
2. The test waits for the `JOACĂ` button on the new main menu. A failure means the app booted the legacy flow.

## 3. Project Integrity Audit
1. Ensure all critical Swift files are part of the build:
   ```bash
   ./verify_project_sources.py
   ```
2. The script runs a fast audit build and verifies the Swift file list contains the rendering and CloudKit modules.

## 4. Manual Spot Check
1. Launch the simulator manually if you want to inspect interactions:
   ```bash
   xcrun simctl launch booted dev.leanvibe.game.Septica
   ```
2. Confirm the landing screen displays the ShuffleCats-quality `MainMenuView` (look for the animated `JOACĂ` button and Romanian gradient background).

## 5. Troubleshooting
- If the legacy UI appears, make sure `AppDelegate` is still setting `SepticaGameViewController` as the root controller and that no stale storyboard is referenced in the build settings.
- For unexpected missing types, rerun `./verify_project_sources.py` to detect file-to-target drift.
- After CloudKit or rendering changes, regenerate a smoke screenshot and attach it to PRs for quick visual validation.
