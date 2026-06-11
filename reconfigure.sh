#!/bin/bash
set -e

REPO_DIR="$HOME/mta-race-server-deploy"
MTA_DIR="$HOME/mta_server"
DEATHMATCH_DIR="$MTA_DIR/mods/deathmatch"

# Check if repo exists
if [ ! -d "$REPO_DIR" ]; then
    echo "Ошибка: репозиторий config не найден в $REPO_DIR"
    echo "Сначала запустите deploy.sh"
    exit 1
fi

cd "$REPO_DIR"

# Ask for server password
echo ""
echo "Текущий пароль: $(grep -oP '(?<=<password>).*(?=</password>)' deathmatch/mtaserver.conf)"
read -rsp "[1] Введи новый пароль сервера (Enter — оставить без изменений): " SERVER_PASSWORD </dev/tty
echo

# If empty, keep current password
if [ -z "$SERVER_PASSWORD" ]; then
    SERVER_PASSWORD=$(grep -oP '(?<=<password>).*(?=</password>)' deathmatch/mtaserver.conf)
    echo "[1] Пароль оставлен без изменений: $SERVER_PASSWORD"
else
    echo "[1] Новый пароль принят"
fi

# Write password to config
sed -i "s|<password>.*</password>|<password>$SERVER_PASSWORD</password>|" deathmatch/mtaserver.conf
echo "[2] Пароль записан в mtaserver.conf"

# Copy config to server
echo "[3] Копирую конфиги на сервер..."
cp -r deathmatch/. "$DEATHMATCH_DIR/"

# Restart server
echo "[4] Перезапускаю сервер через screen..."

# Остановить существующий экран, если запущен
if command -v screen &>/dev/null && screen -ls | grep -q mta; then
    screen -S mta -X quit
    sleep 2
fi

if ! command -v screen &>/dev/null; then
    echo "Устанавливаю screen..."
    apt-get update -qq && apt-get install -y -qq screen
fi

screen -dmS mta "$MTA_DIR/mta-server64"
sleep 2

SERVER_PID=$(pgrep -f "$MTA_DIR/mta-server64$" | head -1)
echo "$SERVER_PID" > "$MTA_DIR/mta-server.pid"

# Get IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

echo ""
echo "================ ПЕРЕНАСТРОЙКА ГОТОВА ================"
echo "PID сервера:       $SERVER_PID"
echo "IP и порт:         mtasa://$SERVER_IP:22003"
echo " (открой в браузере — запустит игру и подключит к серверу)"
echo "Пароль:            $SERVER_PASSWORD"
echo "Консоль сервера:   screen -r mta"
echo "Отключиться:       Ctrl+A, затем D"
echo "======================================================"