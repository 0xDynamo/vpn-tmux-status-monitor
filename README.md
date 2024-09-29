# VPN Status Monitor with `systemd` and `tmux`

This project sets up a script that monitors VPN connection status, displays it in the `tmux` status bar, and updates dynamically using `systemd` timers. The goal is to provide a lightweight, efficient solution for monitoring VPN connections in real-time using `tmux`.

## Prerequisites
- **tmux** installed and configured
- **systemd** available on your system (most Linux distributions include this by default)
- Basic shell scripting knowledge

## Step-by-Step Setup

### 1. Create the VPN Status Script

1. Create the Bash script that checks the VPN status. We'll monitor the `tun0` interface (adjust as needed).

    Save the following script as `vpn_status.sh` under `/home/dynamo/`:

    ```bash
    #!/bin/bash

    # Path to store VPN status output
    STATUS_FILE="$HOME/vpn_status_output.txt"

    # Function to update VPN status in tmux
    update_tmux_for_vpn_connected() {
        local vpn_ip=$1
        echo "$vpn_ip" > "$STATUS_FILE"  # Write IP to the status file
        tmux refresh-client -S           # Refresh tmux to show updated status
    }

    # Function to update tmux for VPN disconnected
    update_tmux_for_vpn_disconnected() {
        echo "Disconnected" > "$STATUS_FILE"  # Write "Disconnected" to the status file
        tmux refresh-client -S                # Refresh tmux
    }

    # Check VPN status and get IP address
    ip=$(/usr/sbin/ifconfig tun0 2>/dev/null | grep 'inet ' | awk '{print $2}')
    if [ -n "$ip" ]; then
        update_tmux_for_vpn_connected "$ip"
    else
        update_tmux_for_vpn_disconnected
    fi
    ```

2. Make the script executable:
    ```bash
    chmod +x /home/dynamo/vpn_status.sh
    ```

### 2. Configure tmux to Display VPN Status

1. Edit your tmux configuration file (`~/.tmux.conf`) and add the following line to display the VPN status:

    ```bash
    set -g status-right "VPN: #(cat /home/dynamo/vpn_status_output.txt) | #(whoami)@#(hostname -s)"
    ```

2. Reload tmux:
    ```bash
    tmux source ~/.tmux.conf
    ```

### 3. Create the `systemd` Service

1. Create a new `systemd` service file at `/etc/systemd/system/vpn-status.service`:

    ```ini
    [Unit]
    Description=VPN Status Monitor Service

    [Service]
    ExecStart=/bin/bash /home/dynamo/vpn_status.sh
    WorkingDirectory=/home/dynamo
    User=dynamo
    StandardOutput=journal
    StandardError=journal

    [Install]
    WantedBy=multi-user.target
    ```

### 4. Create the `systemd` Timer

1. Create a timer file at `/etc/systemd/system/vpn-status.timer` to run the service every 5 seconds:

    ```ini
    [Unit]
    Description=Run VPN Status Monitor every 5 seconds

    [Timer]
    OnBootSec=5
    OnUnitActiveSec=5
    Unit=vpn-status.service

    [Install]
    WantedBy=timers.target
    ```

### 5. Enable and Start the Service and Timer

1. Reload the `systemd` daemon to recognize the new service and timer:
    ```bash
    sudo systemctl daemon-reload
    ```

2. Enable and start the timer:
    ```bash
    sudo systemctl enable vpn-status.timer
    sudo systemctl start vpn-status.timer
    ```

3. Check the status of the timer and service:
    ```bash
    systemctl status vpn-status.timer
    systemctl status vpn-status.service
    ```

### 6. Verify VPN Status in tmux

1. Open tmux and confirm that the VPN status is displayed on the right side of the tmux status bar. The status should update every 5 seconds.

### 7. Debugging and Logs

To check logs or troubleshoot any issues:
```bash
journalctl -xe
