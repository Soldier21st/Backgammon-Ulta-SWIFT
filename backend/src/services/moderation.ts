import { randomUUID } from "node:crypto";

export interface ModerationReport {
  id: string;
  reporterUserId: string;
  reportedUserId: string;
  matchId: string;
  reason: string;
  createdAt: number;
}

export class ModerationService {
  private readonly reports: ModerationReport[] = [];

  createReport(input: Omit<ModerationReport, "id" | "createdAt">): ModerationReport {
    const report: ModerationReport = {
      ...input,
      id: randomUUID(),
      createdAt: Date.now()
    };
    this.reports.push(report);
    return report;
  }

  listReportsForUser(userId: string): ModerationReport[] {
    return this.reports.filter((item) => item.reportedUserId === userId);
  }
}
