# Changelog

## [0.2.2] - 2026-04-28

### Fixed
- Dockerfile: use s6-overlay service structure instead of `CMD` — fixes "can only run as pid 1" startup error
- `run.sh` is now placed at `/etc/services.d/meshcentral/run` as required by HA base images

---

## [0.2.1] - 2026-04-28

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
- Removed unused `allow_device_sharing` option that was never written to config

### Documentation
- README rewritten with quick start guide and full configuration reference tables

---

## [0.1.0] - Initial release

- Initial MeshCentral add-on for Home Assistant
- Basic configuration: `data_path`, `hostname`, `cert_url`, `allow_device_sharing`
