# KazeDB

Blazing-fast multi-tenant database engine for [Statamic](https://statamic.com).

This repository hosts pre-built binaries. For the Statamic PHP driver, see the [Statamic Marketplace](https://statamic.com/addons).

## Quick Install

```bash
curl -sL https://raw.githubusercontent.com/sushidev-team/kaze-db-releases/main/install.sh | bash
```

This installs the latest binary to `/usr/local/bin/kazedb`.

## Manual Download

Go to [**Releases**](https://github.com/sushidev-team/kaze-db-releases/releases) and download for your platform:

| Platform | Architecture | File |
|----------|-------------|------|
| Linux | x86_64 (AMD64) | `kazedb-linux-amd64.tar.gz` |
| Linux | ARM64 | `kazedb-linux-arm64.tar.gz` |
| macOS | x86_64 (Intel) | `kazedb-darwin-amd64.tar.gz` |
| macOS | ARM64 (Apple Silicon) | `kazedb-darwin-arm64.tar.gz` |

## Setup

### 1. Install the binary

```bash
curl -sL https://raw.githubusercontent.com/sushidev-team/kaze-db-releases/main/install.sh | bash
```

### 2. Create a config file

```bash
sudo mkdir -p /etc/kazedb
sudo tee /etc/kazedb/kazedb.yaml > /dev/null <<'EOF'
server:
  listen: "0.0.0.0:3001"

storage:
  backend: local
  path: /path/to/your/statamic/content

data_path: /var/lib/kazedb

auth:
  token: "your-secret-token"
  admin_token: "your-admin-secret"

cache:
  max_mb: 128

metrics:
  listen: "0.0.0.0:9090"
EOF
```

### 3. Set up the systemd service

```bash
curl -sL https://raw.githubusercontent.com/sushidev-team/kaze-db-releases/main/install.sh | bash -s -- --setup-service
```

This creates a `kazedb` system user, the systemd unit, and enables the service.

### 4. Start KazeDB

```bash
sudo systemctl start kazedb
sudo systemctl status kazedb
```

### 5. Verify

```bash
curl -s http://localhost:3001/admin/health
# {"status":"ok","version":"0.1.0"}
```

## Updating

### Check for updates

```bash
kazedb-update --check
# or
curl -sL https://raw.githubusercontent.com/sushidev-team/kaze-db-releases/main/install.sh | bash -s -- --check
```

### Update to latest

```bash
curl -sL https://raw.githubusercontent.com/sushidev-team/kaze-db-releases/main/install.sh | bash
```

The installer:
1. Downloads the new binary
2. Stops the service gracefully (finishes in-flight requests)
3. Replaces the binary
4. Restarts the service

**Your data is safe** — all data and config files live in `/var/lib/kazedb` and `/etc/kazedb`, separate from the binary. Updates only replace the binary itself.

### Install a specific version

```bash
curl -sL https://raw.githubusercontent.com/sushidev-team/kaze-db-releases/main/install.sh | bash -s -- --version v0.2.0
```

## Laravel Forge

Add this to your Forge deploy script or run it manually on the server:

```bash
# First-time setup
curl -sL https://raw.githubusercontent.com/sushidev-team/kaze-db-releases/main/install.sh | bash
curl -sL https://raw.githubusercontent.com/sushidev-team/kaze-db-releases/main/install.sh | bash -s -- --setup-service

# Edit config
sudo nano /etc/kazedb/kazedb.yaml

# Start
sudo systemctl start kazedb
```

For updates, just re-run the install:

```bash
curl -sL https://raw.githubusercontent.com/sushidev-team/kaze-db-releases/main/install.sh | bash
```

## Docker

```bash
docker pull ghcr.io/sushidev-team/kazedb:latest

docker run -d \
  -p 3001:3001 \
  -v /path/to/content:/content:ro \
  -v kazedb-data:/data \
  -v /path/to/kazedb.yaml:/etc/kazedb/kazedb.yaml:ro \
  ghcr.io/sushidev-team/kazedb:latest
```

## CLI Reference

```bash
kazedb serve --config /etc/kazedb/kazedb.yaml    # Start the server
kazedb check --config /etc/kazedb/kazedb.yaml    # Validate config
kazedb reindex --config /etc/kazedb/kazedb.yaml  # Rebuild indexes from files
```

## Data Directories

| Path | Contains | Survives updates |
|------|----------|-----------------|
| `/usr/local/bin/kazedb` | Binary | Replaced on update |
| `/etc/kazedb/kazedb.yaml` | Configuration | Preserved |
| `/var/lib/kazedb/` | Database + cache | Preserved |
| `/path/to/content/` | Statamic flat files | Preserved (read-only) |

## License

KazeDB is commercial software by [Sushi Dev](https://sushi.dev). Licensed via the [Statamic Marketplace](https://statamic.com/addons).
