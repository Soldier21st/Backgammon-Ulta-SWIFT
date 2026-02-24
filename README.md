# Backgammon Ultra Starter

Initial implementation scaffold for a premium modern iOS Backgammon product with:

- Solo play (10 AI levels)
- Online ranked (Elo)
- Casual online + friends invites
- Voice chat moderation controls
- Profile, leaderboard, achievements, daily challenges
- Premium subscription + cosmetics

Current status:

- Playable solo board flow with legal-move highlighting and AI turns.
- 10 AI difficulty profiles with heuristic move selection.
- Deterministic turn-candidate generation for dice-order handling.
- Realtime backend skeleton (Node.js + TypeScript + WebSocket).

## Modules

- `BackgammonUltraCore`: shared domain models, Elo logic, progression, monetization models.
- `BackgammonUltraGameEngine`: deterministic board and move validation primitives.
- `BackgammonUltraRealtime`: websocket protocol contracts and matchmaking models.
- `BackgammonUltraVoice`: voice token/contracts and moderation hooks.
- `BackgammonUltraApp`: SwiftUI shell for app navigation and feature hubs.

## Run tests

```bash
swift test
```

## Docs

- `docs/ARCHITECTURE.md`
- `docs/DATABASE_SCHEMA.sql`
- `docs/MULTIPLAYER_SYSTEM.md`
- `docs/BACKEND_API.md`
- `docs/VOICE_INTEGRATION.md`
- `docs/ELO_RATING.md`
- `docs/AI_SYSTEM.md`
- `docs/MONETIZATION.md`
- `docs/SCALABILITY_1M.md`

## Backend

`backend/` contains a realtime server scaffold with:

- queueing and matchmaking,
- match session event stream ownership,
- ranked Elo settlement,
- moderation report intake.

See `backend/README.md` for local run and test commands.
