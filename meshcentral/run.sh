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

bashio::log.info "Starting MeshCentral..."
bashio::log.info "Hostname: ${HOSTNAME}"
bashio::log.info "Data path: ${DATA_PATH}"

# Create data directory
mkdir -p "${DATA_PATH}"

# Generate config.json if it doesn't exist
CONFIG_FILE="${DATA_PATH}/config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    bashio::log.info "Creating initial MeshCentral config..."
    cat > "$CONFIG_FILE" << EOF
{
  "settings": {
    "port": 443,
    "redirPort": 80,
    "tlsOffload": true,
    "selfUpdate": false,
    "cleanErrorLog": 5
  },
  "domains": {
    "": {
      "title": "MeshCentral",
      "title2": "Home Assistant",
      "newAccounts": false,
      "_comment_newAccounts": "Set to true temporarily to create your first admin account",
      "certUrl": "${CERT_URL}",
      "mstsc": false
    }
  }
}
EOF
    bashio::log.info "Config created. NOTE: Set 'newAccounts: true' temporarily to create your first admin account!"
fi

# Start MeshCentral
exec node /usr/lib/node_modules/meshcentral --datapath "${DATA_PATH}"
