# Voice Integration Plan (WebRTC)

## Architecture

- iOS client uses WebRTC native SDK.
- Backend issues short-lived voice access tokens per match.
- SFU topology recommended (LiveKit/Janus/mediasoup) for stable scaling and moderation hooks.

## Match Flow

1. Match starts in game service.
2. Client requests voice token (`matchID`, `userID`).
3. Voice service validates:
- user entitlement (premium required),
- block relationships,
- active match membership.
4. Voice token returned with TTL and room ID.
5. Client joins room and publishes one microphone track.

## iOS Audio

- `AVAudioSession` category: `.playAndRecord`.
- mode: `.voiceChat`.
- support Bluetooth routing.
- respect interruptions and route change events.

## In-match Controls

- `Mute`: disable local microphone track.
- `Block`: unsubscribe from blocked user and persist social block.
- `Report`: send match-linked moderation report with reason and timestamp.

## Moderation and Safety

- No auto-recording by default.
- Maintain report metadata and optional short safety buffer only if legally approved.
- Immediate action: local mute + hide quick-chat when block is applied.
- Back-office review queue receives report context (match ID, users, event timestamps).
