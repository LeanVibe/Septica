# iOS Documentation Archive

**Archived Date**: October 1, 2025

## Why These Files Were Archived

These documentation files incorrectly described the Romanian Septica project as an **iOS Swift/SwiftUI application**, when the actual architecture is:

- **Backend**: Go + Gin framework + PostgreSQL
- **Frontend**: Premium PWA (HTML/CSS/JavaScript + Three.js)

## Archived Files

1. **PLAN.md** - Claimed "Romanian Septica iOS App - Current Status & Next Steps"
2. **TODO.md** - Described iOS development phases with CloudKit integration
3. **ENHANCEMENT_ROADMAP.md** - Contained Swift/SwiftUI code examples for non-existent iOS app
4. **PROGRESS_SUMMARY.md** - Claimed iOS app restoration achievements

## What Actually Exists

- ✅ Go backend server (`backend/` directory) with WebSocket multiplayer
- ✅ PostgreSQL database with comprehensive game models
- ✅ Premium PWA frontend (`frontend/` directory) with Three.js 3D rendering
- ❌ **No iOS Swift codebase exists**

## Corrected Documentation

Refer to:
- `docs/CLAUDE.md` - Accurate project description (PWA architecture)
- `docs/PROJECT_STATUS.md` - Current consolidated status (PWA-focused)
- `docs/TECHNICAL_DEBT.md` - Known issues and improvements

## How This Happened

Documentation drift - likely from:
1. Initial project vision included iOS version
2. Documentation created before pivoting to PWA approach
3. Files not updated when architecture changed
4. Copy-paste from iOS project templates

## Lesson Learned

**Single Source of Truth**: `docs/CLAUDE.md` should be the canonical project description. All other documentation should reference it, not duplicate architectural details.
