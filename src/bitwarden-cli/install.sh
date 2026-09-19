#!/bin/sh
set -e

SERVER="${SERVER}"
WEB_VAULT="${WEB_VAULT}"
API="${API}"
IDENTITY="${IDENTITY}"
ICONS="${ICONS}"
NOTIFICATIONS="${NOTIFICATIONS}"
EVENTS="${EVENTS}"
KEY_CONNECTOR="${KEY_CONNECTOR}"

REQUIRED_PACKAGES="curl unzip sudo ca-certificates"
BW_URL="https://vault.bitwarden.com/download/?app=cli&platform=linux"
TARGET_PATH=/usr/local/bin/bw

apt_get_update()
{
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

export DEBIAN_FRONTEND=noninteractive

if ! command -v apt-get >/dev/null 2>&1; then
    echo "This feature requires a Debian/Ubuntu base image (apt-get not found)." >&2
    exit 1
fi

check_packages $REQUIRED_PACKAGES

install() {
    curl -L "${BW_URL}" -o bw.zip

    unzip bw.zip
    rm bw.zip

    chmod a+x bw
    mv bw $TARGET_PATH
}

configure() {
    configCmd="sudo -u ${_REMOTE_USER} -i ${TARGET_PATH} config server"

    [ "${SERVER}" != "" ] && configCmd="${configCmd} ${SERVER}"
    [ "${WEB_VAULT}" != "" ] && configCmd="${configCmd} --web-vault ${WEB_VAULT}"
    [ "${API}" != "" ] && configCmd="${configCmd} --api ${API}"
    [ "${IDENTITY}" != "" ] && configCmd="${configCmd} --identity ${IDENTITY}"
    [ "${ICONS}" != "" ] && configCmd="${configCmd} --icons ${ICONS}"
    [ "${NOTIFICATIONS}" != "" ] && configCmd="${configCmd} --notifications ${NOTIFICATIONS}"
    [ "${EVENTS}" != "" ] && configCmd="${configCmd} --events ${EVENTS}"
    [ "${KEY_CONNECTOR}" != "" ] && configCmd="${configCmd} --key-connector ${KEY_CONNECTOR}"

    $configCmd
}

echo "(*) Installing Bitwarden CLI..."

install

if [ "${SERVER}" != "" ] || [ "${WEB_VAULT}" != "" ] || [ "${API}" != "" ] || [ "${IDENTITY}" != "" ] || [ "${ICONS}" != "" ] || [ "${NOTIFICATIONS}" != "" ] || [ "${EVENTS}" != "" ] || [ "${KEY_CONNECTOR}" != "" ]; then
    echo "(*) Configure custom Bitwarden server..."
    configure
fi

# Clean up
rm -rf /var/lib/apt/lists/*

# Smoke test: fail the build if the binary did not install correctly
echo "(*) Verifying Bitwarden CLI installation..."
bw --version

echo "Done!"
