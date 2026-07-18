CLINE ON LAPTOP -> REMOTE OLLAMA ON PC

1. Edit agent-lab.conf once:
   PC_IP, LAPTOP_IP and optionally model/timeouts.

2. On the PC running Ollama:
   chmod 755 configure-ollama-lan.sh
   ./configure-ollama-lan.sh

3. Copy the four files into the benchmark repository on the laptop.

4. On the laptop:
   chmod 755 setup-cline-laptop.sh
   ./setup-cline-laptop.sh

5. Run the benchmark:
   ./launch-cline-remote.sh

The scripts take no command-line IP/model arguments. They all read agent-lab.conf.

SECURITY
- Ollama binds to the PC's fixed LAN IP, not 0.0.0.0.
- If UFW is active, only LAPTOP_IP is allowed to reach port 11434.
- Router port forwarding must remain disabled.
- If UFW is inactive, set ENABLE_UFW_IF_INACTIVE=true only after reviewing SSH rules.

CONTEXT
- This remote Cline test intentionally does not create or install Ollama on the laptop.
- Cline CLI 3.0.44 has been observed loading Ornith at 32768 even when the model alias declares 65536.
- The updated memorandum confirms that larger context is working memory, not extra intelligence.
- For a later local-laptop run, 16K is the sensible first target because the laptop has 32 GB RAM.
