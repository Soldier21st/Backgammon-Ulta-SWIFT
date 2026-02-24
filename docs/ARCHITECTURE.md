# Backgammon Ultra Architecture

## 1. Client (iOS, Swift + SwiftUI)

### App Layers

1. `Presentation`
- SwiftUI feature hubs and game UI.
- Local UI state, animations, haptics, dark mode tokens.

2. `Domain`
- Matchmaking and game-use-case flows.
- Profile/stats/challenge orchestration.

3. `Data`
- WebSocket transport.
- REST endpoints for profile/store/leaderboards.
- Local persistence for settings and replay cache.

### Feature Modules

- `Play`: solo, ranked, casual, friends, local 2P.
- `Compete`: seasons, challenges, achievements.
- `Social`: quick chat, emoji, block/report, invites.
- `Profile`: identity and match history.
- `Store`: subscription and cosmetics.

## 2. Backend (Node.js + TypeScript)

### Services

- `API Gateway`: auth, profiles, inventory, settings.
- `Realtime Gateway`: persistent websocket sessions.
- `Game Session Service`: authoritative move validation and state.
- `Matchmaking Service`: queueing by mode/rating/region.
- `Rating Service`: Elo updates and season resets.
- `Voice Signaling Service`: WebRTC token issue and policy.
- `Moderation Service`: report processing and penalties.
- `Replay Service`: event stream storage/playback.
- `Economy Service`: entitlements, purchases, cosmetics.

### Shared Infrastructure

- PostgreSQL: primary relational source of truth.
- Redis: presence, queue buckets, short-lived session state.
- Object storage: avatars, replay chunks, cosmetics metadata.
- Queue (BullMQ/SQS): asynchronous jobs and denormalized materialization.

## 3. Security and Fair Play

- Authoritative server RNG for dice.
- Server-side legal move checks only.
- Signed action envelopes with monotonic sequence IDs.
- Device attestation and anomaly scoring.
- Collusion detection pipeline for ranked abuse.
