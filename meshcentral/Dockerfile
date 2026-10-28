ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM

# Install Node.js and jq
RUN apk add --no-cache nodejs npm jq

# MeshCentral version baked into this image. Pinned on purpose: the image is
# built once per add-on release and reused on every install/reinstall, so an
# unpinned install would silently freeze whatever npm "latest" was at build time.
# Bump this (and the add-on version) to ship a new MeshCentral release.
ARG MESHCENTRAL_VERSION=1.3.1

# Install MeshCentral locally — avoids global install path issues
RUN mkdir -p /opt/meshcentral && \
    cd /opt/meshcentral && \
    npm install meshcentral@${MESHCENTRAL_VERSION} && \
    node -e "console.log('MeshCentral', require('/opt/meshcentral/node_modules/meshcentral/package.json').version)"

# Copy startup script
COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD ["/run.sh"]
