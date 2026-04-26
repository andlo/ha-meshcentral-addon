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

### Step 2 — First-time setup

Before starting the add-on for the first time, you need to allow account creation:

1. Go to the add-on **Configuration** tab
2. Note the `data_path` (default: `/data/meshcentral-data`)
3. Start the add-on
4. Open the MeshCentral web interface (see **Network** below)
5. Create your admin account
6. **Important:** After creating your account, stop the add-on and edit `/data/meshcentral-data/config.json` — set `"newAccounts": false` to prevent others from registering

### Step 3 — Install the HA integration

Install the [MeshCentral integration](https://github.com/andlo/ha-meshcentral) via HACS to connect HA entities to your MeshCentral server.

Use these settings in the integration:
- **Host:** `homeassistant.local` (or your HA IP)
- **Port:** `4430`
- **Use SSL:** off (the add-on uses tlsOffload — HA handles TLS)
- **Verify SSL:** off

### Step 4 — Install agents on your computers

Download and install the MeshCentral agent on each computer you want to manage:

1. Log in to MeshCentral web interface
2. Go to **My Devices → Add Device**
3. Download and run the installer on each PC

## Network

### Local network only (simplest)

The add-on is accessible on your local network at:
`http://homeassistant.local:4430`

Agents on the same network will connect automatically.

### External access via Nabu Casa (recommended)

If you have [Nabu Casa](https://www.nabucasa.com/) (Home Assistant Cloud):

1. Enable **Remote Access** in Nabu Casa
2. Your MeshCentral will be accessible at your Nabu Casa URL
3. Agents outside your home network can connect via the Nabu Casa URL

### External access via Cloudflare Tunnel (free, no port-forwarding)

1. Set up a [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) pointing to `http://homeassistant.local:4430`
2. In MeshCentral's config.json, set your tunnel URL as the `hostname`
3. Agents anywhere in the world can now connect

### Port forwarding (traditional)

Forward port `4430` on your router to your HA host IP.

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `data_path` | `/data/meshcentral-data` | Where MeshCentral stores its data |
| `hostname` | *(auto)* | Public hostname for agent connections — set this to your external URL (Cloudflare, Nabu Casa etc.) |
| `allow_device_sharing` | `false` | Allow device sharing with other users |

## Ports

| Port | Description |
|------|-------------|
| `4430/tcp` | MeshCentral web interface |

## Updating MeshCentral

The add-on bundles a specific version of MeshCentral. When a new version of the add-on is released, update it via the HA add-on store. Your data and agent connections are preserved across updates.

## Backup

MeshCentral data is stored in `/data/meshcentral-data` which is included in HA's standard backup. All device connections, users, and settings are backed up automatically.

## Troubleshooting

**Agents can't connect from outside my network:**
Set the `hostname` option to your external URL (Cloudflare tunnel, DuckDNS, Nabu Casa URL).

**Can't create account:**
Temporarily set `"newAccounts": true` in `/data/meshcentral-data/config.json` and restart the add-on. Remember to set it back to `false` after.

**MeshCentral integration shows "invalid_auth":**
If your account has 2FA enabled, create a Login Token in MeshCentral → My Account → Login Tokens and use those credentials in the HA integration.

## Related

- [MeshCentral HA Integration](https://github.com/andlo/ha-meshcentral) — HACS integration for HA entities
- [MeshCentral](https://meshcentral.com) — Official MeshCentral website
- [MeshCentral GitHub](https://github.com/Ylianst/MeshCentral) — MeshCentral source code

## License

MIT
