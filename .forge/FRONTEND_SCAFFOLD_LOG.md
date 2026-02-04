# Septica Frontend v2 Scaffold Log

Date: 2026-02-02

## Scaffold
- Created React 19 + TypeScript + Vite app:
  - `npm create vite@latest frontend-v2 -- --template react-ts`
- Installed dependencies:
  - `npm install`
  - `npm install -D tailwindcss @tailwindcss/vite`
  - `npm install zustand`

## Tailwind v4 Setup
- Added Tailwind Vite plugin in `frontend-v2/vite.config.ts`.
- Updated `frontend-v2/src/index.css` with:
  - `@import "tailwindcss";`
  - basic body/root reset.

## Project Structure
- Added folders:
  - `frontend-v2/src/components/`
  - `frontend-v2/src/stores/`
  - `frontend-v2/src/services/`
  - `frontend-v2/src/types/`

## Game State Types
- Added `frontend-v2/src/types/game.ts` based on existing Septica game state:
  - Card (rank/suit)
  - PlayerState
  - OpponentState
  - ScoreState
  - GameState
- Added `frontend-v2/src/types/index.ts` barrel export.
