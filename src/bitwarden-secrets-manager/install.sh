#!/bin/sh
set -e

SERVER_BASE="${SERVER_BASE}"
SERVER_API="${SERVER_API}"
SERVER_IDENTITY="${SERVER_IDENTITY}"

REQUIRED_PACKAGES="curl unzip sudo ca-certificates jq"
TARGET_PATH=/usr/local/bin/bws

error() {
    echo "$1" >&2
    echo "Exiting..." >&2
    exit 1
}

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

platform_detect() {
    if [ "$(uname -s)" = "Linux" ]; then
        PLATFORM="unknown-linux-gnu"
    elif [ "$(uname -s)" = "Darwin" ]; then
        PLATFORM="apple-darwin"
    else
        error "Unsupported platform: $(uname -s)"
    fi
}

arch_detect() {
    if [ "$(uname -m)" = "x86_64" ]; then
        ARCH="x86_64"
    elif [ "$(uname -m)" = "aarch64" ]; then # Linux
        ARCH="aarch64"
    elif [ "$(uname -m)" = "arm64" ]; then # Darwin/macOS
        ARCH="aarch64"
    else
        error "Unsupported architecture: $(uname -m)"
    fi
}

github_api_get() {
    # Resilient GitHub API GET: retries with backoff, and only accepts a
    # response for which the jq predicate $2 is true. This rejects GitHub's
    # rate-limit error body (also an object). Uses GITHUB_TOKEN when present.
    _url="$1"
    _valid="$2"
    _attempt=0
    while [ "$_attempt" -lt 4 ]; do
        _attempt=$((_attempt + 1))
        if [ -n "${GITHUB_TOKEN:-}" ]; then
            _resp="$(curl -fsSL -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${GITHUB_TOKEN}" "$_url" 2>/dev/null)" || _resp=""
        else
            _resp="$(curl -fsSL -H "Accept: application/vnd.github+json" "$_url" 2>/dev/null)" || _resp=""
        fi
        if [ -n "$_resp" ] && printf '%s' "$_resp" | jq -e "$_valid" >/dev/null 2>&1; then
            printf '%s' "$_resp"
            return 0
        fi
        sleep $(( _attempt * 3 + $$ % 4 ))
    done
    return 1
}

export DEBIAN_FRONTEND=noninteractive

if ! command -v apt-get >/dev/null 2>&1; then
    error "This feature requires a Debian/Ubuntu base image (apt-get not found)."
fi

check_packages $REQUIRED_PACKAGES

if [ -z "${VERSION:-}" ]; then
    RELEASES_JSON="$(github_api_get "https://api.github.com/repos/bitwarden/sdk-sm/releases?per_page=100" 'type == "array" and ([.[] | select((.tag_name // "") | startswith("bws-"))] | length > 0)')" \
        || error "Could not resolve the latest bws version from the GitHub API (rate limited?). Pin the 'version' option to install a specific release."
    CURRENT_TAG="$(printf '%s' "$RELEASES_JSON" | jq --raw-output '[.[] | select(.draft == false) | select(.prerelease == false) | select(.tag_name | startswith("bws-")) | .tag_name][0]')"
    VERSION="${CURRENT_TAG#bws-v}"
fi

platform_detect
arch_detect

install() {
    curl -L "https://github.com/bitwarden/sdk-sm/releases/download/bws-v${VERSION}/bws-${ARCH}-${PLATFORM}-${VERSION}.zip" -o bws.zip

    unzip bws.zip
    rm bws.zip

    chmod a+x bws
    mv bws $TARGET_PATH
}

configure() {
    configCmd="sudo -u ${_REMOTE_USER} -i ${TARGET_PATH} config"

    [ "${SERVER_BASE}" != "" ] && $configCmd server-base $SERVER_BASE
    [ "${SERVER_API}" != "" ] && $configCmd server-api $SERVER_API
    [ "${SERVER_IDENTITY}" != "" ] && $configCmd server-identity $SERVER_IDENTITY

    return 0
}

echo "(*) Installing Bitwarden Secrets Manager CLI..."

install

if [ "${SERVER_BASE}" != "" ] || [ "${SERVER_API}" != "" ] || [ "${SERVER_IDENTITY}" != "" ]; then
    echo "(*) Configure custom Bitwarden server URLs..."
    configure
fi

# Clean up
rm -rf /var/lib/apt/lists/*

# Smoke test: fail the build if the binary did not install correctly
echo "(*) Verifying Bitwarden Secrets Manager CLI installation..."
bws --version

echo "Done!"
