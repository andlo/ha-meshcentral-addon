ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM

# Install Node.js and jq
RUN apk add --no-cache nodejs npm jq

# Install MeshCentral to a fixed known path
RUN npm install -g meshcentral --prefix /opt/meshcentral

# Copy startup script
COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD ["/run.sh"]
