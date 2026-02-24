# Backend API Contract (Initial)

## HTTP

### `GET /health`

Response:

```json
{
  "ok": true,
  "uptime": 123.4
}
```

## WebSocket

Connect:

`wss://<host>/ws?userId=<player-id>`

## Client -> Server

- `queue.join`
- `queue.leave`
- `match.action`
- `chat.quick`
- `emoji`
- `voice.report`
- `heartbeat`

## Server -> Client

- `queue.joined`
- `queue.left`
- `match.found`
- `match.event`
- `match.state`
- `chat.quick`
- `emoji`
- `heartbeat`
- `system.error`

## Notes

- Match actions are idempotent through `actionId`.
- Server owns turn order and event sequence numbers.
- Ranked rating settlement is emitted as `match.event` kind `rating.updated`.
