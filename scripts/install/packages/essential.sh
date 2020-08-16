#!/bin/bash

# Essential packages

APT_PACKAGES_ESSENTIAL=(
"build-essential"
"libssl-dev"
"libffi-dev"
"curl"
"wget"
"zip"
"unzip"
"git"
"vim"
"gnupg2"
"net-tools"
)

echolog
echolog "${UL_NC}Installing Essential Packages${NC}"
echolog

sudo apt-add-repository universe -y

apt_bulk_install "${APT_PACKAGES_ESSENTIAL[@]}"

