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

## Installation

### Step 1 — Add this repository to HA

1. Go to **Settings → Add-ons → Add-on Store**
2. Click ⋮ → **Repositories**
3. Add: `https://github.com/andlo/ha-meshcentral-addon`
4. Find and install **MeshCentral**

### Step 2 — Configure the add-on

All MeshCentral settings are available directly in the add-on **Configuration** tab in Home Assistant — no need to edit any JSON files manually.

See the full [Configuration reference](#configuration) below.

### Step 3 — Create your admin account

1. In the add-on **Configuration** tab, temporarily set `new_accounts` to `true`
2. Start the add-on
3. Open the MeshCentral web interface and create your admin account
4. **Important:** Set `new_accounts` back to `false` and restart the add-on

### Step 4 — Install the HA integration

Install the [MeshCentral integration](https://github.com/andlo/ha-meshcentral) via HACS to connect HA entities to your MeshCentral server.

Use these settings in the integration:
- **Host:** `homeassistant.local` (or your HA IP)
- **Port:** `4430`
- **Use SSL:** off (the add-on uses tlsOffload — HA handles TLS)
- **Verify SSL:** off

### Step 5 — Install agents on your computers

1. Log in to MeshCentral web interface
2. Go to **My Devices → Add Device**
3. Download and run the installer on each PC

## Network

### Local network only (simplest)

The add-on is accessible on your local network at `http://homeassistant.local:4430`. Set `server_mode` to `lan`.

### External access via Nabu Casa (recommended)

If you have [Nabu Casa](https://www.nabucasa.com/) (Home Assistant Cloud):

1. Enable **Remote Access** in Nabu Casa
2. Set `cert_url` to your Nabu Casa URL
3. Agents outside your home network can now connect

### External access via Cloudflare Tunnel (free, no port-forwarding)

1. Set up a [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) pointing to `http://homeassistant.local:4430`
2. Set `server_mode` to `wan` and `cert_url` to your tunnel URL
3. Agents anywhere in the world can now connect

### Port forwarding (traditional)

Forward port `4430` on your router to your HA host IP. Set `server_mode` to `wan` and `cert_url` to your external URL.

## Configuration

All settings are configured via the add-on **Configuration** tab in Home Assistant. The add-on generates MeshCentral's `config.json` automatically on every start based on these settings.

### General

| Option | Default | Description |
|--------|---------|-------------|
| `data_path` | `/data/meshcentral-data` | Where MeshCentral stores its database, files and backups |
| `hostname` | *(auto)* | Public hostname for agent connections. Leave empty to use the HA hostname |
| `cert_url` | *(empty)* | **Required for external agent connections.** Full external URL, e.g. `https://mesh.yourdomain.com` |
| `server_mode` | `lan` | Network mode: `lan` (local only), `wan` (internet, requires DNS), `hybrid` (both) |

### Domain / appearance

| Option | Default | Description |
|--------|---------|-------------|
| `domain_title` | `MeshCentral` | Title shown on the login page |
| `domain_title2` | `Home Assistant` | Subtitle shown below the title |
| `new_accounts` | `false` | Allow users to self-register. Enable temporarily to create your first admin account |
| `allow_device_sharing` | `false` | Allow device sharing with other users |

### Security

| Option | Default | Description |
|--------|---------|-------------|
| `session_key` | *(auto)* | Secret key for encrypting session cookies. Leave empty to auto-generate on each start |
| `session_time` | `60` | Session duration in minutes |
| `tls_offload` | `true` | Set to `true` when a reverse proxy (e.g. HA's NGINX) handles TLS in front of MeshCentral |
| `trusted_proxy` | *(empty)* | IP addresses allowed to forward headers (X-Forwarded-For). Use `CloudFlare` for automatic CloudFlare IP list |
| `user_allowed_ip` | *(empty)* | Only these IPs can log in. Comma-separated, e.g. `192.168.1.0/24,10.0.0.1`. Empty = all allowed |
| `user_blocked_ip` | *(empty)* | Block these IPs from logging in |
| `agent_allowed_ip` | *(empty)* | Only accept agents from these IPs |
| `agent_blocked_ip` | *(empty)* | Reject agents from these IPs |

### Network features

| Option | Default | Description |
|--------|---------|-------------|
| `web_rtc` | `false` | Enable WebRTC for direct peer-to-peer browser ↔ agent connections |
| `compression` | `false` | Enable GZIP compression for HTTP responses |
| `self_update` | `false` | Allow MeshCentral to update itself automatically |
| `maintenance_mode` | `false` | When enabled, only administrators can log in |

### Email (SMTP)

| Option | Default | Description |
|--------|---------|-------------|
| `smtp_enabled` | `false` | Enable SMTP to send emails (account confirmation, password reset) |
| `smtp_host` | *(empty)* | SMTP server hostname, e.g. `smtp.gmail.com` |
| `smtp_port` | `587` | SMTP port. Use `587` for STARTTLS or `465` for SSL |
| `smtp_from` | *(empty)* | Sender email address |
| `smtp_user` | *(empty)* | SMTP username |
| `smtp_pass` | *(empty)* | SMTP password |
| `smtp_tls` | `true` | Enable TLS for the SMTP connection |

## Ports

| Port | Description |
|------|-------------|
| `4430/tcp` | MeshCentral web interface (HTTPS) |
| `4433/tcp` | Intel AMT / MPS port |

## Data storage

All MeshCentral data is kept under `data_path`:

| Folder | Contents |
|--------|----------|
| `data_path/` | MeshCentral database and config |
| `data_path/meshcentral-files/` | Device files |
| `data_path/meshcentral-backups/` | Automatic backups |
| `data_path/meshcentral-recordings/` | Session recordings |

All folders are included in HA's standard backup.

> **Note:** The `meshcentral-web` folder cannot be redirected (MeshCentral limitation) and will be created next to the add-on installation.

## Updating MeshCentral

The add-on bundles a specific version of MeshCentral. When a new version of the add-on is released, update it via the HA add-on store. Your data and agent connections are preserved across updates.

## Troubleshooting

**Agents can't connect from outside my network:**
Set `server_mode` to `wan` or `hybrid`, and set `cert_url` to your external URL (Cloudflare tunnel, DuckDNS, Nabu Casa URL).

**Can't create account:**
Temporarily set `new_accounts` to `true` in the add-on configuration and restart. Remember to set it back to `false` after creating your account.

**MeshCentral integration shows "invalid_auth":**
If your account has 2FA enabled, create a Login Token in MeshCentral → My Account → Login Tokens and use those credentials in the HA integration.

**Settings not taking effect:**
The add-on regenerates `config.json` on every start from the HA configuration. Restart the add-on after changing any setting.

## Related

- [MeshCentral HA Integration](https://github.com/andlo/ha-meshcentral) — HACS integration for HA entities
- [MeshCentral](https://meshcentral.com) — Official MeshCentral website
- [MeshCentral GitHub](https://github.com/Ylianst/MeshCentral) — MeshCentral source code

## License

MIT
