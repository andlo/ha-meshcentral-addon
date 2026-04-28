# MeshCentral Add-on for Home Assistant

[![GitHub Release](https://img.shields.io/github/release/andlo/ha-meshcentral-addon.svg)](https://github.com/andlo/ha-meshcentral-addon/releases)
[![License](https://img.shields.io/github/license/andlo/ha-meshcentral-addon.svg)](LICENSE)
[![Project Maintenance](https://img.shields.io/badge/maintainer-%40andlo-blue.svg)](https://github.com/andlo)
[![GitHub Actions](https://github.com/andlo/ha-meshcentral-addon/actions/workflows/build.yaml/badge.svg)](https://github.com/andlo/ha-meshcentral-addon/actions/workflows/build.yaml)
[![Buy me a coffee](https://img.shields.io/badge/buy%20me%20a%20coffee-donate-yellow.svg)](https://www.buymeacoffee.com/andlo)

Run [MeshCentral](https://meshcentral.com) as a Home Assistant add-on — the free, open-source remote device management platform. Monitor and control all your Windows, Linux and macOS computers directly from Home Assistant.

![MeshCentral add-on in the HA add-on store](screenshots/addon-store-card.png)

## What is MeshCentral?

MeshCentral lets you remotely monitor, manage and control computers — think of it as your own private TeamViewer or AnyDesk, completely self-hosted, no subscriptions, no cloud dependency.

When combined with the [MeshCentral HA integration](https://github.com/andlo/ha-meshcentral), your PCs become first-class citizens in your smart home:

- See online/offline status in real-time
- Wake, reboot, sleep, hibernate or shut down devices from HA
- Automate based on PC state (turn on desk lamp when PC comes online, cut power when it shuts down)
- Monitor Windows Defender, firewall and antivirus status
- Hardware sensors: CPU, GPU, RAM, disk

![PC devices dashboard in Home Assistant](screenshots/dashboard-pc.png)

## Quick start (local network)

This is all you need to get up and running on your local network:

1. **Add this repository** — go to **Settings → Add-ons → Add-on Store**, click ⋮ → **Repositories**, add `https://github.com/andlo/ha-meshcentral-addon`
2. **Install MeshCentral** from the store
3. **Start the add-on** — default settings work out of the box for local use
4. **Open the web interface** — see [Connecting to MeshCentral](#connecting-to-meshcentral) below
5. **Create your admin account** — account creation is enabled by default on first run
6. **Disable new accounts** — go to the add-on **Configuration** tab, set `new_accounts` to `false`, restart the add-on
7. **Install agents** on your computers — go to **My Devices → Add Device** in MeshCentral

That's it. No JSON editing required.

![MeshCentral add-on installed — info page with icon and controls](screenshots/addon-info.png)

![MeshCentral add-on configuration — all settings available in the HA UI](screenshots/addon-configuration.png)

## Connecting to MeshCentral

MeshCentral runs its own HTTPS server with a self-signed certificate. When you start the add-on, the **Log** tab will show the exact URLs:

```
 Open in browser (accept certificate warning):
   https://192.168.x.x:4430
 Or via HTTP redirect:
   http://192.168.x.x:4431
```

The easiest way to connect is via **HTTP on port 4431** — your browser will automatically be redirected to HTTPS. You will see a certificate warning the first time (because the certificate is self-signed) — click **Advanced → Proceed** to continue. This is normal and safe on your local network.

Alternatively, go directly to `https://homeassistant.local:4430`.

| Port | Description |
|------|-------------|
| `4430` | MeshCentral HTTPS web interface |
| `4431` | HTTP → redirects to HTTPS automatically |
| `4433` | Intel AMT / MPS port |

## External access

To reach MeshCentral and your agents from outside your home network, set these two options in the **Configuration** tab:

| Option | What to set |
|--------|-------------|
| `server_mode` | `wan` (internet only) or `hybrid` (local + internet) |
| `cert_url` | Your full public URL — e.g. from Nabu Casa, Cloudflare Tunnel, or DuckDNS |

### Via Nabu Casa (easiest)
Enable **Remote Access** in Nabu Casa and paste your Nabu Casa URL as `cert_url`.

### Via Cloudflare Tunnel (free, no port-forwarding)
Set up a tunnel pointing to `http://homeassistant.local:4430` and use the tunnel URL as `cert_url`.

### Via port forwarding
Forward port `4430` on your router to your HA host and use your external IP or domain as `cert_url`.

## Install the HA integration

Install the [MeshCentral integration](https://github.com/andlo/ha-meshcentral) via HACS to get HA entities for your devices.

![MeshCentral integration with 8 devices and 202 entities](screenshots/integration-devices.png)

Settings for the integration:
- **Host:** `homeassistant.local` (or your HA IP)
- **Port:** `4430`
- **Use SSL:** off
- **Verify SSL:** off

> If your account has 2FA enabled, create a Login Token in MeshCentral → My Account → Login Tokens and use those credentials instead.

## Configuration

All settings are in the add-on **Configuration** tab. No JSON files to edit. The add-on generates MeshCentral's config on every start from these options.

### General

| Option | Default | Description |
|--------|---------|-------------|
| `server_mode` | `lan` | `lan` = local network only, `wan` = internet (requires `cert_url`), `hybrid` = both |
| `cert_url` | *(empty)* | Your full external URL. Required for agents outside your local network |
| `hostname` | *(HA hostname)* | Public hostname override. Leave empty to use the HA system hostname |

### Domain / appearance

| Option | Default | Description |
|--------|---------|-------------|
| `domain_title` | `MeshCentral` | Title shown on the login page |
| `domain_title2` | *(empty)* | Optional subtitle |
| `new_accounts` | `true` | Allow users to self-register. **Disable after creating your admin account** |

### Security

| Option | Default | Description |
|--------|---------|-------------|
| `session_key` | *(auto)* | Secret key for session cookies. Leave empty to auto-generate |
| `session_time` | `60` | Session duration in minutes |
| `tls_offload` | `false` | Set to `true` only if a reverse proxy handles HTTPS in front of MeshCentral |
| `trusted_proxy` | *(empty)* | IPs allowed to send X-Forwarded-For headers. Use `CloudFlare` for automatic CloudFlare IP list |
| `user_allowed_ip` | *(empty)* | Comma-separated IPs/ranges allowed to log in — e.g. `192.168.1.0/24`. Empty = all allowed |
| `user_blocked_ip` | *(empty)* | Block these IPs from logging in |
| `agent_allowed_ip` | *(empty)* | Only accept agents from these IPs |
| `agent_blocked_ip` | *(empty)* | Reject agents from these IPs |

### Features

| Option | Default | Description |
|--------|---------|-------------|
| `web_rtc` | `false` | Enable WebRTC for direct peer-to-peer connections (reduces server load for desktop sessions) |
| `compression` | `false` | Enable GZIP compression |
| `self_update` | `false` | Let MeshCentral update itself automatically |
| `maintenance_mode` | `false` | Only administrators can log in |

### Email (SMTP)

Only needed for account confirmation and password reset emails.

| Option | Default | Description |
|--------|---------|-------------|
| `smtp_enabled` | `false` | Enable SMTP |
| `smtp_host` | *(empty)* | SMTP server hostname — e.g. `smtp.gmail.com` |
| `smtp_port` | `587` | Use `587` for STARTTLS or `465` for SSL |
| `smtp_from` | *(empty)* | Sender address |
| `smtp_user` | *(empty)* | SMTP username |
| `smtp_pass` | *(empty)* | SMTP password |
| `smtp_tls` | `true` | Enable TLS |

## Data storage

All data is stored under `/data/meshcentral-data` and `/data/meshcentral-backups`, both included in HA's standard backup automatically.

| Folder | Contents |
|--------|----------|
| `/data/meshcentral-data/` | Database and config |
| `/data/meshcentral-data/meshcentral-files/` | Device files |
| `/data/meshcentral-backups/` | Automatic backups |
| `/data/meshcentral-data/meshcentral-recordings/` | Session recordings |

## Troubleshooting

**Browser shows "ERR_EMPTY_RESPONSE" or similar:**
Use `http://homeassistant.local:4431` (HTTP port) which redirects to HTTPS, or go directly to `https://homeassistant.local:4430` and accept the certificate warning.

**Agents can't connect from outside my network:**
Set `server_mode` to `wan` or `hybrid` and set `cert_url` to your external URL.

**Can't log in / no accounts exist:**
Set `new_accounts` to `true` in the Configuration tab and restart. Create your admin account, then set it back to `false`.

**Settings not taking effect:**
The add-on regenerates its config on every start. Restart the add-on after any configuration change.

## Related

- [MeshCentral HA Integration](https://github.com/andlo/ha-meshcentral) — HACS integration for HA entities
- [MeshCentral](https://meshcentral.com) — Official MeshCentral website
- [MeshCentral GitHub](https://github.com/Ylianst/MeshCentral) — MeshCentral source code

## License

MIT
