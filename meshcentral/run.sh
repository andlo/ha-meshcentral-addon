#!/usr/bin/with-contenv bashio

# Read all options from HA add-on configuration
DATA_PATH=$(bashio::config 'data_path')
HOSTNAME=$(bashio::config 'hostname')
CERT_URL=$(bashio::config 'cert_url')
ALLOW_SHARING=$(bashio::config 'allow_device_sharing')
SERVER_MODE=$(bashio::config 'server_mode')
NEW_ACCOUNTS=$(bashio::config 'new_accounts')
DOMAIN_TITLE=$(bashio::config 'domain_title')
DOMAIN_TITLE2=$(bashio::config 'domain_title2')
SESSION_KEY=$(bashio::config 'session_key')
SESSION_TIME=$(bashio::config 'session_time')
TLS_OFFLOAD=$(bashio::config 'tls_offload')
TRUSTED_PROXY=$(bashio::config 'trusted_proxy')
USER_ALLOWED_IP=$(bashio::config 'user_allowed_ip')
USER_BLOCKED_IP=$(bashio::config 'user_blocked_ip')
AGENT_ALLOWED_IP=$(bashio::config 'agent_allowed_ip')
AGENT_BLOCKED_IP=$(bashio::config 'agent_blocked_ip')
WEB_RTC=$(bashio::config 'web_rtc')
COMPRESSION=$(bashio::config 'compression')
SELF_UPDATE=$(bashio::config 'self_update')
MAINTENANCE=$(bashio::config 'maintenance_mode')
SMTP_ENABLED=$(bashio::config 'smtp_enabled')
SMTP_HOST=$(bashio::config 'smtp_host')
SMTP_PORT=$(bashio::config 'smtp_port')
SMTP_FROM=$(bashio::config 'smtp_from')
SMTP_USER=$(bashio::config 'smtp_user')
SMTP_PASS=$(bashio::config 'smtp_pass')
SMTP_TLS=$(bashio::config 'smtp_tls')

# Use HA hostname as fallback if not set
if [ -z "$HOSTNAME" ]; then
    HOSTNAME=$(bashio::info.hostname)
fi

# Directory setup
FILES_PATH="${DATA_PATH}/meshcentral-files"
BACKUP_PATH="${DATA_PATH}/meshcentral-backups"
RECORDINGS_PATH="${DATA_PATH}/meshcentral-recordings"
CONFIG_FILE="${DATA_PATH}/config.json"

bashio::log.info "Starting MeshCentral..."
bashio::log.info "Data path: ${DATA_PATH}"
bashio::log.info "Server mode: ${SERVER_MODE}"
bashio::log.info "Hostname: ${HOSTNAME}"

mkdir -p "${DATA_PATH}" "${FILES_PATH}" "${BACKUP_PATH}" "${RECORDINGS_PATH}"


# Build settings section
SETTINGS="{}"

# Network mode
if [ "$SERVER_MODE" = "wan" ]; then
    SETTINGS=$(echo "$SETTINGS" | jq '. + {WANonly: true}')
elif [ "$SERVER_MODE" = "lan" ]; then
    SETTINGS=$(echo "$SETTINGS" | jq '. + {LANonly: true}')
fi

# Ports (always set)
SETTINGS=$(echo "$SETTINGS" | jq '. + {port: 443, redirPort: 80, mpsPort: 4433}')

# TLS offload
SETTINGS=$(echo "$SETTINGS" | jq --argjson v "$TLS_OFFLOAD" '. + {tlsOffload: $v}')

# Trusted proxy
if bashio::config.has_value 'trusted_proxy'; then
    SETTINGS=$(echo "$SETTINGS" | jq --arg v "$TRUSTED_PROXY" '. + {trustedProxy: $v}')
fi

# Session
SETTINGS=$(echo "$SETTINGS" | jq --argjson v "$SESSION_TIME" '. + {sessionTime: $v}')
if bashio::config.has_value 'session_key'; then
    SETTINGS=$(echo "$SETTINGS" | jq --arg v "$SESSION_KEY" '. + {sessionKey: $v}')
fi

