#!/usr/bin/with-contenv bashio

# Read config from HA add-on options
HOSTNAME=$(bashio::config 'hostname')
DATA_PATH=$(bashio::config 'data_path')
CERT_URL=$(bashio::config 'cert_url')
ALLOW_SHARING=$(bashio::config 'allow_device_sharing')

# Use HA hostname if not set
if [ -z "$HOSTNAME" ]; then
    HOSTNAME=$(bashio::info.hostname)
fi

# All MeshCentral data folders kept under DATA_PATH
FILES_PATH="${DATA_PATH}/meshcentral-files"
BACKUP_PATH="${DATA_PATH}/meshcentral-backups"
RECORDINGS_PATH="${DATA_PATH}/meshcentral-recordings"

bashio::log.info "Starting MeshCentral..."
bashio::log.info "Hostname: ${HOSTNAME}"
bashio::log.info "Data path: ${DATA_PATH}"
bashio::log.info "Cert URL: ${CERT_URL:-not set}"

# Create directories
mkdir -p "${DATA_PATH}" "${FILES_PATH}" "${BACKUP_PATH}" "${RECORDINGS_PATH}"

CONFIG_FILE="${DATA_PATH}/config.json"

# Generate config.json if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    bashio::log.info "Creating initial MeshCentral config..."
    cat > "$CONFIG_FILE" << EOF
{
  "settings": {
    "port": 443,
    "redirPort": 80,
    "tlsOffload": true,
    "selfUpdate": false,
    "autoBackup": {
      "backupPath": "${BACKUP_PATH}"
    }
  },
  "domains": {
    "": {
      "title": "MeshCentral",
      "title2": "Home Assistant",
      "newAccounts": false,
      "_comment_newAccounts": "Set to true temporarily to create your first admin account",
      "certUrl": "${CERT_URL}",
      "sessionRecording": {
        "filepath": "${RECORDINGS_PATH}"
      }
    }
  }
}
EOF
    bashio::log.info "Config created."
    bashio::log.info "NOTE: Set 'newAccounts: true' temporarily to create your first admin account!"
fi

# Always update certUrl from add-on options on every restart
if command -v jq &> /dev/null; then
    if [ -n "$CERT_URL" ]; then
        bashio::log.info "Updating certUrl to: ${CERT_URL}"
        jq --arg url "$CERT_URL" '.domains[""].certUrl = $url' "$CONFIG_FILE" > /tmp/mc_config_tmp.json \
            && mv /tmp/mc_config_tmp.json "$CONFIG_FILE"
    else
        bashio::log.info "No cert_url set — removing certUrl from config if present"
        jq 'del(.domains[""].certUrl)' "$CONFIG_FILE" > /tmp/mc_config_tmp.json \
            && mv /tmp/mc_config_tmp.json "$CONFIG_FILE"
    fi
else
    bashio::log.warning "jq not found — certUrl will only be set on first run"
fi

# Start MeshCentral with all paths under DATA_PATH
# --filespath keeps meshcentral-files under DATA_PATH instead of parent folder
bashio::log.info "Starting MeshCentral node process..."
exec node /usr/lib/node_modules/meshcentral \
    --datapath "${DATA_PATH}" \
    --filespath "${FILES_PATH}"
