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
PLUGINS=$(bashio::config 'plugins')
LOGIN_COUNT=$(bashio::config 'max_invalid_login_count')
LOGIN_TIME=$(bashio::config 'max_invalid_login_time')
AUTO_REMOVE=$(bashio::config 'auto_remove_inactive_devices')
AGENT_PORT=$(bashio::config 'agent_port')
MPS_PORT=$(bashio::config 'mps_port')
BACKUP_INTERVAL=$(bashio::config 'backup_interval_hours')
BACKUP_KEEP=$(bashio::config 'backup_keep_days')
SMTP_ENABLED=$(bashio::config 'smtp_enabled')
ALIAS_PORT=$(bashio::config 'alias_port')
AGENT_ALIAS_PORT=$(bashio::config 'agent_alias_port')
AGENT_PONG=$(bashio::config 'agent_pong')
BROWSER_PONG=$(bashio::config 'browser_pong')
MINIFY=$(bashio::config 'minify')
OIDC_ENABLED=$(bashio::config 'oidc_enabled')
OIDC_NEW_ACCOUNTS=$(bashio::config 'oidc_new_accounts')

# ── Paths ─────────────────────────────────────────────────────────────────────
DATA_PATH="/data/meshcentral-data"
FILES_PATH="${DATA_PATH}/meshcentral-files"
BACKUP_PATH="/data/meshcentral-backups"
RECORDINGS_PATH="${DATA_PATH}/meshcentral-recordings"
CONFIG_FILE="${DATA_PATH}/config.json"

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

# Alias ports — the publicly visible ports when behind a reverse proxy or tunnel
# that listens on a different port than MeshCentral itself (e.g. Cloudflare on 443).
# These control the port written into agent installers and links.
if [ "$ALIAS_PORT" -gt 0 ] 2>/dev/null; then
    SETTINGS=$(echo "$SETTINGS" | jq --argjson v "$ALIAS_PORT" '. + {aliasPort: $v}')
fi
if [ "$AGENT_ALIAS_PORT" -gt 0 ] 2>/dev/null; then
    SETTINGS=$(echo "$SETTINGS" | jq --argjson v "$AGENT_ALIAS_PORT" '. + {agentAliasPort: $v}')
fi
if bashio::config.has_value 'agent_alias_dns'; then
    SETTINGS=$(echo "$SETTINGS" | jq --arg v "$(bashio::config 'agent_alias_dns')" '. + {agentAliasDNS: $v}')
fi

# Keepalive intervals — needed behind proxies that drop idle WebSockets
# (e.g. Cloudflare closes idle connections after ~100 seconds).
if [ "$AGENT_PONG" -gt 0 ] 2>/dev/null; then
    SETTINGS=$(echo "$SETTINGS" | jq --argjson v "$AGENT_PONG" '. + {agentPong: $v}')
fi
if [ "$BROWSER_PONG" -gt 0 ] 2>/dev/null; then
    SETTINGS=$(echo "$SETTINGS" | jq --argjson v "$BROWSER_PONG" '. + {browserPong: $v}')
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

# Plugins — adds the Plugins tab under My Server where plugins are installed and managed.
# Installed plugins live under the datapath and survive add-on restarts and updates.
if [ "$PLUGINS" = "true" ]; then
    SETTINGS=$(echo "$SETTINGS" | jq '. + {plugins: {enabled: true}}')
    bashio::log.info "Plugins enabled (plugins.enabled: true)"
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

if [ "$MINIFY" = "true" ]; then
    DOMAIN=$(echo "$DOMAIN" | jq '. + {minify: true}')
fi

# OIDC single sign-on (optional)
if [ "$OIDC_ENABLED" = "true" ]; then
    if bashio::config.has_value 'oidc_issuer' && bashio::config.has_value 'oidc_client_id' && bashio::config.has_value 'oidc_client_secret'; then
        OIDC_JSON=$(jq -n \
            --arg     iss "$(bashio::config 'oidc_issuer')" \
            --arg     cid "$(bashio::config 'oidc_client_id')" \
            --arg     sec "$(bashio::config 'oidc_client_secret')" \
            --argjson na  "$OIDC_NEW_ACCOUNTS" \
            '{issuer: $iss, client: {client_id: $cid, client_secret: $sec}, newAccounts: $na}')
        # redirect_uri defaults to https://<host>/auth-oidc-callback inside MeshCentral;
        # only override it when explicitly configured.
        if bashio::config.has_value 'oidc_callback_url'; then
            OIDC_JSON=$(echo "$OIDC_JSON" | jq --arg v "$(bashio::config 'oidc_callback_url')" '.client += {redirect_uri: $v}')
        fi
        DOMAIN=$(echo "$DOMAIN" | jq --argjson v "$OIDC_JSON" '. + {authStrategies: {oidc: $v}}')
        bashio::log.info "OIDC single sign-on enabled (issuer: $(bashio::config 'oidc_issuer'))"
    else
        bashio::log.warning "oidc_enabled is true but oidc_issuer, oidc_client_id or oidc_client_secret is missing — OIDC not configured."
    fi
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

# ── Apply raw JSON overrides (advanced) ───────────────────────────────────────
# config_override is deep-merged on top of the generated config as the last step,
# so any MeshCentral setting can be reached even if the add-on has no option for it.
if bashio::config.has_value 'config_override'; then
    OVERRIDE=$(bashio::config 'config_override')
    if echo "$OVERRIDE" | jq -e 'type == "object"' >/dev/null 2>&1; then
        CONFIG=$(jq -n --argjson base "$CONFIG" --argjson ovr "$OVERRIDE" '$base * $ovr')
        bashio::log.info "config_override applied on top of the generated config."
    else
        bashio::log.warning "config_override is not a valid JSON object — ignored."
    fi
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
