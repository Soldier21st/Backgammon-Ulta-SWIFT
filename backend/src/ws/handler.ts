import { ClientMessage, ServerMessage } from "../domain/protocol";
import { QueueRequest } from "../domain/models";
import { GameSessionService } from "../services/gameSession";
import { MatchmakingService } from "../services/matchmaking";
import { ModerationService } from "../services/moderation";
import { RatingStore } from "../services/ratingStore";
import { ClientRegistry } from "../state/clientRegistry";

export interface RealtimeContext {
  clients: ClientRegistry;
  matchmaking: MatchmakingService;
  gameSessions: GameSessionService;
  moderation: ModerationService;
  ratings: RatingStore;
}

export function handleClientMessage(
  userId: string,
  raw: string,
  context: RealtimeContext
): void {
  const message = parseClientMessage(raw);
  if (!message) {
    sendError(context.clients, userId, "BAD_PAYLOAD", "Invalid message payload.");
    return;
  }

  try {
    switch (message.type) {
      case "queue.join": {
        const queueRequest: QueueRequest = {
          userId,
          queueType: message.payload.queueType,
          currentRating: message.payload.currentRating,
          region: message.payload.region,
          preferredMatchLength: message.payload.preferredMatchLength,
          maxPingMs: message.payload.maxPingMs
        };

        const ticket = context.matchmaking.enqueue(queueRequest);
        context.clients.send(userId, {
          type: "queue.joined",
          payload: {
            ticketId: ticket.ticketId,
            queueType: ticket.queueType,
            queuedAt: ticket.createdAt
          }
        });

        const pair = context.matchmaking.tryMatch(ticket.ticketId);
        if (!pair) {
          return;
        }

        const match = context.gameSessions.createMatch({
          mode: pair.queueType,
          matchLength: pair.matchLength,
          playerA: {
            userId: pair.players[0].userId,
            ratingAtStart: pair.players[0].currentRating
          },
          playerB: {
            userId: pair.players[1].userId,
            ratingAtStart: pair.players[1].currentRating
          }
        });

        const participants = match.participants.map((p) => p.userId);
        context.clients.broadcast(participants, {
          type: "match.found",
          payload: { match }
        });
        context.clients.broadcast(participants, {
          type: "match.state",
          payload: { match }
        });
        break;
      }

      case "queue.leave": {
        const removed = message.payload.ticketId
          ? context.matchmaking.removeByTicket(message.payload.ticketId)
          : context.matchmaking.removeByUser(userId);

        if (!removed) {
          sendError(context.clients, userId, "TICKET_NOT_FOUND", "Queue ticket not found.");
          return;
        }
        context.clients.send(userId, {
          type: "queue.left",
          payload: {
            ticketId: message.payload.ticketId
          }
        });
        break;
      }

      case "match.action": {
        const result = context.gameSessions.applyAction({
          ...message.payload,
          actorUserId: userId,
          sentAt: Date.now()
        });
        const participants = result.match.participants.map((p) => p.userId);

        context.clients.broadcast(participants, {
          type: "match.event",
          payload: {
            matchId: result.match.id,
            sequence: result.event.sequence,
            kind: result.event.kind,
            actorUserId: result.event.actorUserId,
            payload: result.event.payload
          }
        });
        context.clients.broadcast(participants, {
          type: "match.state",
          payload: {
            match: result.match
          }
        });

        if (result.match.state === "completed" && result.match.mode === "ranked") {
          const settlement = context.ratings.settleRankedMatch(result.match);
          if (settlement) {
            context.clients.broadcast(participants, {
              type: "match.event",
              payload: {
                matchId: result.match.id,
                sequence: result.match.eventSequence + 1,
                kind: "rating.updated",
                payload: settlement
              }
            });
          }
        }
        break;
      }

      case "chat.quick": {
        const match = context.gameSessions.getSession(message.payload.matchId);
        if (!match) {
          sendError(context.clients, userId, "MATCH_NOT_FOUND", "Match not found.");
          return;
        }
        const participants = match.participants.map((p) => p.userId);
        context.clients.broadcast(participants, {
          type: "chat.quick",
          payload: {
            matchId: match.id,
            actorUserId: userId,
            message: message.payload.message
          }
        });
        break;
      }

      case "emoji": {
        const match = context.gameSessions.getSession(message.payload.matchId);
        if (!match) {
          sendError(context.clients, userId, "MATCH_NOT_FOUND", "Match not found.");
          return;
        }
        const participants = match.participants.map((p) => p.userId);
        context.clients.broadcast(participants, {
          type: "emoji",
          payload: {
            matchId: match.id,
            actorUserId: userId,
            emoji: message.payload.emoji
          }
        });
        break;
      }

      case "voice.report": {
        context.moderation.createReport({
          reporterUserId: userId,
          reportedUserId: message.payload.reportedUserId,
          matchId: message.payload.matchId,
          reason: message.payload.reason
        });
        break;
      }

      case "heartbeat": {
        context.clients.send(userId, {
          type: "heartbeat",
          payload: { ts: Date.now() }
        });
        break;
      }

      default:
        sendError(context.clients, userId, "UNSUPPORTED", "Unsupported message type.");
    }
  } catch (error) {
    const messageText = error instanceof Error ? error.message : "Unknown server error";
    sendError(context.clients, userId, "SERVER_ERROR", messageText);
  }
}

function parseClientMessage(raw: string): ClientMessage | null {
  try {
    const parsed = JSON.parse(raw) as Record<string, unknown>;
    if (typeof parsed !== "object" || parsed === null) {
      return null;
    }
    if (typeof parsed.type !== "string") {
      return null;
    }
    if (typeof parsed.payload !== "object" || parsed.payload === null) {
      return null;
    }
    return parsed as ClientMessage;
  } catch {
    return null;
  }
}

function sendError(clients: ClientRegistry, userId: string, code: string, message: string): void {
  const payload: ServerMessage = {
    type: "system.error",
    payload: { code, message }
  };
  clients.send(userId, payload);
}
