#!/bin/bash
set -e

REPO_DIR="$HOME/mta-race-server-deploy"
MTA_DIR="$HOME/mta_server"
DEATHMATCH_DIR="$MTA_DIR/mods/deathmatch"

# 0. Clone or pull this repo
cd "$HOME"
if [ -d "$REPO_DIR" ]; then
    echo "[0] Репозиторий config уже есть, обновляю..."
    git -C "$REPO_DIR" pull
else
    echo "[0] Клонирую репозиторий config..."
    git clone https://github.com/ttvfreaks/mta-race-server-deploy.git
fi

# 1. Ask for server password
# read -rsp "[1] Введи пароль сервера (Enter — оставить без пароля): " SERVER_PASSWORD </dev/tty
# echo

# 2. Write password to config
# sed -i "s|<password>.*</password>|<password>$SERVER_PASSWORD</password>|" "$REPO_DIR/deathmatch/mtaserver.conf"
# echo "[2] Пароль записан в mtaserver.conf"

# 3. Download and unpack MTA Server (если ещё нет)
if [ -f "$MTA_DIR/mta-server64" ]; then
    echo "[3] MTA сервер уже скачан, пропускаю"
else
    echo "[3] Скачиваю MTA сервер..."
    wget -q https://linux.multitheftauto.com/dl/multitheftauto_linux_x64.tar.gz
    mkdir -p "$MTA_DIR"
    tar -xzf multitheftauto_linux_x64.tar.gz -C "$MTA_DIR" --strip-components=1
    rm -f multitheftauto_linux_x64.tar.gz
    echo "[3] MTA сервер распакован в $MTA_DIR"
fi

# 4. Clone robot-mta-server and extract into deathmatch
echo "[4] Клонирую robot-mta-server..."
rm -rf "$HOME/robot-mta-server"
rm -rf "$DEATHMATCH_DIR/resources"
mkdir -p "$DEATHMATCH_DIR/resources"
git clone --depth 1 https://gitlab.com/The123robot/robot-mta-server.git "$HOME/robot-mta-server"
cp -r "$HOME/robot-mta-server/." "$DEATHMATCH_DIR/resources"
rm -rf "$HOME/robot-mta-server"
echo "[4] robot-mta-server скопирован в $DEATHMATCH_DIR"

# 5. Copy our config files to replace defaults
echo "[5] Копирую свои конфиги поверх..."
cp -r "$REPO_DIR/deathmatch/." "$DEATHMATCH_DIR/"

# 6. Start or restart server
echo "[6] Запускаю сервер в фоне..."

# Остановить предыдущий процесс, если есть
if [ -f "$MTA_DIR/mta-server.pid" ]; then
    OLD_PID=$(cat "$MTA_DIR/mta-server.pid")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "Останавливаю старый процесс (PID: $OLD_PID)..."
        kill "$OLD_PID" 2>/dev/null || true
        sleep 2
    fi
fi

# Запускаем сервер в фоне и пишем PID
nohup "$MTA_DIR/mta-server64" > "$MTA_DIR/mta-server.log" 2>&1 &
SERVER_PID=$!
echo "$SERVER_PID" > "$MTA_DIR/mta-server.pid"
sleep 3

# Проверяем, жив ли процесс
if kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "Сервер запущен (PID: $SERVER_PID)"
else
    echo "ОШИБКА: Сервер не запустился. Лог:"
    tail -20 "$MTA_DIR/mta-server.log"
fi

# Пробуем узнать IP (в Colab работает curl ifconfig.me)
SERVER_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || curl -s --max-time 5 v4.ident.me 2>/dev/null || echo "127.0.0.1")

echo ""
echo "================ ГОТОВО ================="
echo "PID сервера:       $SERVER_PID"
echo "IP и порт:         mtasa://$SERVER_IP:22003"
echo "      открой в браузере — запустит игру и подключит к серверу"
echo "Пароль:            ETO_DURKA"
echo "Лог сервера:       tail -f $MTA_DIR/mta-server.log"
echo "Остановить:        kill \$(cat $MTA_DIR/mta-server.pid)"
echo "========================================="
