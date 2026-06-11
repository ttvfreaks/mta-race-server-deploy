#!/bin/bash

# 0. Clone repo
cd ~
git clone https://github.com/ttvfreaks/mta-race-server-deploy.git

# 1. Download and unpack MTA Server 1.6
wget https://linux.multitheftauto.com/dl/multitheftauto_linux_x64.tar.gz
mkdir -p ~/mta_server
tar -xvzf multitheftauto_linux_x64.tar.gz -C ~/mta_server
rm -f multitheftauto_linux_x64.tar.gz

# 2. Download The123robot's server
git clone https://gitlab.com/The123robot/robot-mta-server.git

# 3. Extract gamemode and configs
rm -rf ~/mta_server/mods/deadmatch/
cp ~/robot-mta-server ~/mta_server/mods/deadmatch/
\cp 