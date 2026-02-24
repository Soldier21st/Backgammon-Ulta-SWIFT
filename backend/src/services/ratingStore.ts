import { MatchSession, RankedPlayerSnapshot } from "../domain/models";
import { EloService } from "./elo";

export interface RatingSettlement {
  matchId: string;
  playerAUserId: string;
  playerBUserId: string;
  playerADelta: number;
  playerBDelta: number;
  playerARatingAfter: number;
  playerBRatingAfter: number;
}

export class RatingStore {
  private readonly ratings = new Map<string, RankedPlayerSnapshot>();
  private readonly settledMatchIds = new Set<string>();
  private readonly elo: EloService;

  constructor(elo = new EloService()) {
    this.elo = elo;
  }

  get(userId: string): RankedPlayerSnapshot {
    const existing = this.ratings.get(userId);
    if (existing) {
      return existing;
    }
    const initial: RankedPlayerSnapshot = {
      userId,
      rating: 1500,
      rankedMatchesPlayed: 0
    };
    this.ratings.set(userId, initial);
    return initial;
  }

  settleRankedMatch(match: MatchSession): RatingSettlement | null {
    if (match.mode !== "ranked" || !match.winnerUserId) {
      return null;
    }
    if (this.settledMatchIds.has(match.id)) {
      return null;
    }

    const [a, b] = match.participants;
    const playerA = this.get(a.userId);
    const playerB = this.get(b.userId);
    const playerAWon = match.winnerUserId === a.userId;

    const update = this.elo.updateRatings({
      playerA,
      playerB,
      playerAWon,
      matchLength: match.matchLength
    });

    const nextA: RankedPlayerSnapshot = {
      ...playerA,
      rating: update.playerARatingAfter,
      rankedMatchesPlayed: playerA.rankedMatchesPlayed + 1
    };
    const nextB: RankedPlayerSnapshot = {
      ...playerB,
      rating: update.playerBRatingAfter,
      rankedMatchesPlayed: playerB.rankedMatchesPlayed + 1
    };

    this.ratings.set(nextA.userId, nextA);
    this.ratings.set(nextB.userId, nextB);
    this.settledMatchIds.add(match.id);

    return {
      matchId: match.id,
      playerAUserId: nextA.userId,
      playerBUserId: nextB.userId,
      playerADelta: update.playerADelta,
      playerBDelta: update.playerBDelta,
      playerARatingAfter: nextA.rating,
      playerBRatingAfter: nextB.rating
    };
  }
}
