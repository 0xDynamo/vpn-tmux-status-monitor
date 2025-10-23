#!/bin/bash

# Path to store VPN status output
STATUS_FILE="$HOME/vpn_status_output.txt"

# Function to update tmux status-right for VPN connected, displaying the IP address
update_tmux_for_vpn_connected() {
    local vpn_ip=$1
    echo "$vpn_ip" > "$STATUS_FILE"  # Write IP to the status file
    # Light refresh instead of reloading the entire config
    if command -v tmux >/dev/null 2>&1 && tmux ls >/dev/null 2>&1; then
        tmux refresh-client -S >/dev/null 2>&1 || true
    fi
}

# Function to update tmux status-right for VPN disconnected
update_tmux_for_vpn_disconnected() {
    echo "Disconnected" > "$STATUS_FILE"  # Write "Disconnected" to the status file
    # Light refresh instead of reloading the entire config
    if command -v tmux >/dev/null 2>&1 && tmux ls >/dev/null 2>&1; then
        tmux refresh-client -S >/dev/null 2>&1 || true
    fi
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
