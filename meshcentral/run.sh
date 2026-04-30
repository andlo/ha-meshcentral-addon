#!/usr/bin/with-contenv bashio

# Read required options
SERVER_MODE=$(bashio::config 'server_mode')
NEW_ACCOUNTS=$(bashio::config 'new_accounts')
DOMAIN_TITLE=$(bashio::config 'domain_title')
SESSION_TIME=$(bashio::config 'session_time')
TLS_OFFLOAD=$(bashio::config 'tls_offload')
WEB_RTC=$(bashio::config 'web_rtc')
COMPRESSION=$(bashio::config 'compression')
SELF_UPDATE=$(bashio::config 'self_update')
MAINTENANCE=$(bashio::config 'maintenance_mode')
SMTP_ENABLED=$(bashio::config 'smtp_enabled')

# Data path — fixed location inside HA addon data
DATA_PATH="/data/meshcentral-data"
FILES_PATH="${DATA_PATH}/meshcentral-files"
BACKUP_PATH="/data/meshcentral-backups"
RECORDINGS_PATH="${DATA_PATH}/meshcentral-recordings"
CONFIG_FILE="${DATA_PATH}/config.json"

# Use HA hostname as fallback
HOSTNAME=$(bashio::info.hostname)
if bashio::config.has_value 'hostname'; then
    HOSTNAME=$(bashio::config 'hostname')
fi

# Get HA's local IP for cert — this is what users browse to
HA_IP=$(bashio::info.ip_address 2>/dev/null || echo "")

bashio::log.info "Starting MeshCentral..."
bashio::log.info "Server mode: ${SERVER_MODE}"
bashio::log.info "Hostname: ${HOSTNAME}"
if [ -n "$HA_IP" ]; then
    bashio::log.info "IP address: ${HA_IP}"
fi

mkdir -p "${DATA_PATH}" "${FILES_PATH}" "${BACKUP_PATH}" "${RECORDINGS_PATH}"

# Remove old certs on every start so MeshCentral regenerates them with current config
# This ensures the cert CN always matches the current IP/hostname
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
# hybrid: neither flag set — MeshCentral default behaviour

# Ports — MeshCentral listens directly on external ports to avoid origin mismatch
SETTINGS=$(echo "$SETTINGS" | jq '. + {port: 4430, redirPort: 4431, mpsPort: 4433}')

# Cert — set to HA IP so MeshCentral's origin check matches what the browser sends
if bashio::config.has_value 'cert_url'; then
    CERT_HOST=$(bashio::config 'cert_url' | sed 's|https://||' | sed 's|http://||' | sed 's|/.*||')
    SETTINGS=$(echo "$SETTINGS" | jq --arg v "$CERT_HOST" '. + {cert: $v}')
elif [ -n "$HA_IP" ]; then
    SETTINGS=$(echo "$SETTINGS" | jq --arg v "$HA_IP" '. + {cert: $v}')
fi
SETTINGS=$(echo "$SETTINGS" | jq --argjson v "$TLS_OFFLOAD" '. + {tlsOffload: $v}')

# Trusted proxy (optional)
if bashio::config.has_value 'trusted_proxy'; then
    TRUSTED_PROXY=$(bashio::config 'trusted_proxy')
    SETTINGS=$(echo "$SETTINGS" | jq --arg v "$TRUSTED_PROXY" '. + {trustedProxy: $v}')
fi

# Session
SETTINGS=$(echo "$SETTINGS" | jq --argjson v "$SESSION_TIME" '. + {sessionTime: $v}')
if bashio::config.has_value 'session_key'; then
    SESSION_KEY=$(bashio::config 'session_key')
    SETTINGS=$(echo "$SETTINGS" | jq --arg v "$SESSION_KEY" '. + {sessionKey: $v}')
fi

# Features
SETTINGS=$(echo "$SETTINGS" | jq \
    --argjson rtc "$WEB_RTC" \
    --argjson comp "$COMPRESSION" \
    --argjson upd "$SELF_UPDATE" \
    '. + {webRTC: $rtc, compression: $comp, selfUpdate: $upd}')

if [ "$MAINTENANCE" = "true" ]; then
    SETTINGS=$(echo "$SETTINGS" | jq '. + {maintenanceMode: true}')
fi

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

# Autobackup — placeres uden for DATA_PATH
SETTINGS=$(echo "$SETTINGS" | jq --arg bp "$BACKUP_PATH" '. + {autoBackup: {backupPath: $bp}}')

# ── Build domain ──────────────────────────────────────────────────────────────

DOMAIN="{}"
DOMAIN=$(echo "$DOMAIN" | jq --arg v "$DOMAIN_TITLE" '. + {title: $v}')

if bashio::config.has_value 'domain_title2'; then
    DOMAIN=$(echo "$DOMAIN" | jq --arg v "$(bashio::config 'domain_title2')" '. + {title2: $v}')
fi

DOMAIN=$(echo "$DOMAIN" | jq --argjson v "$NEW_ACCOUNTS" '. + {newAccounts: $v}')

# certUrl — required for agents connecting from outside LAN
if bashio::config.has_value 'cert_url'; then
    DOMAIN=$(echo "$DOMAIN" | jq --arg v "$(bashio::config 'cert_url')" '. + {certUrl: $v}')
fi

DOMAIN=$(echo "$DOMAIN" | jq --arg rp "$RECORDINGS_PATH" \
    '. + {sessionRecording: {filepath: $rp}}')

# ── Build SMTP (only if enabled and host is set) ──────────────────────────────

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

# ── Start MeshCentral ─────────────────────────────────────────────────────────

HA_IP=$(bashio::info.ip_address 2>/dev/null || echo "homeassistant.local")
HTTPS_PORT=$(bashio::addon.port "443/tcp" 2>/dev/null || echo "4430")
HTTP_PORT=$(bashio::addon.port "80/tcp" 2>/dev/null || echo "4431")

bashio::log.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bashio::log.info " MeshCentral is starting..."
bashio::log.info " Open in browser (accept certificate warning):"
bashio::log.info "   https://${HA_IP}:${HTTPS_PORT}"
bashio::log.info " Or via HTTP redirect:"
bashio::log.info "   http://${HA_IP}:${HTTP_PORT}"
bashio::log.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

bashio::log.info "Starting MeshCentral node process..."
exec node /opt/meshcentral/node_modules/meshcentral \
    --datapath "${DATA_PATH}" \
    --filespath "${FILES_PATH}"
