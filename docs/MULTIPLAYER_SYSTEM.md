# Multiplayer System Design

## Session Model

- Match server is authoritative for move validation, dice, doubling cube, turn order, and end conditions.
- Client submits action intents only.
- Server broadcasts canonical state and event sequence numbers.

## Transport

- Protocol: secure WebSockets (`wss`).
- Message wrapper: `RealtimeEnvelope` with `id`, `sequence`, `eventType`, and `payload`.
- Sequence is monotonic per match to support replay and desync recovery.

## Matchmaking

### Ranked

- Start with `+-100` Elo window.
- Expand window every 5 seconds up to configurable maximum.
- Consider region and ping budget.
- Prevent repeated same-opponent farming via cooldown rules.

### Casual

- Wider rating tolerance for speed.
- Optional voice preference.

### Friends

- Private room via invite token or Game Center invite.
- Optional spectator visibility toggle.

## Reconnect and State Recovery

- Client stores last acknowledged sequence number.
- Reconnect payload includes `matchID` + `lastSequence`.
- Server either streams missed deltas or sends a full snapshot.

## Spectator Mode

- Read-only channel.
- Delay spectators in ranked to reduce live ghosting.
- Voice channel disabled for spectators by default.

## Anti-cheat Controls

- CSPRNG dice generated server-side.
- Full legal-move verification server-side.
- Idempotency keys on action requests.
- Anomaly checks for latency manipulation and collusion patterns.
