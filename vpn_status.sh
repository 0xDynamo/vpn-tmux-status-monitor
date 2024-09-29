#!/bin/bash

# Path to your .tmux.conf
TMUX_CONF="$HOME/.tmux.conf"
STATUS_FILE="$HOME/vpn_status_output.txt"

# Function to update tmux status-right for VPN connected, displaying the IP address
update_tmux_for_vpn_connected() {
    local vpn_ip=$1
    echo "$vpn_ip" > "$STATUS_FILE"  # Write IP to the status file
    tmux source "$TMUX_CONF"
}

# Function to update tmux status-right for VPN disconnected
update_tmux_for_vpn_disconnected() {
    echo "Disconnected" > "$STATUS_FILE"  # Write "Disconnected" to the status file
    tmux source "$TMUX_CONF"
}

# Check VPN status and get IP address
ip=$(/usr/sbin/ifconfig tun0 2>/dev/null | grep 'inet ' | awk '{print $2}')
if [ -n "$ip" ]; then
    echo "VPN: $ip"
    update_tmux_for_vpn_connected "$ip"
else
    echo "VPN: Disconnected"
    update_tmux_for_vpn_disconnected
fi