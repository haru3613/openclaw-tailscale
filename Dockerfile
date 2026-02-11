FROM ghcr.io/openclaw/openclaw:2026.2.9  
# 切換到 root 用戶以安裝 Tailscale  
USER root  
# 安裝 Tailscale  
RUN apt-get update && apt-get install -y tailscale && rm -rf /var/lib/apt/lists/*  
# 切換回原始用戶  
USER node  
# 創建啟動腳本  
RUN mkdir -p /app/scripts  
RUN cat > /app/scripts/entrypoint.sh << 'EOF'  
#!/bin/bash  
set -e  
# 啟動 Tailscale daemon  
echo "Starting Tailscale daemon..."  
tailscaled --tun=userspace-networking &  
TAILSCALED_PID=$!  
# 等待 tailscaled 啟動  
sleep 2  
# 使用環境變數連接到 Tailscale  
if [ -n "$TS_AUTHKEY" ]; then  
    echo "Connecting to Tailscale with auth key..."  
    tailscale up \  
        --authkey="$TS_AUTHKEY" \  
        --hostname="${TS_HOSTNAME:-openclaw}" \  
        --accept-dns=false \  
        --accept-routes=false  
    echo "Tailscale connected successfully"  
else  
    echo "Warning: TS_AUTHKEY not set, Tailscale will not auto-connect"  
fi  
# 啟動 OpenClaw  
echo "Starting OpenClaw..."  
exec node /home/node/bin/openclaw.js  
EOF  
RUN chmod +x /app/scripts/entrypoint.sh  
# 設置新的入口點  
ENTRYPOINT ["/app/scripts/entrypoint.sh"]  
