import test from "node:test";
import assert from "node:assert/strict";
import { MatchmakingService } from "./matchmaking";

test("ranked queue matches close ratings in same region", () => {
  const matchmaking = new MatchmakingService();

  const first = matchmaking.enqueue({
    userId: "u1",
    queueType: "ranked",
    currentRating: 1500,
    region: "US",
    preferredMatchLength: 5
  });

  const second = matchmaking.enqueue({
    userId: "u2",
    queueType: "ranked",
    currentRating: 1560,
    region: "US",
    preferredMatchLength: 7
  });

  const pair = matchmaking.tryMatch(second.ticketId);
  assert.ok(pair);
  assert.equal(pair?.players[0].ticketId, first.ticketId);
  assert.equal(pair?.players[1].ticketId, second.ticketId);
  assert.equal(pair?.matchLength, 7);
});

test("ranked queue does not immediately match large Elo gaps", () => {
  const matchmaking = new MatchmakingService();

  matchmaking.enqueue({
    userId: "u1",
    queueType: "ranked",
    currentRating: 1500,
    region: "US",
    preferredMatchLength: 5
  });

  const second = matchmaking.enqueue({
    userId: "u2",
    queueType: "ranked",
    currentRating: 2100,
    region: "US",
    preferredMatchLength: 5
  });

  const pair = matchmaking.tryMatch(second.ticketId);
  assert.equal(pair, null);
});

test("casual queue ignores rating distance", () => {
  const matchmaking = new MatchmakingService();

  matchmaking.enqueue({
    userId: "u1",
    queueType: "casual",
    currentRating: 1200,
    region: "EU",
    preferredMatchLength: 3
  });
  const second = matchmaking.enqueue({
    userId: "u2",
    queueType: "casual",
    currentRating: 2600,
    region: "EU",
    preferredMatchLength: 5
  });

  const pair = matchmaking.tryMatch(second.ticketId);
  assert.ok(pair);
});
