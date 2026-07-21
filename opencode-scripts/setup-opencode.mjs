#!/usr/bin/env node
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { join, resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const scriptDir = dirname(fileURLToPath(import.meta.url));
const rootDir = resolve(scriptDir, "..");

const version = process.env.OPENCODE_VERSION ?? "1.18.3";
const packagePath = join(rootDir, "package.json");
const configPath = join(rootDir, "opencode.jsonc");
const runnerPath = join(scriptDir, "run-opencode.mjs");
const gitignorePath = join(rootDir, ".gitignore");

function fail(message) {
  console.error(`[error] ${message}`);
  process.exit(1);
}

function npmCommand() {
  return process.platform === "win32" ? "npm.cmd" : "npm";
}

if (!existsSync(join(rootDir, "AGENTS.md"))) {
  fail("Run this script from the repository rootDir; AGENTS.md was not found.");
}
if (!existsSync(configPath)) {
  fail("opencode.jsonc was not found. Copy the complete bootstrap bundle into the repository first.");
}
if (!existsSync(runnerPath)) {
  fail("opencode-scripts/run-opencode.mjs was not found. Copy the complete bootstrap bundle into the repository first.");
}

const nodeMajor = Number.parseInt(process.versions.node.split(".")[0], 10);
if (!Number.isFinite(nodeMajor) || nodeMajor < 22) {
  fail(`Node.js 22+ is required by this repository bootstrap. Current: ${process.version}`);
}

let pkg = {
  name: "agents-ollama-llm-test",
  version: "0.0.0",
  private: true,
  description: "Reproducible local coding-agent benchmark with OpenCode and Ollama",
};

if (existsSync(packagePath)) {
  try {
    pkg = JSON.parse(readFileSync(packagePath, "utf8"));
  } catch (error) {
    fail(`package.json is not valid JSON: ${error.message}`);
  }
}

pkg.private = true;
pkg.engines = { ...(pkg.engines ?? {}), node: ">=22 <23" };
pkg.scripts = {
  ...(pkg.scripts ?? {}),
  opencode: "node ./opencode-scripts/run-opencode.mjs",
  "opencode:version": "node ./opencode-scripts/run-opencode.mjs --version",
  "opencode:paths": "node ./opencode-scripts/run-opencode.mjs debug paths",
  "opencode:config": "node ./opencode-scripts/run-opencode.mjs debug config",
};
pkg.devDependencies = {
  ...(pkg.devDependencies ?? {}),
  "opencode-ai": version,
};
writeFileSync(packagePath, `${JSON.stringify(pkg, null, 2)}\n`, "utf8");

const ignoreEntries = ["node_modules/", ".opencode-runtime/"];
let gitignore = existsSync(gitignorePath) ? readFileSync(gitignorePath, "utf8") : "";
for (const entry of ignoreEntries) {
  if (!gitignore.split(/\r?\n/).includes(entry)) {
    if (gitignore.length > 0 && !gitignore.endsWith("\n")) gitignore += "\n";
    gitignore += `${entry}\n`;
  }
}
writeFileSync(gitignorePath, gitignore, "utf8");

console.log(`[setup] Installing opencode-ai@${version} locally...`);
const install = spawnSync(
  npmCommand(),
  ["install", "--save-dev", "--save-exact", `opencode-ai@${version}`],
  { cwd: rootDir, stdio: "inherit", env: process.env },
);
if (install.error) fail(`npm install failed to start: ${install.error.message}`);
if (install.status !== 0) fail(`npm install failed with exit code ${install.status}`);

const verify = spawnSync(
  process.execPath,
  [runnerPath, "--version"],
  { cwd: rootDir, stdio: "inherit", env: process.env },
);
if (verify.error) fail(`OpenCode verification failed to start: ${verify.error.message}`);
if (verify.status !== 0) fail(`OpenCode verification failed with exit code ${verify.status}`);

console.log("[ok] Local OpenCode installation and restrictive baseline are ready.");
console.log("[next] Commit package.json, package-lock.json, opencode.jsonc, opencode-scripts/, and .gitignore.");
