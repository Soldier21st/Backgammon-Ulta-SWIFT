# Backgammon Ultra Backend (Node.js + TypeScript)

Realtime service skeleton for:

- WebSocket matchmaking and match events
- Authoritative match session stream and turn ownership
- Ranked Elo update settlement
- Quick chat / emoji relay
- Voice abuse report intake

## Endpoints

- `GET /health`
- `WS /ws?userId=<uuid-or-stable-id>`

## Client Message Types

- `queue.join`
- `queue.leave`
- `match.action`
- `chat.quick`
- `emoji`
- `voice.report`
- `heartbeat`

## Server Message Types

- `queue.joined`
- `queue.left`
- `match.found`
- `match.event`
- `match.state`
- `chat.quick`
- `emoji`
- `heartbeat`
- `system.error`

## Local run

```bash
cd backend
npm install
npm run dev
```

## Tests

```bash
cd backend
npm test
```
