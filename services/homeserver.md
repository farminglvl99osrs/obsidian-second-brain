---
type: service
status: active
repo: https://github.com/staffdill/homeserver
owner: staffdill
tags: [infrastructure, raspberry-pi, docker, dns, vpn]
last_updated: 2026-03-06
---

# homeserver

## Overview

Raspberry Pi home server running network infrastructure services via Docker Compose. Provides DNS-level ad blocking for the entire LAN and a WireGuard VPN for remote access.

## Tech Stack

- Language / framework: Docker Compose (declarative config)
- Platform: Raspberry Pi (Linux ARM, `raspi` kernel)
- DNS / Ad blocking: Pi-hole (`pihole/pihole:latest`)
- VPN: wg-easy (`ghcr.io/wg-easy/wg-easy:latest`) — WireGuard with web UI
- Config: `.env` (credentials, gitignored), `docker-compose.yml`
- Database: None

## Key Endpoints / Interfaces

**Pi-hole:**
- Ports: `53/tcp+udp` (DNS), `80/tcp` (web admin)
- Web admin: `http://192.168.0.22:80`
- Config volumes: `pihole/etc-pihole/`, `pihole/etc-dnsmasq.d/`

**WireGuard (wg-easy):**
- Ports: `51820/udp` (VPN tunnel), `51821/tcp` (web management UI)
- Web UI: `http://192.168.0.22:51821`
- Config volume: `wireguard/`
- VPN client DNS: `192.168.0.22` (routes through Pi-hole)

## Network Topology

```
Internet -> Router -> Pi (192.168.0.22)
                        |- Pi-hole (DNS for all LAN devices)
                        `- WireGuard (VPN for remote access)
                              `- Routes DNS through Pi-hole
```

## Relationships

- Provides **DNS for the entire home LAN** — all devices use Pi-hole as resolver
- Provides **VPN access** for remote network connectivity
- [[three-sword-style-ai]] GCP training traffic may route through VPN
- No code dependencies on other repos; purely network infrastructure

## Architecture Decisions

- **Docker Compose** over bare-metal installs — reproducible, easy to update
- **WireGuard DNS routes through Pi-hole** — VPN clients get ad blocking remotely
- **wg-easy** for WireGuard — browser-based peer management UI
- **`restart: unless-stopped`** on both services — auto-restart on reboot
- **`depends_on: pihole`** — DNS available before VPN starts

## Operational Notes

- **Pi IP:** `192.168.0.22` (LAN static assignment)
- **Credentials:** `.env` file — never commit. Contains `PIHOLE_PASSWORD`, `WG_HOST`, `WG_PASSWORD_HASH`
- **Deploy:** `docker compose up -d`
- **Update:** `docker compose pull && docker compose up -d`
- **No CI/CD** — manual deploy only
- **Local path:** `~/Documents/homeserver`
