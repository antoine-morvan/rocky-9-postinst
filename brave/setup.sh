#!/usr/bin/env bash
set -e -u -o pipefail

sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo

sudo dnf install brave-browser
