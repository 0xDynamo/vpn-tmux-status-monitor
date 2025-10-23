# VPN Status Monitor with `systemd` and `tmux`

This project sets up a script that monitors VPN connection status, displays it in the `tmux` status bar, and updates dynamically using `systemd` timers. The goal is to provide a lightweight, efficient solution for monitoring VPN connections in real-time using `tmux`.

## Prerequisites

* **tmux** installed and configured
* **systemd** available on your system (most Linux distributions include this by default)
* Basic shell scripting knowledge

## Step-by-Step Setup

### 1. Create the VPN Status Script

1. Create the Bash script that checks the VPN status. We'll monitor the `tun0` interface (adjust as needed).

   Save the following script as `vpn_status.sh` under `/home/$USER/`:

   ```bash
   #!/bin/bash

   # Path to store VPN status output
   STATUS_FILE="$HOME/vpn_status_output.txt"

   # Function to safely refresh tmux
   refresh_tmux() {
       if command -v tmux >/dev/null 2>&1 && tmux ls >/dev/null 2>&1; then
           tmux refresh-client -S
       fi
   }

   # Check VPN status and get IP address
   ip=$(/usr/sbin/ifconfig tun0 2>/dev/null | awk '/inet /{print $2}')
   if [[ -n "$ip" ]]; then
       echo "$ip" > "$STATUS_FILE"
   else
       echo "Disconnected" > "$STATUS_FILE"
   fi

   refresh_tmux
   ```

2. Make the script executable:

   ```bash
   chmod +x /home/$USER/vpn_status.sh
   ```

---

### 2. Configure tmux to Display VPN Status

1. Edit your tmux configuration file (`~/.tmux.conf`) and add the following line to display the VPN status:

   ```bash
   set -g status-right "VPN: #(cat /home/$USER/vpn_status_output.txt) | #(whoami)@#(hostname -s)"
   ```

2. Reload tmux:

   ```bash
   tmux source ~/.tmux.conf
   ```

---

### 3. Create the `systemd` Service

1. Create a new `systemd` service file at `/etc/systemd/system/vpn-status@.service`:

   ```ini
   [Unit]
   Description=VPN Status Monitor Service (%i)
   After=network-online.target
   Wants=network-online.target

   [Service]
   Type=oneshot
   User=%i
   Group=%i
   WorkingDirectory=/home/%i
   ExecStart=/bin/bash /home/%i/vpn_status.sh
   StandardOutput=journal
   StandardError=journal

   [Install]
   WantedBy=multi-user.target
   ```

---

### 4. Create the `systemd` Timer

1. Create a timer file at `/etc/systemd/system/vpn-status@.timer` to run the service every 5 seconds:

   ```ini
   [Unit]
   Description=Run VPN Status Monitor for %i every 5 seconds

   [Timer]
   OnBootSec=5s
   OnUnitActiveSec=5s
   AccuracySec=1s
   Unit=vpn-status@%i.service

   [Install]
   WantedBy=timers.target
   ```

---

### 5. Enable and Start the Service and Timer

1. Reload the `systemd` daemon to recognize the new service and timer:

   ```bash
   sudo systemctl daemon-reload
   ```

2. Enable and start the timer instance for your user (replace `dynamo` with your username if different):

   ```bash
   sudo systemctl enable vpn-status@dynamo.timer
   sudo systemctl start vpn-status@dynamo.timer
   ```

3. Check the status of the timer and service:

   ```bash
   systemctl status vpn-status@dynamo.timer
   systemctl status vpn-status@dynamo.service
   ```

---

### 6. Verify VPN Status in tmux

1. Open tmux and confirm that the VPN status is displayed on the right side of the tmux status bar.
   The status should update automatically every 5 seconds.

---

### 7. Debugging and Logs

To check logs or troubleshoot any issues:

```bash
journalctl -xe
journalctl -u vpn-status@dynamo.service -n 10 --no-pager
```


