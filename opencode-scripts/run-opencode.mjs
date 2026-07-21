#!/usr/bin/env node
import { existsSync, mkdirSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawn } from "node:child_process";

const scriptDir = dirname(fileURLToPath(import.meta.url));
const rootDir = resolve(scriptDir, "..");
const runtime = join(rootDir, ".opencode-runtime");
const binary = join(
    rootDir,
  "node_modules",
  ".bin",
  process.platform === "win32" ? "opencode.cmd" : "opencode",
);

if (!existsSync(binary)) {
  console.error("[error] Local OpenCode binary not found. Run: node opencode-scripts/setup-opencode.mjs");
  process.exit(1);
}

for (const directory of ["config", "data", "cache", "state"]) {
  mkdirSync(join(runtime, directory), { recursive: true });
}

const env = {
  ...process.env,
  OPENCODE_CONFIG: join(rootDir, "opencode.jsonc"),
  OPENCODE_DISABLE_CLAUDE_CODE: "1",
  OPENCODE_DISABLE_LSP_DOWNLOAD: "true",
  XDG_CONFIG_HOME: join(runtime, "config"),
  XDG_DATA_HOME: join(runtime, "data"),
  XDG_CACHE_HOME: join(runtime, "cache"),
  XDG_STATE_HOME: join(runtime, "state"),
};

const child = spawn(binary, process.argv.slice(2), {
  cwd: rootDir,
  env,
  stdio: "inherit",
  shell: process.platform === "win32",
});

child.on("error", (error) => {
  console.error(`[error] Failed to start OpenCode: ${error.message}`);
  process.exit(1);
});

child.on("exit", (code, signal) => {
  if (signal) {
    console.error(`[error] OpenCode terminated by signal ${signal}`);
    process.exit(1);
  }
  process.exit(code ?? 1);
});
