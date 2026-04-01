# KazeDB — Pre-built Binaries

Blazing-fast multi-tenant database engine for [Statamic](https://statamic.com).

This repository hosts pre-built binaries. Source code is in a private repository.

## Download

Go to [**Releases**](https://github.com/sushidev-team/kaze-db-releases/releases) and download the binary for your platform:

| Platform | Architecture | File |
|----------|-------------|------|
| Linux | x86_64 (AMD64) | `kazedb-linux-amd64.tar.gz` |
| Linux | ARM64 | `kazedb-linux-arm64.tar.gz` |
| macOS | x86_64 (Intel) | `kazedb-darwin-amd64.tar.gz` |
| macOS | ARM64 (Apple Silicon) | `kazedb-darwin-arm64.tar.gz` |

## Quick Install (Linux AMD64)

```bash
# Download latest release
curl -sL https://github.com/sushidev-team/kaze-db-releases/releases/latest/download/kazedb-linux-amd64.tar.gz | tar xz
chmod +x kazedb-linux-amd64
sudo mv kazedb-linux-amd64 /usr/local/bin/kazedb
```

## Laravel Forge

```bash
# In your Forge deploy script:
curl -sL https://github.com/sushidev-team/kaze-db-releases/releases/latest/download/kazedb-linux-amd64.tar.gz | tar xz
sudo mv kazedb-linux-amd64 /usr/local/bin/kazedb
sudo systemctl restart kazedb
```

## License

KazeDB is commercial software by [Sushi Dev](https://sushi.dev). Licensed via the [Statamic Marketplace](https://statamic.com/addons).
