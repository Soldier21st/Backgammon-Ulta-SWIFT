import { MatchActionCommand, MatchSession, QueueType } from "./models";

export type ClientMessage =
  | {
      type: "queue.join";
      payload: {
        queueType: QueueType;
        currentRating: number;
        region: string;
        preferredMatchLength: 1 | 3 | 5 | 7 | 11;
        maxPingMs?: number;
      };
    }
  | {
      type: "queue.leave";
      payload: { ticketId?: string };
    }
  | {
      type: "match.action";
      payload: Omit<MatchActionCommand, "actorUserId" | "sentAt">;
    }
  | {
      type: "chat.quick";
      payload: {
        matchId: string;
        message: "Hi" | "Good luck" | "Your turn" | "Nice move" | "Well played" | "Rematch?";
      };
    }
  | {
      type: "emoji";
      payload: {
        matchId: string;
        emoji: string;
      };
    }
  | {
      type: "voice.report";
      payload: {
        matchId: string;
        reportedUserId: string;
        reason: string;
      };
    }
  | {
      type: "heartbeat";
      payload: { ts: number };
    };

export type ServerMessage =
  | {
      type: "system.error";
      payload: { code: string; message: string };
    }
  | {
      type: "queue.joined";
      payload: { ticketId: string; queueType: QueueType; queuedAt: number };
    }
  | {
      type: "queue.left";
      payload: { ticketId?: string };
    }
  | {
      type: "match.found";
      payload: {
        match: MatchSession;
      };
    }
  | {
      type: "match.event";
      payload: {
        matchId: string;
        sequence: number;
        kind: string;
        actorUserId?: string;
        payload: Record<string, unknown>;
      };
    }
  | {
      type: "match.state";
      payload: {
        match: MatchSession;
      };
    }
  | {
      type: "chat.quick";
      payload: {
        matchId: string;
        actorUserId: string;
        message: string;
      };
    }
  | {
      type: "emoji";
      payload: {
        matchId: string;
        actorUserId: string;
        emoji: string;
      };
    }
  | {
      type: "heartbeat";
      payload: { ts: number };
    };
