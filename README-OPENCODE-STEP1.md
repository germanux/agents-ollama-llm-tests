# OpenCode — Step 1: local, pinned, restrictive bootstrap

Copy the contents of this bundle into the repository root, preserving paths. Then run:

```bash
node scripts/setup-opencode.mjs
npm run opencode:version
npm run opencode:paths
npm run opencode:config
```

The bootstrap:

- installs `opencode-ai@1.18.3` as an exact local dev dependency;
- creates `package-lock.json` through npm;
- starts with the built-in `plan` agent;
- disables subagents, shell, edits, web access, LSP, skills and external directories;
- reuses the existing project `AGENTS.md` automatically;
- uses a Node launcher instead of Bash-specific environment syntax;
- isolates config/data/cache/state under `.opencode-runtime/` on Linux/WSL;
- disables Claude compatibility and automatic LSP downloads;
- adds `node_modules/` and `.opencode-runtime/` to `.gitignore`.

Do not run a coding task yet. Step 2 will add the Ollama provider and one selected laptop model, then run a read-only smoke test.
