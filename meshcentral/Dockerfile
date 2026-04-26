ARG BUILD_FROM
FROM $BUILD_FROM

# Install Node.js (required for MeshCentral)
RUN apk add --no-cache nodejs npm

# Install MeshCentral
RUN npm install -g meshcentral

# Copy startup script
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
