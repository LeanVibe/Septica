# Septica Restoration Plan

## 1. Baseline Assessment (Day 0)
- Snapshot current stubbed state (git tag `buildable-stub-baseline`).
- Document every subsystem replaced with placeholders (analytics, CloudKit, achievements, dialogue, menus, boards) with references to original files.
- Agree on success metrics: clean `xcodebuild` build, reinstated feature parity, regression test coverage ≥ existing UI tests.
- Owners: Tech Lead (Bogdan), iOS Lead (assigned).

## 2. Core Model & Networking Restoration (Days 1-3)
- Recreate shared cultural/analytics data models (`CulturalTypes`, `AnalyticsStubs`, achievement enums) with final schemas.
- Reintroduce CloudKit layer (PlayerProfileService, RewardChestService, CloudKitSyncEngine) using minimal async API + fakes for offline dev.
- Reinstate networking layer (MultiplayerService, NetworkManager) with Combine publishers and integration tests using local mock server.
- Deliverables: updated models, passing unit tests (`SepticaTests/CloudKit`, `Network`), documentation in `/docs/cloudkit.md`.

## 3. Analytics & Achievement Systems (Days 3-6)
- Restore `TraditionalStrategyAnalyzer`, `PerformanceAnalyticsManager`, `GameStateAnalyticsIntegration` with simplified but real algorithms.
- Reconnect `CulturalAuthenticityScoring`, `RomanianCulturalAnalytics`, and achievement tracking (unlock logic, notifications).
- Implement snapshot tests for analytics overlays and achievement notifications.
- Deliverables: analytics regression suite, updated documentation `/docs/analytics-overview.md`.

## 4. UI Rebuild (Days 4-7)
- Rebuild game screens (`GameBoardView`, `WorkingGameScreen`, `ShuffleCatsInspiredGameScreen`) using restored view models.
- Recreate cultural UI components (RomanianBackground, Dialogue overlays, ornate patterns) driven by real data.
- Rebuild menu stack (`MainMenuView`, `GameSetupView`, etc.) with navigation flows, binding into managers.
- Deliverables: interactive demo video, updated SwiftUI previews, checklist in `/docs/ui-restoration.md`.

## 5. Dialogue & Narrative Systems (Days 6-8)
- Reinstate `RomanianDialogueSystem` with data-driven scripts.
- Connect to gameplay events (Analytics, achievement unlocks).
- Add localization hooks and `Localizable.strings` entries.
- Deliverables: dialogue script JSON, tests verifying triggers.

## 6. QA & Automation (Days 8-9)
- Update existing XCTest / UITest targets to cover restored flows.
- Run `xcodebuild ... clean test` + Playwright web UI (if applicable) to ensure repo consistency.
- Generate new coverage reports and share via `/docs/testing-report.md`.

## 7. Final Hardening & Release Prep (Days 9-10)
- Performance profiling for analytics/game loops (Instruments).
- Accessibility audit (VoiceOver, Dynamic Type) for revived views.
- Security review for CloudKit/network credentials; verify `.gitignore` compliance.
- Deliverables: release checklist, final `build.log`, green CI.

## Governance & Logistics
- Daily standup notes stored in `/docs/status/daily-YYYYMMDD.md`.
- Weekly demo (Fridays) to stakeholders.
- PR policy: feature branch per subsystem, code review by domain owner, tests must pass.
- Risk tracking: use `/docs/risks.md` to log blockers.

## Tools & Environments
- iOS Simulator iPhone 16 (iOS 18) baseline; physical devices for smoke tests.
- CloudKit: use development container with seeded sample data.
- Analytics data: generate fixtures via `scripts/seed_analytics.swift` (to be authored in Phase 2).

## Exit Criteria
- All stub files removed or replaced with production implementations.
- Feature parity confirmed with original requirements (UI/CloudKit/analytics/multiplayer).
- Automated build + test pipeline green; documentation updated.
