#!/usr/bin/with-contenv bashio

# ── Read options ──────────────────────────────────────────────────────────────
SERVER_MODE=$(bashio::config 'server_mode')
NEW_ACCOUNTS=$(bashio::config 'new_accounts')
DOMAIN_TITLE=$(bashio::config 'domain_title')
SESSION_TIME=$(bashio::config 'session_time')
ALLOW_LOGIN_TOKEN=$(bashio::config 'allow_login_token')
TLS_OFFLOAD=$(bashio::config 'tls_offload')
WEB_RTC=$(bashio::config 'web_rtc')
COMPRESSION=$(bashio::config 'compression')
ALLOW_HQ_DESKTOP=$(bashio::config 'allow_high_quality_desktop')
SELF_UPDATE=$(bashio::config 'self_update')
MAINTENANCE=$(bashio::config 'maintenance_mode')
NO_2FA=$(bashio::config 'no_2fa')
SITE_STYLE=$(bashio::config 'site_style')
GUEST_SHARING=$(bashio::config 'guest_device_sharing')
ALLOW_FRAMING=$(bashio::config 'allow_framing')
LOGIN_COUNT=$(bashio::config 'max_invalid_login_count')
LOGIN_TIME=$(bashio::config 'max_invalid_login_time')
AUTO_REMOVE=$(bashio::config 'auto_remove_inactive_devices')
AGENT_PORT=$(bashio::config 'agent_port')
MPS_PORT=$(bashio::config 'mps_port')
BACKUP_INTERVAL=$(bashio::config 'backup_interval_hours')
BACKUP_KEEP=$(bashio::config 'backup_keep_days')
SMTP_ENABLED=$(bashio::config 'smtp_enabled')

# ── Paths ─────────────────────────────────────────────────────────────────────
# Everything lives in the add-on config folder (/addon_configs/<slug>, mounted
# at /config) so the database and settings persist across updates, rebuilds
# and reinstalls — unlike /data, which is deleted on uninstall.
DATA_PATH="/config/meshcentral-data"
FILES_PATH="${DATA_PATH}/meshcentral-files"
BACKUP_PATH="/config/meshcentral-backups"
RECORDINGS_PATH="${DATA_PATH}/meshcentral-recordings"
CONFIG_FILE="${DATA_PATH}/config.json"

# One-time migration from the old /data location
if [ -d /data/meshcentral-data ] && [ ! -d "${DATA_PATH}" ]; then
    cp -a /data/meshcentral-data "${DATA_PATH}"
    bashio::log.info "Migrated MeshCentral data from /data to /config (persistent storage)."
fi
if [ -d /data/meshcentral-backups ] && [ ! -d "${BACKUP_PATH}" ]; then
    cp -a /data/meshcentral-backups "${BACKUP_PATH}"
fi

# ── Hostname ──────────────────────────────────────────────────────────────────
HOSTNAME=$(bashio::info.hostname)
if bashio::config.has_value 'hostname'; then
    HOSTNAME=$(bashio::config 'hostname')
fi

bashio::log.info "Starting MeshCentral..."
bashio::log.info "Server mode: ${SERVER_MODE}"
bashio::log.info "Hostname: ${HOSTNAME}"

mkdir -p "${DATA_PATH}" "${FILES_PATH}" "${BACKUP_PATH}" "${RECORDINGS_PATH}"

