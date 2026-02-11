FROM tailscale/tailscale:latest

RUN mkdir -p /app /var/lib/tailscale /var/run/tailscale

RUN cat > /app/entrypoint.sh << 'EOF'
#!/bin/sh
set -e

if [ -z "$TS_AUTHKEY" ]; then
    echo "Error: TS_AUTHKEY is required"
    exit 1
fi

echo "Starting tailscaled (userspace networking)..."
tailscaled \
    --tun=userspace-networking \
    --statedir=/var/lib/tailscale \
    --socket=/var/run/tailscale/tailscaled.sock &
TAILSCALED_PID=$!

# Wait for tailscaled socket to be ready
echo "Waiting for tailscaled to be ready..."
for i in $(seq 1 15); do
    if tailscale status >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

echo "Connecting to Tailscale network..."
tailscale up \
    --authkey="$TS_AUTHKEY" \
    --hostname="${TS_HOSTNAME:-openclaw-proxy}" \
    --accept-dns=false \
    --accept-routes=false

echo "Tailscale connected:"
tailscale status

# Configure reverse proxy: expose openclaw service via Tailscale serve
# Accessible at https://<hostname>.tail3d8d9e.ts.net
echo "Configuring reverse proxy to openclaw-pernal.zeabur.internal:18789 ..."
tailscale serve --bg / http://openclaw-pernal.zeabur.internal:18789

echo "Current Tailscale Serve status:"
tailscale serve status

echo "Reverse proxy is active."
echo "Access at: https://${TS_HOSTNAME:-openclaw-proxy}.tail3d8d9e.ts.net"

wait $TAILSCALED_PID
EOF

RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
