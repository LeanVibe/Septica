# Repository Guidelines

## Project Structure & Module Organization
- App sources live in `Septica/` with feature folders such as `Models/`, `ViewModels/`, `Views/`, `Controllers/`, `Managers/`, `Services/`, `Rendering/`, `Performance/`, `ErrorHandling/`, and `AI/`.
- Store shared assets in `Assets.xcassets/`. Supporting docs sit in `/docs` and root-level markdown files.
- Place unit, integration, and performance tests in `SepticaTests/`; UI and launch coverage belongs in `SepticaUITests/`.
- Xcode project file is `Septica.xcodeproj`, using the `Septica` scheme for local work.

## Build, Test, and Development Commands
- `xcodebuild -project Septica.xcodeproj -scheme Septica -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15' build` — compile the app for the iOS 15 simulator in Debug mode.
- `xcodebuild -project Septica.xcodeproj -scheme Septica -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15' clean test` — reset derived data and run all unit and UI tests.
- `./CreateAppStoreArchive.sh` — produce a signed archive suitable for App Store submission.
- `./run_all_validation.sh` — execute repository validation utilities before merging.

## Coding Style & Naming Conventions
- Swift 5 with 4-space indentation and a 120-character soft wrap.
- Types use `PascalCase`; methods, properties, and variables use `camelCase`.
- Prefer `let` for constants, avoid force unwraps, and keep filenames aligned to their primary type (e.g., `Card.swift`).
- Run `swiftlint` locally if installed to flag style violations.

## Testing Guidelines
- Tests rely on XCTest. Name files with the `Tests.swift` suffix and methods beginning with `test…`.
- Keep cases focused on a single behavior; use subfolders like `Integration/`, `Performance/`, or `Stress/` where appropriate.
- Execute the full suite with the `xcodebuild … clean test` command above before opening a PR.

## Commit & Pull Request Guidelines
- Follow concise, imperative commit messages; emoji prefixes such as `✨ Add card dealing animation` mirror existing history.
- PRs should summarize intent, explain rationale, attach UI screenshots when relevant, and link issues.
- Ensure CI is green, validations have run, and tests pass prior to requesting review.

## Security & Configuration Tips
- Never commit signing certificates, provisioning profiles, or secrets. Use simulated data for tests and respect `.gitignore` entries.

## Architecture Notes
- The app blends MVC and MVVM: models and view models drive UIKit views/controllers, with `Managers/` and `Services/` coordinating flows and `Rendering/` dedicated to Metal/graphics work.
