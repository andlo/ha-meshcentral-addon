ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM

# Install Node.js and jq (required for MeshCentral and config management)
RUN apk add --no-cache nodejs npm jq

# Install MeshCentral
RUN npm install -g meshcentral

# Copy startup script
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]

