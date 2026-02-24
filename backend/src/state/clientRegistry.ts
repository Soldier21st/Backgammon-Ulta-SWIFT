import { WebSocket } from "ws";
import { ServerMessage } from "../domain/protocol";

export class ClientRegistry {
  private readonly socketsByUser = new Map<string, Set<WebSocket>>();
  private readonly userBySocket = new Map<WebSocket, string>();

  register(userId: string, socket: WebSocket): void {
    const bucket = this.socketsByUser.get(userId) ?? new Set<WebSocket>();
    bucket.add(socket);
    this.socketsByUser.set(userId, bucket);
    this.userBySocket.set(socket, userId);
  }

  removeSocket(socket: WebSocket): string | undefined {
    const userId = this.userBySocket.get(socket);
    if (!userId) {
      return undefined;
    }
    this.userBySocket.delete(socket);
    const bucket = this.socketsByUser.get(userId);
    if (!bucket) {
      return userId;
    }
    bucket.delete(socket);
    if (bucket.size === 0) {
      this.socketsByUser.delete(userId);
    } else {
      this.socketsByUser.set(userId, bucket);
    }
    return userId;
  }

  send(userId: string, message: ServerMessage): void {
    const sockets = this.socketsByUser.get(userId);
    if (!sockets || sockets.size === 0) {
      return;
    }
    const payload = JSON.stringify(message);
    for (const socket of sockets) {
      if (socket.readyState === WebSocket.OPEN) {
        socket.send(payload);
      }
    }
  }

  broadcast(userIds: Iterable<string>, message: ServerMessage): void {
    for (const userId of userIds) {
      this.send(userId, message);
    }
  }

  userIdForSocket(socket: WebSocket): string | undefined {
    return this.userBySocket.get(socket);
  }
}
