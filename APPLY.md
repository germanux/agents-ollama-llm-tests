# Apply

Replace the matching project files with this package, **except** `.opencode/opencode.json`.

Keep that file under control of the existing Ollama/OpenCode setup script. Run the script already used on each machine so that it:

1. Recreates the Ollama aliases from `.ollama-modelfiles/`.
2. Regenerates `.opencode/opencode.json` with the detected model catalog.
3. Writes the authoritative `limit.context` and `limit.output` values.

The root `opencode.jsonc` now contains only the stable provider endpoints and general project settings. It does not duplicate model context or output limits.

Restart OpenCode after the script finishes. Select `benchmark-pc` for the desktop model or `benchmark-local` for the laptop model.
