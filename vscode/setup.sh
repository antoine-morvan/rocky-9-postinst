#!/usr/bin/env bash
set -e -u -o pipefail

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

cat << EOF | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null 
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

sudo dnf install code
