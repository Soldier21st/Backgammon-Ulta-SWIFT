# Scalability Plan (Toward 1M Registered Users)

## Traffic Assumptions

- 1M registered users.
- 100k to 150k DAU.
- 15k to 25k concurrent users at peak.
- Realtime matches are the latency-critical path.

## Capacity Strategy

1. `Realtime Gateway` horizontally autoscaled pods.
2. `Game Session` workers stateless and distributed by match shard key.
3. Redis cluster for presence and queue coordination.
4. PostgreSQL primary + read replicas for profile and leaderboard reads.
5. Async jobs for non-critical writes (achievements, analytics, notifications).

## Data Strategy

- Event log for move history (`move_events`) with partitioning by month.
- Materialized read models for leaderboards and profile summary.
- Replay payloads compressed in object storage, metadata in PostgreSQL.

## Regional Strategy

- Multi-region deploy (US/EU/APAC).
- Region-aware matchmaking with latency budget.
- Global account identity; regional game session affinity.

## Reliability

- Blue/green deployments for realtime services.
- Circuit breakers between gateways and internal services.
- Idempotent commands and retry-safe event processing.
- SLOs:
  - connect success rate,
  - p95 move acknowledge latency,
  - match completion rate.

## Observability

- Structured logs with match/session IDs.
- Metrics dashboards for queue wait time, reconnect frequency, and desync rates.
- Distributed tracing for end-to-end match lifecycle.
