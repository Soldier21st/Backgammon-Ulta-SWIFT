import { EloUpdateResult, RankedPlayerSnapshot } from "../domain/models";

export interface EloConfig {
  provisionalK: number;
  establishedK: number;
  eliteK: number;
  provisionalMatchThreshold: number;
  eliteRatingThreshold: number;
  scale: number;
}

export class EloService {
  private readonly config: EloConfig;

  constructor(config?: Partial<EloConfig>) {
    this.config = {
      provisionalK: 40,
      establishedK: 24,
      eliteK: 16,
      provisionalMatchThreshold: 30,
      eliteRatingThreshold: 2200,
      scale: 400,
      ...config
    };
  }

  expectedScore(playerRating: number, opponentRating: number): number {
    const exponent = (opponentRating - playerRating) / this.config.scale;
    return 1 / (1 + 10 ** exponent);
  }

  matchLengthMultiplier(matchLength: 1 | 3 | 5 | 7 | 11): number {
    switch (matchLength) {
      case 1:
        return 0.75;
      case 3:
        return 0.9;
      case 5:
        return 1.0;
      case 7:
        return 1.1;
      case 11:
        return 1.2;
      default:
        return 1.0;
    }
  }

  effectiveK(player: RankedPlayerSnapshot, matchLength: 1 | 3 | 5 | 7 | 11): number {
    const baseK =
      player.rankedMatchesPlayed < this.config.provisionalMatchThreshold
        ? this.config.provisionalK
        : player.rating >= this.config.eliteRatingThreshold
          ? this.config.eliteK
          : this.config.establishedK;
    return baseK * this.matchLengthMultiplier(matchLength);
  }

  updateRatings(input: {
    playerA: RankedPlayerSnapshot;
    playerB: RankedPlayerSnapshot;
    playerAWon: boolean;
    matchLength: 1 | 3 | 5 | 7 | 11;
  }): EloUpdateResult {
    const { playerA, playerB, playerAWon, matchLength } = input;
    const scoreA = playerAWon ? 1 : 0;
    const scoreB = playerAWon ? 0 : 1;
    const expectedA = this.expectedScore(playerA.rating, playerB.rating);
    const expectedB = this.expectedScore(playerB.rating, playerA.rating);
    const kA = this.effectiveK(playerA, matchLength);
    const kB = this.effectiveK(playerB, matchLength);

    const deltaA = Math.round(kA * (scoreA - expectedA));
    const deltaB = Math.round(kB * (scoreB - expectedB));

    return {
      playerARatingAfter: playerA.rating + deltaA,
      playerBRatingAfter: playerB.rating + deltaB,
      playerADelta: deltaA,
      playerBDelta: deltaB
    };
  }

  seasonSoftReset(currentRating: number, baseRating = 1500, carryFactor = 0.75): number {
    const shifted = (currentRating - baseRating) * carryFactor;
    return baseRating + Math.round(shifted);
  }
}
