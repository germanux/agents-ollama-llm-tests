cd ~/Desarrollo/agents-harness-benchmark/cline-zero-64k

CLINE_SESSION_BACKEND_MODE=local \
cline \
  -s ollama-api-options-ctx-num=65536,request_timeout_ms=300000 \
  --provider ollama \
  --model ornith-cline-64k \
  --auto-approve true \
  --timeout 10800 \
  --retries 20 \
  --cwd "$PWD" \
  --verbose \
  "Read AGENTS.md and BENCHMARK_TASK.md completely and execute the task until BUILD SUCCESS. Be careful with .clineignore."
