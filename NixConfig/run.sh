#!/bin/bash

# Usage: ./run.sh [app] [--no-proxy|--proxy]
# Examples:
#   ./run.sh kiro           # Auto-detect proxy
#   ./run.sh windsurf       # Auto-detect proxy  
#   ./run.sh kiro --no-proxy    # Force no proxy
#   ./run.sh kiro --proxy       # Force proxy

APP=${1:-kiro}
PROXY_MODE=${2:-auto}

# Function to detect and set proxy
setup_proxy() {
    # Clear existing proxy vars first
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY
    
    # Detect IP from WiFi interface
    WIFI_IP=$(ip route show dev wlp3s0 2>/dev/null | grep default | awk '{print $3}')
    
    # Fallback to other interfaces
    if [ -z "$WIFI_IP" ]; then
        WIFI_IP=$(ip route show default 2>/dev/null | awk '{print $3}')
    fi
    
    if [ ! -z "$WIFI_IP" ]; then
        export http_proxy="http://$WIFI_IP:7890"
        export https_proxy="http://$WIFI_IP:7890"
        export HTTP_PROXY="http://$WIFI_IP:7890"
        export HTTPS_PROXY="http://$WIFI_IP:7890"
        # Don't proxy localhost (important for OAuth callbacks!)
        export no_proxy="localhost,127.0.0.1,::1"
        export NO_PROXY="localhost,127.0.0.1,::1"
        echo "[run.sh] Proxy set to: $WIFI_IP:7890"
    else
        echo "[run.sh] No gateway found, running without proxy"
    fi
}

# Function to clear proxy
clear_proxy() {
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY
    echo "[run.sh] Proxy disabled"
}

# Handle proxy mode
case "$PROXY_MODE" in
    --no-proxy)
        clear_proxy
        ;;
    --proxy)
        setup_proxy
        ;;
    auto|*)
        setup_proxy
        ;;
esac

echo "[run.sh] Starting $APP..."

# Run the app
# exec ~/nixstatic shell --impure --offline nixpkgs/25.05#nodejs nixpkgs/25.05#pnpm nixpkgs/25.05#git .#kiro-wrapped -c bash
exec ~/nixstatic shell --impure --offline nixpkgs/25.05#nodejs nixpkgs/25.05#pnpm nixpkgs/25.05#git .#$APP-wrapped -c bash