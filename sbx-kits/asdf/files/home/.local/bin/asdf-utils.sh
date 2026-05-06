#!/usr/bin/env bash

ASDF_RELEASE_API_URL="${ASDF_RELEASE_API_URL:-https://api.github.com/repos/asdf-vm/asdf/releases/latest}"
ASDF_INSTALL_DIR="${ASDF_INSTALL_DIR:-$HOME/.local/bin}"
ASDF_BIN="$ASDF_INSTALL_DIR/asdf"

ASDF_RELEASE_JSON=""
ASDF_TARGET_VERSION=""
ASDF_OS=""
ASDF_ARCH=""
ASDF_ASSET_URL=""
ASDF_ASSET_MD5_URL=""

install_latest() {
  mkdir -p "$ASDF_INSTALL_DIR"

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  local archive="$tmp_dir/asdf.tar.gz"
  local archive_md5="$tmp_dir/asdf.tar.gz.md5"
  local expected_md5
  local actual_md5

  log_info "Installing asdf $ASDF_TARGET_VERSION for $ASDF_OS/$ASDF_ARCH."
  log_info "Downloading: $ASDF_ASSET_URL"

  curl -fsSL -o "$archive" "$ASDF_ASSET_URL"
  curl -fsSL -o "$archive_md5" "$ASDF_ASSET_MD5_URL"

  expected_md5="$(tr -d '[:space:]' < "$archive_md5")"

  if command -v md5sum >/dev/null 2>&1; then
    actual_md5="$(md5sum "$archive" | awk '{print $1}')"
  else
    actual_md5="$(md5 -q "$archive")"
  fi

  if [[ "$expected_md5" != "$actual_md5" ]]; then
    fail "MD5 checksum mismatch for downloaded archive."
  fi

  log_info "MD5 checksum verified."

  tar -xzf "$archive" -C "$tmp_dir"

  if [[ ! -f "$tmp_dir/asdf" ]]; then
    fail "Archive did not contain expected asdf binary."
  fi

  install -m 755 "$tmp_dir/asdf" "$ASDF_BIN"
  log_info "Installed asdf to $ASDF_BIN."
}

load_latest_release() {
  ASDF_OS="$(normalize_os)"
  ASDF_ARCH="$(normalize_arch)"
  ASDF_RELEASE_JSON="$(curl -fsSL "$ASDF_RELEASE_API_URL")"

  ASDF_TARGET_VERSION="$(jq -r '.target_name // .tag_name // empty' <<<"$ASDF_RELEASE_JSON")"

  if [[ -z "$ASDF_TARGET_VERSION" || "$ASDF_TARGET_VERSION" == "null" ]]; then
    fail "Could not determine latest asdf version from release JSON."
  fi

  ASDF_ASSET_URL="$(jq -r \
    --arg os "$ASDF_OS" \
    --arg arch "$ASDF_ARCH" \
    '.assets[]
     | select(.name | test($os))
     | select(.name | test($arch))
     | select(.name | endswith(".tar.gz"))
     | .browser_download_url' <<<"$ASDF_RELEASE_JSON" | head -n 1)"

  if [[ -z "$ASDF_ASSET_URL" || "$ASDF_ASSET_URL" == "null" ]]; then
    fail "Could not find release asset for OS=$ASDF_OS ARCH=$ASDF_ARCH."
  fi

  ASDF_ASSET_MD5_URL="${ASDF_ASSET_URL}.md5"
}

installed_version() {
  if [[ -x "$ASDF_BIN" ]]; then
    "$ASDF_BIN" version 2>/dev/null | awk '{print $1}' || true
  fi
}

normalize_os() {
  case "$(uname -s)" in
    Linux) printf '%s\n' "linux" ;;
    Darwin) printf '%s\n' "darwin" ;;
    *) fail "Unsupported operating system: $(uname -s)" ;;
  esac
}

normalize_arch() {
  case "$(uname -m)" in
    x86_64|amd64) printf '%s\n' "amd64" ;;
    arm64|aarch64) printf '%s\n' "arm64" ;;
    *) fail "Unsupported architecture: $(uname -m)" ;;
  esac
}

require_dependencies() {
  require_cmd curl
  require_cmd jq
  require_cmd tar
  require_cmd install
  require_cmd md5sum
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "Missing required command: $1"
  fi
}

fail() {
  log_error "$*"
  exit 1
}

log_info() {
  printf '[info] %s\n' "$*" >&2
}

log_error() {
  printf '[error] %s\n' "$*" >&2
}
