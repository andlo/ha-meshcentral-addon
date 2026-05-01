# MeshCentral

Run MeshCentral as a Home Assistant add-on — the free, open-source remote device management platform.

MeshCentral lets you remotely monitor, manage and control computers (Windows, Linux, macOS) from a single interface. Combined with the [MeshCentral HA integration](https://github.com/andlo/ha-meshcentral), your PCs become smart home devices — online/offline sensors, Wake-on-LAN, power control, Windows security monitoring and more.

---

## Quick start

1. Install this add-on and start it
2. Open the web interface at `https://homeassistant.local:4430`
3. Create your admin account (registration is open by default)
4. Install MeshCentral agents on your computers from the web interface
5. _(Optional)_ Install the [MeshCentral HA integration](https://github.com/andlo/ha-meshcentral) via HACS and connect it to `homeassistant.local:4430`

> **Tip:** After creating your admin account, consider setting `new_accounts: false` so no one else can register.

---

## Configuration reference

### General / Network

#### `server_mode`
**Default:** `lan`

Controls how MeshCentral presents itself and generates agent installers.

| Value | When to use |
|-------|-------------|
| `lan` | Local network only. No public DNS name needed. Uses the server's local IP in agent installers. |
| `wan` | Internet-accessible server. Set `cert_url` to your public domain. |
| `hybrid` | Both LAN and WAN access. Uses `cert_url` for agent installers but also accepts local connections. |

For most Home Assistant setups, `lan` is the right choice.

#### `cert_url`
**Default:** _(empty)_

The public hostname or IP that agents and browsers use to reach the server — e.g. `meshcentral.example.com` or `192.168.1.100`.

Required when `server_mode` is `wan` or `hybrid`. Leave empty in `lan` mode; MeshCentral will use the server's detected local address.

#### `tls_offload`
**Default:** `false`

Set to `true` if MeshCentral sits behind a reverse proxy (e.g. NGINX Proxy Manager, Traefik) that handles HTTPS and forwards plain HTTP to the add-on. When enabled, MeshCentral trusts `X-Forwarded-*` headers.

Leave `false` for direct access — MeshCentral handles its own TLS certificate.

#### `trusted_proxy`
**Default:** _(empty)_

IP address or CIDR range of your reverse proxy, e.g. `192.168.1.1` or `172.16.0.0/12`. Only used when `tls_offload` is `true`. MeshCentral will only trust forwarded headers from this address.

#### `agent_port`
**Default:** `0` _(disabled)_

If set to a non-zero port number, MeshCentral opens a dedicated HTTPS port exclusively for agent connections, separate from the main web interface port (4430). Useful if you want to expose agent traffic on a different firewall rule. Set to `0` to use the main port for everything.

#### `mps_port`
**Default:** `4433`

Port for Intel AMT / MPS (Management Presence Server) connections. Only relevant if you manage Intel vPro/AMT devices. Exposed externally on the same port by default.

---

### Login page / Appearance

#### `domain_title`
**Default:** `MeshCentral`

The name shown in the browser tab and on the login page header.

#### `domain_title2`
**Default:** _(empty)_

Optional subtitle shown below the main title on the login page.

#### `site_style`
**Default:** `2`

Login page visual style.

| Value | Description |
|-------|-------------|
| `1` | Classic style |
| `2` | Modern style |

#### `welcome_text`
**Default:** _(empty)_

Optional text shown on the login page below the title — useful for a welcome message or instructions for new users.

---

### Accounts & Security

#### `new_accounts`
**Default:** `true`

Allow new users to register themselves on the login page. Set to `true` initially so you can create your admin account. After that, set to `false` to prevent anyone else from registering.

#### `new_accounts_pass`
**Default:** _(empty)_

If set, users must enter this password on the registration page before creating an account. Acts as a shared invite code. Only relevant when `new_accounts` is `true`.

#### `session_time`
**Default:** `60`

How long (in minutes) a user session stays active without activity before requiring re-login. Set to `0` for sessions that never expire automatically.

#### `no_2fa`
**Default:** `false`

Set to `true` to disable the two-factor authentication requirement for all users. Not recommended for internet-facing servers.

#### `max_invalid_login_count`
**Default:** `10`

Number of failed login attempts allowed before an IP address is temporarily blocked.

#### `max_invalid_login_time`
**Default:** `10`

Time window in minutes over which failed login attempts are counted. If an IP exceeds `max_invalid_login_count` within this window, it is blocked.

#### `user_allowed_ip`
**Default:** _(empty)_

Comma-separated list of IP addresses or CIDR ranges that are allowed to access the web interface. All other IPs are blocked. Leave empty to allow all.

Example: `192.168.1.0/24,10.0.0.5`

#### `user_blocked_ip`
**Default:** _(empty)_

Comma-separated list of IP addresses or CIDR ranges that are blocked from accessing the web interface. Leave empty to block none.

---

### Features

#### `web_rtc`
**Default:** `false`

Enable WebRTC for direct peer-to-peer remote desktop connections between browser and agent. Can improve performance but requires open UDP ports and may not work behind strict NAT. Leave `false` for relay-based connections which work everywhere.

#### `compression`
**Default:** `true`

Enable GZIP compression for web traffic. Reduces bandwidth at the cost of a small amount of CPU. Recommended to leave enabled.

#### `allow_high_quality_desktop`
**Default:** `true`

Allow agents to stream remote desktop at full/high quality. Set to `false` to cap quality and reduce bandwidth usage on slow connections.

#### `guest_device_sharing`
**Default:** `true`

Allow users to create guest sharing links for remote desktop sessions — a time-limited URL that gives a guest one-click access to a specific device without needing a MeshCentral account.

#### `allow_framing`
**Default:** `false`

Allow MeshCentral to be embedded in an iframe on another web page. Disabled by default for security (prevents clickjacking). Only enable if you specifically need to embed MeshCentral in another dashboard.

#### `self_update`
**Default:** `false`

Allow MeshCentral to update itself automatically. Not recommended in the add-on context — the add-on controls the MeshCentral version. Leave `false`.

#### `maintenance_mode`
**Default:** `false`

When `true`, MeshCentral blocks all user logins and shows a maintenance message. Agents stay connected. Useful when doing configuration changes without disconnecting devices.

#### `auto_remove_inactive_devices`
**Default:** `0` _(disabled)_

Automatically remove devices that have been offline for more than this many days. Set to `0` to never auto-remove devices.

---

### Agent IP filtering

#### `agent_allowed_ip`
**Default:** _(empty)_

Comma-separated list of IP addresses or CIDR ranges that agents are allowed to connect from. Leave empty to allow agents from any IP.

#### `agent_blocked_ip`
**Default:** _(empty)_

Comma-separated list of IP addresses or CIDR ranges that are blocked from connecting as agents.

---

### Backup

#### `backup_interval_hours`
**Default:** `24`

How often MeshCentral creates an automatic backup of its database and configuration, in hours. Set to `0` to disable automatic backups.

#### `backup_keep_days`
**Default:** `10`

How many days of automatic backups to keep. Older backups are deleted automatically.

#### `backup_zip_password`
**Default:** _(empty)_

Optional password to encrypt backup ZIP files. Leave empty for unencrypted backups.

---

### Email (SMTP)

SMTP allows MeshCentral to send email notifications — for example, when a device goes offline, for account verification, or for 2FA codes.

#### `smtp_enabled`
**Default:** `false`

Enable SMTP email sending. Set to `true` and fill in the fields below to activate.

#### `smtp_host`
**Default:** _(empty)_

Hostname of your SMTP server, e.g. `smtp.gmail.com` or `mail.example.com`.

#### `smtp_port`
**Default:** `587`

SMTP port. Common values: `587` (STARTTLS), `465` (SSL), `25` (plain, not recommended).

#### `smtp_from`
**Default:** _(empty)_

The "from" email address used for outgoing messages, e.g. `meshcentral@example.com`.

#### `smtp_user`
**Default:** _(empty)_

SMTP username for authentication.

#### `smtp_pass`
**Default:** _(empty)_

SMTP password for authentication. Stored securely.

#### `smtp_tls`
**Default:** `true`

Enable TLS/STARTTLS for the SMTP connection. Should be `true` for port 587. Set to `false` only if your SMTP server does not support TLS.

---

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 4430 | HTTPS | MeshCentral web interface and agent connections |
| 4431 | HTTP | Redirects automatically to HTTPS on port 4430 |
| 4433 | HTTPS | Intel AMT / MPS port |

---

## Support

- Add-on repository: [ha-meshcentral-addon](https://github.com/andlo/ha-meshcentral-addon)
- HA integration: [ha-meshcentral](https://github.com/andlo/ha-meshcentral)
- MeshCentral documentation: [meshcentral.com/info](https://meshcentral.com/info)
