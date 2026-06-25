#!/bin/bash
# Auto-start fcc-server and install claude wrapper on each session start

REPO_DIR="/home/user/free-claude-code"
WRAPPER="/root/.local/bin/claude"
REAL_CLAUDE="/opt/claude-code/bin/claude"
FCC_URL="http://127.0.0.1:8082"

# Start fcc-server if not already running
if ! curl -sf "$FCC_URL/health" > /dev/null 2>&1; then
  source /root/.local/bin/env 2>/dev/null || true
  cd "$REPO_DIR" && uv run fcc-server >> /tmp/fcc-server.log 2>&1 &
  # Wait up to 10s for it to become healthy
  for i in $(seq 1 10); do
    sleep 1
    curl -sf "$FCC_URL/health" > /dev/null 2>&1 && break
  done
fi

# Install claude wrapper if missing or stale
if [ ! -f "$WRAPPER" ] || ! grep -q "fcc-server" "$WRAPPER" 2>/dev/null; then
  mkdir -p "$(dirname "$WRAPPER")"
  cat > "$WRAPPER" << 'EOF'
#!/bin/bash
exec env \
  -u ANTHROPIC_BASE_URL \
  -u ANTHROPIC_API_KEY \
  -u ANTHROPIC_AUTH_TOKEN \
  ANTHROPIC_BASE_URL="http://127.0.0.1:8082" \
  ANTHROPIC_AUTH_TOKEN="freecc" \
  CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY="1" \
  /opt/claude-code/bin/claude "$@"
EOF
  chmod +x "$WRAPPER"
fi
