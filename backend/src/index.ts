import { createServer } from "node:http";
import { URL } from "node:url";
import { WebSocket, WebSocketServer } from "ws";
import { loadConfig } from "./config";
import { ClientRegistry } from "./state/clientRegistry";
import { MatchmakingService } from "./services/matchmaking";
import { GameSessionService } from "./services/gameSession";
import { ModerationService } from "./services/moderation";
import { RatingStore } from "./services/ratingStore";
import { handleClientMessage } from "./ws/handler";

const config = loadConfig();
const clients = new ClientRegistry();
const matchmaking = new MatchmakingService();
const gameSessions = new GameSessionService();
const moderation = new ModerationService();
const ratings = new RatingStore();
const pendingSocketUsers = new WeakMap<WebSocket, string>();

const server = createServer((req, res) => {
  if (req.url === "/health") {
    res.statusCode = 200;
    res.setHeader("content-type", "application/json");
    res.end(JSON.stringify({ ok: true, uptime: process.uptime() }));
    return;
  }

  res.statusCode = 404;
  res.setHeader("content-type", "application/json");
  res.end(JSON.stringify({ error: "Not Found" }));
});

const wss = new WebSocketServer({ noServer: true });

wss.on("connection", (socket: WebSocket) => {
  const userId = pendingSocketUsers.get(socket);
  if (!userId) {
    socket.close();
    return;
  }
  clients.register(userId, socket);

  socket.on("message", (raw) => {
    const rawText = typeof raw === "string" ? raw : raw.toString();
    handleClientMessage(userId, rawText, {
      clients,
      matchmaking,
      gameSessions,
      moderation,
      ratings
    });
  });

  socket.on("close", () => {
    const disconnectedUserId = clients.removeSocket(socket);
    if (disconnectedUserId) {
      matchmaking.removeByUser(disconnectedUserId);
    }
  });
});

server.on("upgrade", (request, socket, head) => {
  const hostHeader = request.headers.host ?? "localhost";
  const requestURL = new URL(request.url ?? "/", `http://${hostHeader}`);
  if (requestURL.pathname !== "/ws") {
    socket.write("HTTP/1.1 404 Not Found\r\n\r\n");
    socket.destroy();
    return;
  }

  const userId = requestURL.searchParams.get("userId");
  if (!userId) {
    socket.write("HTTP/1.1 401 Unauthorized\r\n\r\n");
    socket.destroy();
    return;
  }

  wss.handleUpgrade(request, socket, head, (upgradedSocket) => {
    pendingSocketUsers.set(upgradedSocket, userId);
    wss.emit("connection", upgradedSocket, request);
  });
});

server.listen(config.port, config.host, () => {
  // eslint-disable-next-line no-console
  console.log(`[backend] listening on ${config.host}:${config.port}`);
});
