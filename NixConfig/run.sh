#!/bin/bash


unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY
# Detect IP
WIFI_IP=$(ip route show dev wlp3s0 | grep default | awk '{print $3}')

# Set vars
if [ ! -z "$WIFI_IP" ]; then
    export http_proxy=http://$WIFI_IP:7890
    export https_proxy=http://$WIFI_IP:7890
    export HTTP_PROXY=http://$WIFI_IP:7890
    export HTTPS_PROXY=http://$WIFI_IP:7890
fi

# Run the specific app passed as argument, or default to Kiro
APP=${1:-kiro} 

# Use nixstatic to run the app from the local flake
# Note: We use 'path:.' to reference the flake in the current dir
# cd ~/NixConfig
# exec ~/nixstatic run .#$APP --impure -- --no-sandbox
# exec ~/nixstatic run .#$APP --impure -- --no-sandbox
exec ~/nixstatic shell --impure --offline nixpkgs/25.05#nodejs nixpkgs/25.05#pnpm nixpkgs/25.05#git .#kiro-wrapped -c bash