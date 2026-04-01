#!/usr/bin/env bash
set -euo pipefail

# KazeDB Installer & Updater
# Usage:
#   curl -sL https://raw.githubusercontent.com/sushidev-team/kaze-db-releases/main/install.sh | bash
#   curl -sL ... | bash -s -- --version v0.2.0
#   ./install.sh --check

REPO="sushidev-team/kaze-db-releases"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="kazedb"
DATA_DIR="/var/lib/kazedb"
CONFIG_DIR="/etc/kazedb"
SERVICE_NAME="kazedb"

# --- Helpers ----------------------------------------------------------------

info()  { printf "\033[0;32m[kazedb]\033[0m %s\n" "$*"; }
warn()  { printf "\033[0;33m[kazedb]\033[0m %s\n" "$*"; }
error() { printf "\033[0;31m[kazedb]\033[0m %s\n" "$*" >&2; }

detect_platform() {
    local os arch
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    arch="$(uname -m)"

    case "$os" in
        linux)  os="linux" ;;
        darwin) os="darwin" ;;
        *)      error "Unsupported OS: $os"; exit 1 ;;
    esac

    case "$arch" in
        x86_64|amd64)   arch="amd64" ;;
        aarch64|arm64)  arch="arm64" ;;
        *)              error "Unsupported architecture: $arch"; exit 1 ;;
    esac

    echo "${BINARY_NAME}-${os}-${arch}"
}

get_installed_version() {
    if command -v "$BINARY_NAME" &>/dev/null; then
        "$BINARY_NAME" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown"
    else
        echo "none"
    fi
}

get_latest_version() {
    curl -sI "https://github.com/${REPO}/releases/latest" \
        | grep -i '^location:' \
        | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' \
        || { error "Failed to fetch latest version"; exit 1; }
}

# --- Commands ---------------------------------------------------------------

cmd_check() {
    local installed latest
    installed="$(get_installed_version)"
    latest="$(get_latest_version)"

    info "Installed: ${installed}"
    info "Latest:    ${latest}"

    if [ "$installed" = "none" ]; then
        warn "KazeDB is not installed."
        return 1
    fi

    if [ "v${installed}" = "$latest" ]; then
        info "You are up to date."
        return 0
    else
        warn "Update available: ${installed} -> ${latest}"
        return 2
    fi
}

cmd_install() {
    local version="${1:-}"
    local asset installed_version

    asset="$(detect_platform)"
    installed_version="$(get_installed_version)"

    # Determine version
    if [ -z "$version" ]; then
        version="$(get_latest_version)"
    fi

    info "Platform:  ${asset}"
    info "Version:   ${version}"
    info "Installed: ${installed_version}"

    if [ "v${installed_version}" = "$version" ]; then
        info "Already up to date (${version}). Use --force to reinstall."
        if [ "${FORCE:-}" != "1" ]; then
            return 0
        fi
    fi

    # Download
    local url="https://github.com/${REPO}/releases/download/${version}/${asset}.tar.gz"
    local tmpdir
    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' EXIT

    info "Downloading ${url} ..."
    if ! curl -fsSL "$url" -o "${tmpdir}/${asset}.tar.gz"; then
        error "Download failed. Check version and platform."
        exit 1
    fi

    # Extract
    tar xzf "${tmpdir}/${asset}.tar.gz" -C "$tmpdir"
    chmod +x "${tmpdir}/${asset}"

    # Verify the binary runs
    if ! "${tmpdir}/${asset}" --version &>/dev/null; then
        error "Downloaded binary is not executable on this platform."
        exit 1
    fi

    local new_version
    new_version="$("${tmpdir}/${asset}" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "$version")"

    # Stop service if running (graceful — finish in-flight requests)
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        info "Stopping ${SERVICE_NAME} service ..."
        sudo systemctl stop "$SERVICE_NAME"
    fi

    # Install binary
    info "Installing to ${INSTALL_DIR}/${BINARY_NAME} ..."
    sudo mv "${tmpdir}/${asset}" "${INSTALL_DIR}/${BINARY_NAME}"

    # Create data directories if they don't exist
    sudo mkdir -p "$DATA_DIR" "$CONFIG_DIR"

    # Restart service if it exists
    if systemctl list-unit-files "${SERVICE_NAME}.service" &>/dev/null; then
        info "Starting ${SERVICE_NAME} service ..."
        sudo systemctl start "$SERVICE_NAME"
    fi

    info "KazeDB ${new_version} installed successfully."
}

cmd_setup_service() {
    info "Creating systemd service ..."

    sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null <<'UNIT'
[Unit]
Description=KazeDB Database Engine
After=network.target

[Service]
Type=simple
User=kazedb
Group=kazedb
ExecStart=/usr/local/bin/kazedb serve --config /etc/kazedb/kazedb.yaml
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

# Data safety
ReadWritePaths=/var/lib/kazedb
ReadOnlyPaths=/etc/kazedb

[Install]
WantedBy=multi-user.target
UNIT

    # Create user if not exists
    if ! id kazedb &>/dev/null; then
        sudo useradd -r -s /usr/sbin/nologin -d /var/lib/kazedb kazedb
        info "Created 'kazedb' system user."
    fi

    sudo mkdir -p /var/lib/kazedb /etc/kazedb
    sudo chown -R kazedb:kazedb /var/lib/kazedb

    sudo systemctl daemon-reload
    sudo systemctl enable "$SERVICE_NAME"

    info "Service created. Configure /etc/kazedb/kazedb.yaml then run:"
    info "  sudo systemctl start kazedb"
}

# --- Main -------------------------------------------------------------------

main() {
    local cmd="install"
    local version=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --check)        cmd="check";   shift ;;
            --setup-service) cmd="setup";  shift ;;
            --version)      version="$2";  shift 2 ;;
            --force)        FORCE=1;       shift ;;
            -h|--help)      cmd="help";    shift ;;
            *)              shift ;;
        esac
    done

    case "$cmd" in
        check)
            cmd_check
            ;;
        setup)
            cmd_setup_service
            ;;
        install)
            cmd_install "$version"
            ;;
        help)
            echo "KazeDB Installer & Updater"
            echo ""
            echo "Usage:"
            echo "  install.sh                    Install/update to latest version"
            echo "  install.sh --version v0.2.0   Install specific version"
            echo "  install.sh --check            Check for updates"
            echo "  install.sh --setup-service    Create systemd service"
            echo "  install.sh --force            Force reinstall even if up to date"
            ;;
    esac
}

main "$@"
