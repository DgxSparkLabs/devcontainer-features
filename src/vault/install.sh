#!/bin/sh
set -e

SERVER_BASE="${SERVER_BASE}"
SERVER_API="${SERVER_API}"
SERVER_IDENTITY="${SERVER_IDENTITY}"

REQUIRED_PACKAGES="curl unzip sudo ca-certificates jq gpg gpg-agent"
TARGET_PATH=/usr/local/bin/vault

# check: https://developer.hashicorp.com/well-architected-framework/operational-excellence/verify-hashicorp-binary#verify-pgp-key-id-and-fingerprint
GPG_FINGERPRINT="C874011F0AB405110D02105534365D9472D7468F"

PRODUCT="vault"
OS="linux"

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

arch_detect() {
  if [ "$(uname -m)" = "x86_64" ]; then
    ARCH="amd64"
  elif [ "$(uname -m)" = "aarch64" ]; then
    ARCH="arm64"
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
    RELEASE_JSON="$(github_api_get "https://api.github.com/repos/hashicorp/vault/releases/latest" '(.tag_name // "") | test("[0-9]")')" \
        || error "Could not resolve the latest Vault version from the GitHub API (rate limited?). Pin the 'version' option to install a specific release."
    CURRENT_TAG="$(printf '%s' "$RELEASE_JSON" | jq --raw-output '.tag_name')"
    VERSION="${CURRENT_TAG#v}"
fi

arch_detect

install() {
    # create gpg env for signature validation
    export GNUPGHOME=./.gnupg
    gpg --no-tty --quick-generate-key --batch --passphrase "" human@example.com
    curl -L --remote-name https://www.hashicorp.com/.well-known/pgp-key.txt
    gpg --no-tty --import pgp-key.txt
    gpg --no-tty --quick-sign-key $GPG_FINGERPRINT # trust HashiCorp Key

    # download vault, sha256 sums and signature
    curl -L --remote-name https://releases.hashicorp.com/"${PRODUCT}"/"${VERSION}"/"${PRODUCT}"_"${VERSION}"_"${OS}_${ARCH}".zip
    curl -L --remote-name https://releases.hashicorp.com/"${PRODUCT}"/"${VERSION}"/"${PRODUCT}"_"${VERSION}"_SHA256SUMS
    curl -L --remote-name https://releases.hashicorp.com/"${PRODUCT}"/"${VERSION}"/"${PRODUCT}"_"${VERSION}"_SHA256SUMS.sig

    # verify integrity
    gpg --no-tty --verify ${PRODUCT}_${VERSION}_SHA256SUMS.sig ${PRODUCT}_${VERSION}_SHA256SUMS
    sha256sum --check --ignore-missing ${PRODUCT}_${VERSION}_SHA256SUMS

    unzip "${PRODUCT}"_"${VERSION}"_"${OS}_${ARCH}".zip
    rm -f "${PRODUCT}"_"${VERSION}"_"${OS}_${ARCH}".zip LICENSE.txt "${PRODUCT}"_"${VERSION}"_SHA256SUMS "${PRODUCT}"_"${VERSION}"_SHA256SUMS.sig

    chmod a+x vault
    mv vault $TARGET_PATH
}

echo "(*) Installing HashiCorp Vault binary..."

install

# Clean up
rm -rf /var/lib/apt/lists/*
rm -rf .gnupg

# Smoke test: fail the build if the binary did not install correctly
echo "(*) Verifying vault installation..."
vault version

echo "Done!"
