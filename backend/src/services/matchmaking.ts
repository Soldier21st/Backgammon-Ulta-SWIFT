import { randomUUID } from "node:crypto";
import { QueueRequest, QueueTicket, QueueType } from "../domain/models";

export interface MatchPair {
  queueType: QueueType;
  region: string;
  players: [QueueTicket, QueueTicket];
  matchLength: 1 | 3 | 5 | 7 | 11;
}

export class MatchmakingService {
  private readonly queues = new Map<string, QueueTicket[]>();
  private readonly ticketIndex = new Map<string, { key: string; userId: string }>();
  private readonly ticketByUser = new Map<string, string>();

  enqueue(request: QueueRequest): QueueTicket {
    this.removeByUser(request.userId);

    const ticket: QueueTicket = {
      ...request,
      ticketId: randomUUID(),
      createdAt: Date.now(),
      maxPingMs: request.maxPingMs ?? 140
    };

    const key = this.key(request.queueType, request.region);
    const queue = this.queues.get(key) ?? [];
    queue.push(ticket);
    this.queues.set(key, queue);
    this.ticketIndex.set(ticket.ticketId, { key, userId: ticket.userId });
    this.ticketByUser.set(ticket.userId, ticket.ticketId);
    return ticket;
  }

  removeByTicket(ticketId: string): boolean {
    const located = this.ticketIndex.get(ticketId);
    if (!located) {
      return false;
    }

    const queue = this.queues.get(located.key);
    if (!queue) {
      this.ticketIndex.delete(ticketId);
      return false;
    }

    const idx = queue.findIndex((item) => item.ticketId === ticketId);
    if (idx >= 0) {
      const [removed] = queue.splice(idx, 1);
      this.ticketByUser.delete(removed.userId);
    }

    if (queue.length === 0) {
      this.queues.delete(located.key);
    } else {
      this.queues.set(located.key, queue);
    }

    this.ticketIndex.delete(ticketId);
    return idx >= 0;
  }

  removeByUser(userId: string): boolean {
    const ticketId = this.ticketByUser.get(userId);
    if (!ticketId) {
      return false;
    }
    return this.removeByTicket(ticketId);
  }

  tryMatch(ticketId: string): MatchPair | null {
    const located = this.ticketIndex.get(ticketId);
    if (!located) {
      return null;
    }

    const queue = this.queues.get(located.key);
    if (!queue || queue.length < 2) {
      return null;
    }

    const subjectIndex = queue.findIndex((q) => q.ticketId === ticketId);
    if (subjectIndex < 0) {
      return null;
    }

    const subject = queue[subjectIndex];
    let bestIndex = -1;
    let bestDistance = Number.POSITIVE_INFINITY;

    for (let idx = 0; idx < queue.length; idx += 1) {
      if (idx === subjectIndex) {
        continue;
      }
      const candidate = queue[idx];
      if (!this.isCompatible(subject, candidate)) {
        continue;
      }

      const distance = Math.abs(subject.currentRating - candidate.currentRating);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = idx;
      }
    }

    if (bestIndex < 0) {
      return null;
    }

    const candidate = queue[bestIndex];
    this.removeByTicket(subject.ticketId);
    this.removeByTicket(candidate.ticketId);

    const queueType = subject.queueType;
    const region = subject.region;
    const matchLength = this.resolveMatchLength(subject.preferredMatchLength, candidate.preferredMatchLength);

    return {
      queueType,
      region,
      players: [subject, candidate],
      matchLength
    };
  }

  private isCompatible(a: QueueTicket, b: QueueTicket): boolean {
    if (a.queueType !== b.queueType) {
      return false;
    }
    if (a.region !== b.region) {
      return false;
    }

    if (a.queueType !== "ranked") {
      return true;
    }

    const now = Date.now();
    const elapsedSec = Math.floor((now - Math.min(a.createdAt, b.createdAt)) / 1000);
    const allowedWindow = Math.min(500, 100 + Math.floor(elapsedSec / 5) * 50);
    return Math.abs(a.currentRating - b.currentRating) <= allowedWindow;
  }

  private resolveMatchLength(
    first: 1 | 3 | 5 | 7 | 11,
    second: 1 | 3 | 5 | 7 | 11
  ): 1 | 3 | 5 | 7 | 11 {
    return first >= second ? first : second;
  }

  private key(queueType: QueueType, region: string): string {
    return `${queueType}:${region.toUpperCase()}`;
  }
}
