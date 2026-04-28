# MeshCentral Add-on for Home Assistant

[![GitHub Release](https://img.shields.io/github/release/andlo/ha-meshcentral-addon.svg)](https://github.com/andlo/ha-meshcentral-addon/releases)
[![License](https://img.shields.io/github/license/andlo/ha-meshcentral-addon.svg)](LICENSE)

Run [MeshCentral](https://meshcentral.com) as a Home Assistant add-on — the free, open-source remote device management platform. Monitor and control all your Windows, Linux and macOS computers directly from Home Assistant.

## What is MeshCentral?

MeshCentral lets you remotely monitor, manage and control computers — think of it as your own private TeamViewer or AnyDesk, completely self-hosted, no subscriptions, no cloud dependency.

When combined with the [MeshCentral HA integration](https://github.com/andlo/ha-meshcentral), your PCs become first-class citizens in your smart home:

- See online/offline status in real-time
- Wake, reboot, sleep, hibernate or shut down devices from HA
- Automate based on PC state (turn on desk lamp when PC comes online, cut power when it shuts down)
- Monitor Windows Defender, firewall and antivirus status
- Hardware sensors: CPU, GPU, RAM, disk

## Quick start (local network)

This is all you need to get up and running on your local network:

1. **Add this repository** — go to **Settings → Add-ons → Add-on Store**, click ⋮ → **Repositories**, add `https://github.com/andlo/ha-meshcentral-addon`
2. **Install MeshCentral** from the store
3. **Start the add-on** — default settings work out of the box for local use
4. **Open the web interface** at `http://homeassistant.local:4430`
5. **Create your admin account** — account creation is enabled by default on first run
6. **Disable new accounts** — go to the add-on **Configuration** tab, set `new_accounts` to `false`, restart the add-on
7. **Install agents** on your computers — go to **My Devices → Add Device** in MeshCentral

That's it. No JSON editing required.

## External access

To reach MeshCentral and your agents from outside your home network, you need to tell MeshCentral its public address. Set these two options in the **Configuration** tab:

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
| `session_key` | *(auto)* | Secret key for session cookies. Leave empty to auto-generate (changes on each restart) |
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

## Ports

| Port | Description |
|------|-------------|
| `4430/tcp` | MeshCentral web interface |
| `4433/tcp` | Intel AMT / MPS port |

## Data storage

All data is stored under `/data/meshcentral-data` which is included in HA's standard backup automatically.

| Folder | Contents |
|--------|----------|
| `meshcentral-data/` | Database and config |
| `meshcentral-data/meshcentral-files/` | Device files |
| `meshcentral-data/meshcentral-backups/` | Automatic backups |
| `meshcentral-data/meshcentral-recordings/` | Session recordings |

> **Note:** The `meshcentral-web` folder cannot be redirected (MeshCentral limitation) and will be created alongside the add-on data folder.

## Troubleshooting

**Agents can't connect from outside my network:**
Set `server_mode` to `wan` or `hybrid` and set `cert_url` to your external URL.

**Can't log in / no accounts exist:**
Set `new_accounts` to `true` in the Configuration tab and restart. Create your admin account, then set it back to `false`.

**Settings not taking effect:**
The add-on regenerates its config on every start. Restart the add-on after any configuration change.

**"Connection refused" on port 4430:**
Check the add-on log. If MeshCentral fails to start, it's usually a config issue — the log will show what went wrong.

## Related

- [MeshCentral HA Integration](https://github.com/andlo/ha-meshcentral) — HACS integration for HA entities
- [MeshCentral](https://meshcentral.com) — Official MeshCentral website
- [MeshCentral GitHub](https://github.com/Ylianst/MeshCentral) — MeshCentral source code

## License

MIT
