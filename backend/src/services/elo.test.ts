import test from "node:test";
import assert from "node:assert/strict";
import { EloService } from "./elo";

test("winner gains rating and loser loses rating", () => {
  const elo = new EloService();
  const result = elo.updateRatings({
    playerA: { userId: "a", rating: 1500, rankedMatchesPlayed: 50 },
    playerB: { userId: "b", rating: 1500, rankedMatchesPlayed: 50 },
    playerAWon: true,
    matchLength: 5
  });

  assert.ok(result.playerADelta > 0);
  assert.ok(result.playerBDelta < 0);
});

test("longer matches produce bigger Elo swing", () => {
  const elo = new EloService();
  const shortMatch = elo.updateRatings({
    playerA: { userId: "a", rating: 1700, rankedMatchesPlayed: 80 },
    playerB: { userId: "b", rating: 1700, rankedMatchesPlayed: 80 },
    playerAWon: true,
    matchLength: 1
  });

  const longMatch = elo.updateRatings({
    playerA: { userId: "a", rating: 1700, rankedMatchesPlayed: 80 },
    playerB: { userId: "b", rating: 1700, rankedMatchesPlayed: 80 },
    playerAWon: true,
    matchLength: 11
  });

  assert.ok(Math.abs(longMatch.playerADelta) > Math.abs(shortMatch.playerADelta));
});

test("season reset moves rating toward 1500", () => {
  const elo = new EloService();
  const reset = elo.seasonSoftReset(2100);
  assert.ok(reset < 2100);
  assert.ok(reset > 1500);
});
