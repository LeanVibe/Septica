# Repository Guidelines

## Project Structure & Module Organization
- App code lives in `Septica/` with subfolders: `Models/`, `ViewModels/`, `Views/`, `Controllers/`, `Managers/`, `Services/`, `Rendering/`, `Performance/`, `ErrorHandling/`, and `AI/`. Assets in `Assets.xcassets/`.
- Tests in `SepticaTests/` (unit/integration/performance) and `SepticaUITests/` (UI & launch tests).
- Xcode project: `Septica.xcodeproj` with scheme `Septica`. Supporting docs in `/docs` and root markdown files.

## Build, Test, and Development Commands
- Build (Debug, simulator):
  `xcodebuild -project Septica.xcodeproj -scheme Septica -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15' build`
- Run tests (unit + UI):
  `xcodebuild -project Septica.xcodeproj -scheme Septica -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15' clean test`
- Archive for App Store (CI/local):
  `./CreateAppStoreArchive.sh`
- Validation utilities:
  `./run_all_validation.sh`

Use Xcode for day‑to‑day development: open `Septica.xcodeproj`, select the `Septica` scheme, and run on an iOS Simulator.

## Coding Style & Naming Conventions
- Language: Swift 5; indentation: 4 spaces; 120‑char soft wrap.
- Types: `PascalCase` (e.g., `GameViewController`, `HandViewModel`).
- Methods/properties: `camelCase`; constants `let` preferred; avoid force‑unwraps.
- File names mirror primary type (e.g., `Card.swift`, `GameRulesTests.swift`).
- Linting: SwiftLint recommended (no repo config present). If installed, run `swiftlint` locally before commits.

## Testing Guidelines
- Framework: XCTest.
- Place tests under `SepticaTests/` or `SepticaUITests/` matching source module paths.
- Naming: test files end with `Tests.swift`; functions start with `test…` and assert one behavior.
- Prefer fast, deterministic tests; use `Integration/`, `Performance/`, `Stress/` subfolders as already organized.

## Commit & Pull Request Guidelines
- Commits: short, imperative subject; emoji prefix used in history is welcome (e.g., `✨ Add card dealing animation`). Group related changes; keep diffs focused.
- PRs: include summary, rationale, screenshots for UI, and steps to test. Link issues where applicable. Passing CI and tests required.

## Security & Configuration Tips
- Do not commit signing certificates, provisioning profiles, or secrets. Respect `.gitignore`.
- Use simulated data for tests; avoid embedding real user data.

## Architecture Notes
- The app follows a pragmatic MVC/MVVM blend: `Models` + `ViewModels` drive `Views`/`ViewControllers`, with `Managers`/`Services` for coordination and `Rendering` for Metal/graphics.
