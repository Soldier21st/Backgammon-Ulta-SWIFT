export interface BackendConfig {
  port: number;
  host: string;
}

export function loadConfig(): BackendConfig {
  return {
    port: Number(process.env.PORT ?? 8787),
    host: process.env.HOST ?? "0.0.0.0"
  };
}