# Features
SETTINGS=$(echo "$SETTINGS" | jq --argjson v "$WEB_RTC" '. + {webRTC: $v}')
SETTINGS=$(echo "$SETTINGS" | jq --argjson v "$COMPRESSION" '. + {compression: $v}')
SETTINGS=$(echo "$SETTINGS" | jq --argjson v "$SELF_UPDATE" '. + {selfUpdate: $v}')

if [ "$MAINTENANCE" = "true" ]; then
    SETTINGS=$(echo "$SETTINGS" | jq '. + {maintenanceMode: true}')
fi

# IP access control
if bashio::config.has_value 'user_allowed_ip'; then
    SETTINGS=$(echo "$SETTINGS" | jq --arg v "$USER_ALLOWED_IP" '. + {userAllowedIP: $v}')
fi
if bashio::config.has_value 'user_blocked_ip'; then
    SETTINGS=$(echo "$SETTINGS" | jq --arg v "$USER_BLOCKED_IP" '. + {userBlockedIP: $v}')
fi
if bashio::config.has_value 'agent_allowed_ip'; then
    SETTINGS=$(echo "$SETTINGS" | jq --arg v "$AGENT_ALLOWED_IP" '. + {agentAllowedIP: $v}')
fi
if bashio::config.has_value 'agent_blocked_ip'; then
    SETTINGS=$(echo "$SETTINGS" | jq --arg v "$AGENT_BLOCKED_IP" '. + {agentBlockedIP: $v}')
fi

# Autobackup
SETTINGS=$(echo "$SETTINGS" | jq --arg bp "$BACKUP_PATH" '. + {autoBackup: {backupPath: $bp}}')


# Build domain section
DOMAIN="{}"
DOMAIN=$(echo "$DOMAIN" | jq --arg v "$DOMAIN_TITLE" '. + {title: $v}')

if bashio::config.has_value 'domain_title2'; then
    DOMAIN=$(echo "$DOMAIN" | jq --arg v "$DOMAIN_TITLE2" '. + {title2: $v}')
fi

DOMAIN=$(echo "$DOMAIN" | jq --argjson v "$NEW_ACCOUNTS" '. + {newAccounts: $v}')

if [ -n "$CERT_URL" ]; then
    DOMAIN=$(echo "$DOMAIN" | jq --arg v "$CERT_URL" '. + {certUrl: $v}')
fi

DOMAIN=$(echo "$DOMAIN" | jq --arg rp "$RECORDINGS_PATH" \
    '. + {sessionRecording: {filepath: $rp}}')

# Build SMTP section (only if enabled)
SMTP_JSON="null"
if [ "$SMTP_ENABLED" = "true" ] && bashio::config.has_value 'smtp_host'; then
    SMTP_JSON=$(jq -n \
        --arg host "$SMTP_HOST" \
        --argjson port "$SMTP_PORT" \
        --arg from "$SMTP_FROM" \
        --arg user "$SMTP_USER" \
        --arg pass "$SMTP_PASS" \
        --argjson tls "$SMTP_TLS" \
        '{host: $host, port: $port, from: $from, user: $user, pass: $pass, tls: $tls}')
    bashio::log.info "SMTP enabled: ${SMTP_HOST}:${SMTP_PORT}"
fi

# Assemble final config.json
if [ "$SMTP_JSON" = "null" ]; then
    CONFIG=$(jq -n \
        --argjson settings "$SETTINGS" \
        --argjson domain "$DOMAIN" \
        '{settings: $settings, domains: {"": $domain}}')
else
    CONFIG=$(jq -n \
        --argjson settings "$SETTINGS" \
        --argjson domain "$DOMAIN" \
        --argjson smtp "$SMTP_JSON" \
        '{settings: $settings, domains: {"": $domain}, smtp: $smtp}')
fi

# Write config.json — always regenerated on start so HA options stay in sync
echo "$CONFIG" > "$CONFIG_FILE"
bashio::log.info "config.json written to ${CONFIG_FILE}"

# Start MeshCentral
bashio::log.info "Starting MeshCentral node process..."
exec node /usr/lib/node_modules/meshcentral \
    --datapath "${DATA_PATH}" \
    --filespath "${FILES_PATH}"