# ── Remove old certs so MeshCentral regenerates with current config ───────────
MESHDATA="${DATA_PATH}/meshcentral-data"
if [ -d "$MESHDATA" ]; then
    rm -f "$MESHDATA"/*.crt "$MESHDATA"/*.key 2>/dev/null || true
    bashio::log.info "Old certificates removed — will be regenerated with current settings."
fi

# ── Build settings ────────────────────────────────────────────────────────────
SETTINGS="{}"

# Network mode
if [ "$SERVER_MODE" = "wan" ]; then
    SETTINGS=$(echo "$SETTINGS" | jq '. + {WANonly: true}')
elif [ "$SERVER_MODE" = "lan" ]; then
    SETTINGS=$(echo "$SETTINGS" | jq '. + {LANonly: true}')
fi

# Ports
SETTINGS=$(echo "$SETTINGS" | jq \
    --argjson mps "$MPS_PORT" \
    '. + {port: 4430, redirPort: 4431, mpsPort: $mps}')

# Optional dedicated agent port
if [ "$AGENT_PORT" -gt 0 ] 2>/dev/null; then
    SETTINGS=$(echo "$SETTINGS" | jq --argjson v "$AGENT_PORT" '. + {agentPort: $v}')
fi

# Cert / hostname
if bashio::config.has_value 'cert_url'; then
    CERT_HOST=$(bashio::config 'cert_url' | sed 's|https://||' | sed 's|http://||' | sed 's|/.*||')
    SETTINGS=$(echo "$SETTINGS" | jq --arg v "$CERT_HOST" '. + {cert: $v}')
else
    SETTINGS=$(echo "$SETTINGS" | jq --arg v "homeassistant.local" '. + {cert: $v}')
fi
SETTINGS=$(echo "$SETTINGS" | jq --argjson v "$TLS_OFFLOAD" '. + {tlsOffload: $v}')

# Trusted proxy (optional)
if bashio::config.has_value 'trusted_proxy'; then
    SETTINGS=$(echo "$SETTINGS" | jq --arg v "$(bashio::config 'trusted_proxy')" '. + {trustedProxy: $v}')
fi

# Login Token support — required for ~t:... tokens used by the HA integration
# See: https://github.com/andlo/ha-meshcentral/issues/12
if [ "$ALLOW_LOGIN_TOKEN" = "true" ]; then
    SETTINGS=$(echo "$SETTINGS" | jq '. + {allowLoginToken: true}')
    bashio::log.info "Login Tokens enabled (allowLoginToken: true)"
fi

# Session
SETTINGS=$(echo "$SETTINGS" | jq --argjson v "$SESSION_TIME" '. + {sessionTime: $v}')
if bashio::config.has_value 'session_key'; then
    SETTINGS=$(echo "$SETTINGS" | jq --arg v "$(bashio::config 'session_key')" '. + {sessionKey: $v}')
fi

# Features
SETTINGS=$(echo "$SETTINGS" | jq \
    --argjson rtc  "$WEB_RTC" \
    --argjson comp "$COMPRESSION" \
    --argjson hq   "$ALLOW_HQ_DESKTOP" \
    --argjson upd  "$SELF_UPDATE" \
    --argjson fr   "$ALLOW_FRAMING" \
    '. + {webRTC: $rtc, compression: $comp, allowHighQualityDesktop: $hq, selfUpdate: $upd, allowFraming: $fr}')

if [ "$MAINTENANCE" = "true" ]; then
    SETTINGS=$(echo "$SETTINGS" | jq '. + {maintenanceMode: true}')
fi

if [ "$NO_2FA" = "true" ]; then
    SETTINGS=$(echo "$SETTINGS" | jq '. + {no2FactorAuth: true}')
fi

# Invalid login rate limiting
SETTINGS=$(echo "$SETTINGS" | jq \
    --argjson cnt "$LOGIN_COUNT" \
    --argjson tim "$LOGIN_TIME" \
    '. + {maxInvalidLogin: {count: $cnt, time: $tim}}')

# IP access control (all optional)
if bashio::config.has_value 'user_allowed_ip'; then
    SETTINGS=$(echo "$SETTINGS" | jq --arg v "$(bashio::config 'user_allowed_ip')" '. + {userAllowedIP: $v}')
fi
if bashio::config.has_value 'user_blocked_ip'; then
    SETTINGS=$(echo "$SETTINGS" | jq --arg v "$(bashio::config 'user_blocked_ip')" '. + {userBlockedIP: $v}')
fi
if bashio::config.has_value 'agent_allowed_ip'; then
    SETTINGS=$(echo "$SETTINGS" | jq --arg v "$(bashio::config 'agent_allowed_ip')" '. + {agentAllowedIP: $v}')
fi
if bashio::config.has_value 'agent_blocked_ip'; then
    SETTINGS=$(echo "$SETTINGS" | jq --arg v "$(bashio::config 'agent_blocked_ip')" '. + {agentBlockedIP: $v}')
fi

# Autobackup
BACKUP_JSON=$(jq -n \
    --arg     bp  "$BACKUP_PATH" \
    --argjson ivl "$BACKUP_INTERVAL" \
    --argjson kp  "$BACKUP_KEEP" \
    '{backupPath: $bp, backupIntervalHours: $ivl, keepLastDaysBackup: $kp}')
if bashio::config.has_value 'backup_zip_password'; then
    BACKUP_JSON=$(echo "$BACKUP_JSON" | jq --arg v "$(bashio::config 'backup_zip_password')" '. + {zipPassword: $v}')
fi
SETTINGS=$(echo "$SETTINGS" | jq --argjson v "$BACKUP_JSON" '. + {autoBackup: $v}')

# ── Build domain ──────────────────────────────────────────────────────────────
DOMAIN="{}"
DOMAIN=$(echo "$DOMAIN" | jq \
    --arg     ttl  "$DOMAIN_TITLE" \
    --argjson na   "$NEW_ACCOUNTS" \
    --argjson ss   "$SITE_STYLE" \
    --argjson gs   "$GUEST_SHARING" \
    --argjson ar   "$AUTO_REMOVE" \
    '. + {title: $ttl, newAccounts: $na, siteStyle: $ss, guestDeviceSharing: $gs, autoRemoveInactiveDevices: $ar}')

if bashio::config.has_value 'domain_title2'; then
    DOMAIN=$(echo "$DOMAIN" | jq --arg v "$(bashio::config 'domain_title2')" '. + {title2: $v}')
fi

if bashio::config.has_value 'welcome_text'; then
    DOMAIN=$(echo "$DOMAIN" | jq --arg v "$(bashio::config 'welcome_text')" '. + {welcomeText: $v}')
fi

if bashio::config.has_value 'new_accounts_pass'; then
    DOMAIN=$(echo "$DOMAIN" | jq --arg v "$(bashio::config 'new_accounts_pass')" '. + {newAccountsPass: $v}')
fi

if bashio::config.has_value 'cert_url'; then
    DOMAIN=$(echo "$DOMAIN" | jq --arg v "$(bashio::config 'cert_url')" '. + {certUrl: $v}')
fi

DOMAIN=$(echo "$DOMAIN" | jq --arg rp "$RECORDINGS_PATH" \
    '. + {sessionRecording: {filepath: $rp}}')

# ── Build SMTP ────────────────────────────────────────────────────────────────
SMTP_JSON="null"
if [ "$SMTP_ENABLED" = "true" ] && bashio::config.has_value 'smtp_host'; then
    SMTP_PORT=587
    SMTP_TLS=true
    if bashio::config.has_value 'smtp_port'; then SMTP_PORT=$(bashio::config 'smtp_port'); fi
    if bashio::config.has_value 'smtp_tls';  then SMTP_TLS=$(bashio::config 'smtp_tls');   fi

    SMTP_JSON=$(jq -n \
        --arg    host "$(bashio::config 'smtp_host')" \
        --argjson port "$SMTP_PORT" \
        --arg    from "$(bashio::config 'smtp_from')" \
        --arg    user "$(bashio::config 'smtp_user')" \
        --arg    pass "$(bashio::config 'smtp_pass')" \
        --argjson tls  "$SMTP_TLS" \
        '{host: $host, port: $port, from: $from, user: $user, pass: $pass, tls: $tls}')
    bashio::log.info "SMTP enabled: $(bashio::config 'smtp_host'):${SMTP_PORT}"
fi

# ── Assemble and write config.json ────────────────────────────────────────────
if [ "$SMTP_JSON" = "null" ]; then
    CONFIG=$(jq -n \
        --argjson settings "$SETTINGS" \
        --argjson domain   "$DOMAIN" \
        '{settings: $settings, domains: {"": $domain}}')
else
    CONFIG=$(jq -n \
        --argjson settings "$SETTINGS" \
        --argjson domain   "$DOMAIN" \
        --argjson smtp     "$SMTP_JSON" \
        '{settings: $settings, domains: {"": $domain}, smtp: $smtp}')
fi

echo "$CONFIG" > "$CONFIG_FILE"
bashio::log.info "config.json written."

if [ "$NEW_ACCOUNTS" = "true" ]; then
    bashio::log.warning "new_accounts is ON — remember to disable it after creating your admin account!"
fi

if [ "$ALLOW_LOGIN_TOKEN" = "true" ]; then
    bashio::log.info "Login Tokens are enabled. To use them in the MeshCentral HA integration,"
    bashio::log.info "go to MeshCentral → My Account → Login Tokens and create a token."
    bashio::log.info "Use the generated username (~t:...) and password in the integration setup."
fi

# ── Start MeshCentral ─────────────────────────────────────────────────────────
bashio::log.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bashio::log.info " MeshCentral is starting..."
bashio::log.info " Open in browser (accept certificate warning):"
bashio::log.info "   https://homeassistant.local:4430"
bashio::log.info " Or via HTTP redirect:"
bashio::log.info "   http://homeassistant.local:4431"
bashio::log.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exec node /opt/meshcentral/node_modules/meshcentral \
    --datapath "${DATA_PATH}" \
    --filespath "${FILES_PATH}"
