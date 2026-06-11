#!/bin/bash
set -e

REPO_DIR="$HOME/mta-race-server-deploy"
MTA_DIR="$HOME/mta_server"
DEATHMATCH_DIR="$MTA_DIR/mods/deathmatch"

# 0. Clone this repo
cd "$HOME"
if [ ! -d "$REPO_DIR" ]; then
    git clone https://github.com/ttvfreaks/mta-race-server-deploy.git
fi

# 1. Ask for server password (read from /dev/tty so it works with curl pipe)
read -rsp "Введи свой пароль для сервера MTA (можно оставить пустым) " SERVER_PASSWORD </dev/tty
echo

# 2. Write password to config
sed -i "s|<password>.*</password>|<password>$SERVER_PASSWORD</password>|" "$REPO_DIR/deathmatch/mtaserver.conf"

# 3. Download and unpack MTA Server
wget -q https://linux.multitheftauto.com/dl/multitheftauto_linux_x64.tar.gz
mkdir -p "$MTA_DIR"
tar -xzf multitheftauto_linux_x64.tar.gz -C "$MTA_DIR" --strip-components=1
rm -f multitheftauto_linux_x64.tar.gz

# 4. Clone robot-mta-server and extract into deathmatch
rm -rf "$DEATHMATCH_DIR"
mkdir -p "$DEATHMATCH_DIR"
git clone --depth 1 https://gitlab.com/The123robot/robot-mta-server.git "$HOME/robot-mta-server"
cp -r "$HOME/robot-mta-server/." "$DEATHMATCH_DIR/"
rm -rf "$HOME/robot-mta-server"

# 5. Copy our config files to replace defaults
cp -r "$REPO_DIR/deathmatch/." "$DEATHMATCH_DIR/"

# 6. Start server and show info
"$MTA_DIR/mta-server" &
SERVER_PID=$!

sleep 2

SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

echo "PID сервера:  $SERVER_PID"
echo "IP и порт:    $SERVER_IP:22003"
echo "Пароль:       $SERVER_PASSWORD"
