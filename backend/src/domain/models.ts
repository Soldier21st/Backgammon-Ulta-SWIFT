export type QueueType = "ranked" | "casual" | "friends";
export type MatchMode = QueueType;
export type MatchState = "waiting" | "active" | "completed" | "cancelled";

export interface QueueRequest {
  userId: string;
  queueType: QueueType;
  currentRating: number;
  region: string;
  preferredMatchLength: 1 | 3 | 5 | 7 | 11;
  maxPingMs?: number;
}

export interface QueueTicket extends QueueRequest {
  ticketId: string;
  createdAt: number;
}

export interface MatchParticipant {
  userId: string;
  ratingAtStart: number;
}

export type MatchActionKind =
  | "roll"
  | "move"
  | "double.offer"
  | "double.accept"
  | "double.decline"
  | "resign";

export interface MatchActionCommand {
  matchId: string;
  actionId: string;
  actorUserId: string;
  kind: MatchActionKind;
  payload: Record<string, unknown>;
  sentAt: number;
}

export interface MatchEvent {
  sequence: number;
  kind: MatchActionKind | "chat.quick" | "emoji" | "system";
  actorUserId?: string;
  payload: Record<string, unknown>;
  createdAt: number;
}

export interface MatchSession {
  id: string;
  mode: MatchMode;
  state: MatchState;
  matchLength: 1 | 3 | 5 | 7 | 11;
  createdAt: number;
  startedAt?: number;
  finishedAt?: number;
  participants: [MatchParticipant, MatchParticipant];
  currentTurnUserId: string;
  winnerUserId?: string;
  eventSequence: number;
  events: MatchEvent[];
}

export interface RankedPlayerSnapshot {
  userId: string;
  rating: number;
  rankedMatchesPlayed: number;
}

export interface EloUpdateResult {
  playerARatingAfter: number;
  playerBRatingAfter: number;
  playerADelta: number;
  playerBDelta: number;
}
