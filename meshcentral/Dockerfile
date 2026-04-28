ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM

# Install Node.js and jq (required for MeshCentral and config management)
RUN apk add --no-cache nodejs npm jq

# Install MeshCentral
RUN npm install -g meshcentral

# Set up s6 service
RUN mkdir -p /etc/services.d/meshcentral
COPY run.sh /etc/services.d/meshcentral/run
RUN chmod a+x /etc/services.d/meshcentral/run
