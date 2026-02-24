import { randomUUID } from "node:crypto";
import { MatchActionCommand, MatchEvent, MatchSession, MatchState } from "../domain/models";

interface CreateMatchInput {
  mode: MatchSession["mode"];
  matchLength: MatchSession["matchLength"];
  playerA: { userId: string; ratingAtStart: number };
  playerB: { userId: string; ratingAtStart: number };
}

export class GameSessionService {
  private readonly sessions = new Map<string, MatchSession>();
  private readonly processedActionIds = new Map<string, Set<string>>();

  createMatch(input: CreateMatchInput): MatchSession {
    const id = randomUUID();
    const participants: MatchSession["participants"] = [
      { userId: input.playerA.userId, ratingAtStart: input.playerA.ratingAtStart },
      { userId: input.playerB.userId, ratingAtStart: input.playerB.ratingAtStart }
    ];

    const currentTurnUserId =
      Math.random() < 0.5 ? participants[0].userId : participants[1].userId;

    const now = Date.now();
    const match: MatchSession = {
      id,
      mode: input.mode,
      state: "active",
      matchLength: input.matchLength,
      createdAt: now,
      startedAt: now,
      participants,
      currentTurnUserId,
      eventSequence: 0,
      events: []
    };

    this.sessions.set(id, match);
    this.processedActionIds.set(id, new Set<string>());
    this.appendSystemEvent(match, "match.started", {
      currentTurnUserId
    });
    return match;
  }

  getSession(matchId: string): MatchSession | undefined {
    return this.sessions.get(matchId);
  }

  applyAction(command: MatchActionCommand): { match: MatchSession; event: MatchEvent } {
    const match = this.sessions.get(command.matchId);
    if (!match) {
      throw new Error("MATCH_NOT_FOUND");
    }
    if (match.state !== "active") {
      throw new Error("MATCH_NOT_ACTIVE");
    }

    const actionIds = this.processedActionIds.get(match.id);
    if (!actionIds) {
      throw new Error("MATCH_INDEX_MISSING");
    }
    if (actionIds.has(command.actionId)) {
      // Idempotent return of current state.
      const latest = match.events[match.events.length - 1];
      if (!latest) {
        throw new Error("DUPLICATE_ACTION");
      }
      return { match, event: latest };
    }

    const isParticipant = match.participants.some((player) => player.userId === command.actorUserId);
    if (!isParticipant) {
      throw new Error("UNAUTHORIZED_PLAYER");
    }

    if ((command.kind === "roll" || command.kind === "move") && command.actorUserId !== match.currentTurnUserId) {
      throw new Error("NOT_YOUR_TURN");
    }

    actionIds.add(command.actionId);

    // This service is authoritative for turn order and command stream.
    // Backgammon move legality should be validated by the game rules runtime before persisting.
    const event = this.appendEvent(match, {
      kind: command.kind,
      actorUserId: command.actorUserId,
      payload: command.payload
    });

    switch (command.kind) {
      case "move":
      case "double.decline":
        match.currentTurnUserId = this.opponentId(match, command.actorUserId);
        break;
      case "resign":
        match.state = "completed";
        match.finishedAt = Date.now();
        match.winnerUserId = this.opponentId(match, command.actorUserId);
        this.appendSystemEvent(match, "match.completed", {
          winnerUserId: match.winnerUserId
        });
        break;
      case "double.accept":
      case "double.offer":
      case "roll":
        break;
      default:
        break;
    }

    return { match, event };
  }

  private opponentId(match: MatchSession, userId: string): string {
    const opponent = match.participants.find((p) => p.userId !== userId);
    if (!opponent) {
      throw new Error("OPPONENT_NOT_FOUND");
    }
    return opponent.userId;
  }

  private appendSystemEvent(
    match: MatchSession,
    kind: string,
    payload: Record<string, unknown>
  ): MatchEvent {
    return this.appendEvent(match, {
      kind: "system",
      payload: {
        kind,
        ...payload
      }
    });
  }

  private appendEvent(
    match: MatchSession,
    eventInput: {
      kind: MatchEvent["kind"];
      actorUserId?: string;
      payload: Record<string, unknown>;
    }
  ): MatchEvent {
    match.eventSequence += 1;
    const event: MatchEvent = {
      sequence: match.eventSequence,
      kind: eventInput.kind,
      actorUserId: eventInput.actorUserId,
      payload: eventInput.payload,
      createdAt: Date.now()
    };
    match.events.push(event);
    return event;
  }

  updateState(matchId: string, state: MatchState): MatchSession {
    const match = this.sessions.get(matchId);
    if (!match) {
      throw new Error("MATCH_NOT_FOUND");
    }
    match.state = state;
    if (state === "completed") {
      match.finishedAt = Date.now();
    }
    return match;
  }
}
