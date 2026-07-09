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

## Using with the MeshCentral HA integration

If you plan to use this add-on together with the [MeshCentral HA integration](https://github.com/andlo/ha-meshcentral), make sure **Enable Login Tokens** (`allow_login_token`) is set to `true` in the add-on configuration.

This is required if your MeshCentral account has **2FA enabled** — the integration authenticates using a Login Token (`~t:...` username) instead of your password, which bypasses 2FA. Without `allowLoginToken: true` in the server config, MeshCentral will reject these tokens and the integration will fail to connect.

**How to set it up:**

1. Enable `allow_login_token: true` in the add-on options and restart
2. Log in to MeshCentral → **My Account** → **Login Tokens** → Create a token
3. In the HA integration setup, enter the generated username (`~t:...`) and the token password

> **Note:** Even without 2FA, Login Tokens are a good practice for automation — they can be revoked individually without changing your main password.

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

If set to a non-zero port number, MeshCentral opens a dedicated HTTPS port exclusively for agent connections, separate from the main web interface port (4430). Set to `0` to use the main port for everything.

#### `alias_port`
**Default:** `0` _(disabled)_

The publicly visible HTTPS port when MeshCentral runs behind a reverse proxy or tunnel that listens on a different port than MeshCentral itself. This controls the port MeshCentral writes into agent installers and generated links.

**Important for Cloudflare Tunnel / reverse proxies on port 443:** without this, agent installers point at port 4430, which the proxy does not listen on, and agents can never connect. Set `alias_port: 443` so agents connect through the proxy's HTTPS port.

#### `agent_alias_port` / `agent_alias_dns`
**Default:** `0` / _(empty)_

Same aliasing for the dedicated agent port (`agent_port`): the publicly visible port and optional separate DNS name agents should use. Only relevant when `agent_port` is set.

#### `agent_pong` / `browser_pong`
**Default:** `0` _(disabled)_

Send keepalive data to connected agents/browsers every this many seconds. Needed behind proxies that drop idle WebSocket connections — Cloudflare, for example, closes idle connections after ~100 seconds, causing agents to disconnect and reconnect repeatedly. `60` is a good value behind Cloudflare.

#### `mps_port`
**Default:** `4433`

Port for Intel AMT / MPS (Management Presence Server) connections. Only relevant if you manage Intel vPro/AMT devices.

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

Login page visual style. `1` = classic, `2` = modern.

#### `welcome_text`
**Default:** _(empty)_

Optional text shown on the login page below the title.

---

### Accounts & Security

#### `new_accounts`
**Default:** `true`

Allow new users to register on the login page. Disable after creating your admin account.

#### `new_accounts_pass`
**Default:** _(empty)_

Optional shared invite code required during registration. Only relevant when `new_accounts` is `true`.

#### `session_time`
**Default:** `60`

How long (in minutes) a user session stays active without activity. Set to `0` for sessions that never expire.

#### `allow_login_token`
**Default:** `false`

Enable support for per-user Login Tokens (`~t:...` username format). **Required when using the MeshCentral HA integration with 2FA accounts.** See the [Using with the HA integration](#using-with-the-meshcentral-ha-integration) section above.

When enabled, users can generate tokens under **My Account → Login Tokens**. Tokens authenticate without requiring the account password or a 2FA code, making them ideal for integrations and automations.

#### `no_2fa`
**Default:** `false`

Disable the two-factor authentication requirement for all users. Not recommended for internet-facing servers.

#### `max_invalid_login_count`
**Default:** `10`

Number of failed login attempts before an IP is temporarily blocked.

#### `max_invalid_login_time`
**Default:** `10`

Time window in minutes over which failed attempts are counted.

#### `user_allowed_ip` / `user_blocked_ip`
**Default:** _(empty)_

Comma-separated IP addresses or CIDR ranges for web interface access control.

---

### Features

#### `web_rtc`
**Default:** `false`

Enable WebRTC for direct peer-to-peer remote desktop. Requires open UDP ports.

#### `compression`
**Default:** `true`

Enable GZIP compression for web traffic. Recommended to keep enabled.

#### `allow_high_quality_desktop`
**Default:** `true`

Allow full-quality remote desktop streaming. Disable to reduce bandwidth.

#### `guest_device_sharing`
**Default:** `true`

Allow users to create one-click guest sharing links for remote desktop sessions.

#### `allow_framing`
**Default:** `false`

Allow MeshCentral to be embedded in an iframe. Disabled by default to prevent clickjacking.

#### `self_update`
**Default:** `false`

Allow MeshCentral to update itself. Not recommended — the add-on controls the version.

#### `maintenance_mode`
**Default:** `false`

Block all user logins while keeping agents connected. Useful during configuration changes.

#### `minify`
**Default:** `false`

Serve reduced-size web pages to save bandwidth.

#### `auto_remove_inactive_devices`
**Default:** `0` _(disabled)_

Auto-remove devices offline for more than this many days. `0` = never.

---

### Agent IP filtering

#### `agent_allowed_ip` / `agent_blocked_ip`
**Default:** _(empty)_

Comma-separated IP addresses or CIDR ranges for agent connection control.

---

### Backup

#### `backup_interval_hours`
**Default:** `24`

How often MeshCentral auto-backs up its database. `0` = disabled.

#### `backup_keep_days`
**Default:** `10`

How many days of backups to keep.

#### `backup_zip_password`
**Default:** _(empty)_

Optional password to encrypt backup ZIP files.

---

### Email (SMTP)

#### `smtp_enabled`
**Default:** `false`

Enable SMTP email for notifications, account verification and 2FA codes.

#### `smtp_host` / `smtp_port` / `smtp_from` / `smtp_user` / `smtp_pass` / `smtp_tls`

Standard SMTP settings. Port `587` with TLS is recommended. See your email provider for details.

---

### Advanced: `config_override`

**Default:** _(empty)_

A raw JSON object that is deep-merged **on top of** the generated `config.json` as the very last step. This makes every MeshCentral setting reachable, even ones this add-on has no dedicated option for — Let's Encrypt, SMS/messaging 2FA, CrowdSec, session recording policy, and everything else in the [MeshCentral config schema](https://github.com/Ylianst/MeshCentral/blob/master/meshcentral-config-schema.json).

Example — enable session recording and a Telegram bot for notifications:

```json
{"domains":{"":{"sessionRecording":true}},"messaging":{"telegram":{"apiid":123456,"apihash":"...","bottoken":"..."}}}
```

Notes:

- The value must be a single JSON **object**. Invalid JSON is ignored with a warning in the add-on log — the add-on still starts with the generated config.
- Keys you set here win over the add-on's generated values (deep merge, object by object).
- Use sparingly: prefer the dedicated options above where they exist, since those are validated by the add-on UI.

---

### Recipe: Cloudflare Tunnel

To expose MeshCentral through a Cloudflare Tunnel (e.g. the Cloudflared add-on) so both browsers **and agents** work:

1. In the Cloudflared add-on, add an `additional_hosts` entry: `hostname: mesh.example.com` → `service: http://homeassistant:4430`.
2. In this add-on, set:
   - `server_mode: hybrid` (or `wan`)
   - `cert_url: https://mesh.example.com`
   - `tls_offload: true` (Cloudflare terminates TLS; the tunnel speaks plain HTTP to the add-on)
   - `alias_port: 443` (**required** — otherwise agent installers point at port 4430, which Cloudflare does not listen on, and agents never connect)
   - `agent_pong: 60` (Cloudflare drops idle WebSockets after ~100 s)
3. Restart the add-on, then download **fresh** agent installers — previously downloaded installers contain the old URL and certificate hash and will not work.

---

## Login Tokens vs LoginKey — what's the difference?

There are two separate "key" concepts in MeshCentral that are easy to confuse:

| | What it is | Where to find it | Purpose |
|---|---|---|---|
| **Login Token** | Per-user temporary token | MeshCentral → My Account → Login Tokens | Used as `~t:...` username in the HA integration to bypass 2FA. Enabled by `allow_login_token: true` in this add-on. |
| **LoginKey (3FA)** | Server-level URL access key | Generated with `--logintokenkey`, stored in the database | Requires `?key=<value>` on all URLs — effectively hides the login page from anyone without the key. Advanced use only. |

**Most users only need Login Tokens** (the first row). Enable `allow_login_token` in this add-on, create a token in My Account, and use it in the HA integration.

**LoginKey (3FA)** is an advanced server-hardening feature. It is not configurable via the add-on UI — if you need it, you must enable it manually after the add-on starts by exec'ing into the container and running:

```bash
node /opt/meshcentral/node_modules/meshcentral --logintokenkey
```

This prints the server's LoginKey. To use it, the HA integration's **Login Key** field must be set to this value. See [ha-meshcentral issue #12](https://github.com/andlo/ha-meshcentral/issues/12) for full details on how the integration handles this.

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
