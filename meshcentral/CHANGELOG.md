# Changelog

## \[0.2.17\] - 2026-08-21

### Added

- Custom AppArmor profile (`apparmor.txt`), replacing Supervisor's default profile with one scoped to what the add-on actually needs: S6/bashio boilerplate, `node`/`jq`, `/opt/meshcentral`, and the `/config` + `/data` storage paths. Improves the add-on's security rating and reduces its default attack surface.

  **Note:** this is a first pass, built from code review rather than live audit-log testing. If you notice the add-on failing to start, permission errors in the log, or features (agent connections, backups, plugins, etc.) misbehaving after updating, please report it on [#16](https://github.com/andlo/ha-meshcentral-addon/issues/16) — we can ship a follow-up release with the profile disabled (`apparmor: false`) within minutes if needed.

Addresses [#16](https://github.com/andlo/ha-meshcentral-addon/issues/16).

## \[0.2.16\] - 2026-08-21

### Documentation

- Documented `config_override` (the deep-merge raw JSON escape hatch) and the location of MeshCentral's persistent data directories under the add-on's config storage. Both already existed but weren't covered in DOCS.md.

Follow-up to [#17](https://github.com/andlo/ha-meshcentral-addon/issues/17).

## \[0.2.15\] - 2026-08-08

### Added

- `mstsc` — enable/disable MeshCentral's built-in web-based RDP client (agentless RDP). Enabled by default, matching MeshCentral's own default.
- `ssh` — enable MeshCentral's built-in web-based SSH client (agentless SSH). Disabled by default, matching MeshCentral's own default. A startup warning is logged if enabled together with `agent_pong`/`browser_pong`, since agentless SSH is incompatible with those keepalive options.

Requested in [#12](https://github.com/andlo/ha-meshcentral-addon/issues/12).

## \[0.2.14\] - 2026-07-26

### Added

- **Reverse proxy / tunnel options** — makes MeshCentral fully usable behind Cloudflare Tunnel, NGINX Proxy Manager, Traefik, etc. (thanks @ddcash):
  - `alias_port` — the publicly visible HTTPS port (e.g. `443` behind Cloudflare Tunnel). Without it, agent installers point at port 4430 and agents behind a proxy can never connect.
  - `agent_alias_port` / `agent_alias_dns` — same aliasing for the dedicated agent port
  - `agent_pong` / `browser_pong` — WebSocket keepalive intervals; needed behind proxies that drop idle connections (Cloudflare: ~100 s)
- `minify` — serve reduced-size web pages
- `config_override` — advanced: raw JSON object deep-merged on top of the generated config.json as the last step, making every MeshCentral setting reachable even without a dedicated add-on option

## \[0.2.13\] - 2026-07-10

### Added

- `plugins` — enable the MeshCentral plugin system. Adds a **Plugins** tab under **My Server** where administrators can install, update and remove plugins. Installed plugins are stored in the add-on's persistent data folder and persist across restarts, updates and backups. Disabled by default.

### Changed

- **Persistent storage** — MeshCentral's database, certificates, backups and recordings now live in the add-on configuration folder (`/addon_configs/<slug>_meshcentral`, the `addon_config` mapping) instead of `/data`. This folder survives add-on updates, rebuilds and uninstall/reinstall, and is reachable via the Samba **addon_configs** share. Existing installs are migrated automatically on first start.

## \[0.2.12\] - 2026-07-07

### Added

- `allow_login_token` — enable per-user Login Tokens (`~t:...` username format). Required when using the [MeshCentral HA integration](https://github.com/andlo/ha-meshcentral) with accounts that have 2FA enabled, since the integration authenticates using a Login Token instead of a password. Disabled by default. See [ha-meshcentral#12](https://github.com/andlo/ha-meshcentral/issues/12).

## \[0.2.11\] - 2026-05-01

### Added

- **15 new configuration options** — all configurable directly from the HA add-on Configuration tab:
  - `site_style` — login page style (1 = classic, 2 = modern)
  - `welcome_text` — custom text shown on the login screen
  - `new_accounts_pass` — optional password required to create a new account
  - `guest_device_sharing` — enable/disable guest sharing links for desktop sessions
  - `auto_remove_inactive_devices` — automatically remove devices offline for N days (0 = disabled)
  - `no_2fa` — disable two-factor authentication requirement
  - `max_invalid_login_count` — max failed login attempts before IP is blocked (default: 10)
  - `max_invalid_login_time` — time window in minutes for counting failed attempts (default: 10)
  - `allow_high_quality_desktop` — cap remote desktop image quality to reduce bandwidth
  - `allow_framing` — allow embedding MeshCentral in an iframe
  - `agent_port` — optional dedicated HTTPS port for agent connections only
  - `backup_interval_hours` — how often automatic backups run (default: 24h)
  - `backup_keep_days` — how many days of backups to retain (default: 10)
  - `backup_zip_password` — optional encryption password for backup ZIP files
- `compression` default changed to `true` — GZIP enabled out of the box

### Documentation

- README configuration section fully rewritten with all options, grouped into: General/network, Domain/appearance, Security, Features, Backup, Email (SMTP)
- Added descriptions and defaults for every option

---


## \[0.2.7\] - 2026-04-28

### Added

- Port 80 (mapped to 4431 externally) — HTTP redirects to HTTPS automatically, so `http://homeassistant.local:4431` redirects to the HTTPS interface without needing to type `https://`
- Startup log now shows the exact URLs to open MeshCentral, so users know where to go without reading the documentation

---

## \[0.2.6\] - 2026-04-28

### Fixed

- Move backup path to `/data/meshcentral-backups` (outside `meshcentral-data`) — fixes MeshCentral backup warning on startup

---

## \[0.2.5\] - 2026-04-28

### Fixed

- Use local `npm install` instead of `npm install -g --prefix` — global install did not include all MeshCentral native files (`exeHandler.js`)
- Local install in `/opt/meshcentral` gives a complete, working installation

---

## \[0.2.4\] - 2026-04-28

### Fixed

- Install MeshCentral to fixed path `/opt/meshcentral` using `--prefix` flag
- Fixes `Cannot find module` error caused by Node.js 24 installing globals to a different path

---

## \[0.2.3\] - 2026-04-28

### Fixed

- Add `init: false` to config.yaml — fixes `s6-overlay-suexec: fatal: can only run as pid 1` startup crash
- s6-overlay v3 (used in HA base images) requires running as PID 1 — Docker default `--init` flag prevented this

---

## \[0.2.2\] - 2026-04-28

### Fixed

- Dockerfile: use s6-overlay service structure instead of `CMD` — partial fix attempt (superseded by 0.2.3)

---

## \[0.2.1\] - 2026-04-28

### Added

- All MeshCentral settings now configurable directly from the HA add-on **Configuration** tab — no manual JSON editing needed
- New options: `server_mode` (lan/wan/hybrid), `new_accounts`, `domain_title`, `domain_title2`, `session_key`, `session_time`, `tls_offload`, `trusted_proxy`
- IP access control options: `user_allowed_ip`, `user_blocked_ip`, `agent_allowed_ip`, `agent_blocked_ip`
- Feature toggles: `web_rtc`, `compression`, `self_update`, `maintenance_mode`
- Full SMTP configuration: `smtp_enabled`, `smtp_host`, `smtp_port`, `smtp_from`, `smtp_user`, `smtp_pass`, `smtp_tls`
- Official MeshCentral icon and logo
- Screenshots in README

### Fixed

- `tls_offload` default changed to `false` — was `true`, which broke local use without a reverse proxy
- `new_accounts` default changed to `true` so first-time users can create their admin account without editing JSON files
- All optional config fields now correctly declared as optional (`str?`) in schema
- `run.sh` now regenerates `config.json` on every start so HA options always stay in sync
- Startup warning logged when `new_accounts` is enabled
- Removed unused `allow_device_sharing` option

### Documentation

- README rewritten with quick start guide and full configuration reference tables

---

## \[0.1.0\] - Initial release

- Initial MeshCentral add-on for Home Assistant
- Basic configuration: `data_path`, `hostname`, `cert_url`, `allow_device_sharing`
