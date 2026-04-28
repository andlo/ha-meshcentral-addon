# Development Notes

This document captures technical findings and gotchas discovered while building this add-on.

## Add-on structure

- `config.yaml` — add-on metadata, options schema, port mappings
- `Dockerfile` — builds on HA base image, installs Node.js, npm, jq and MeshCentral
- `run.sh` — startup script using `bashio` for option reading and logging

## MeshCentral config.json

Valid options reference: https://config.meshcentraltools.com

Known invalid/problematic options:
- `cleanErrorLog` — **not a valid option**, do not use
- `mstsc: false` — **disables RDP access**, omit entirely (default is true)

### certUrl
Required for agents outside the local network. Without it, agents cannot verify SSL and will fail to connect. The `run.sh` script updates this on every restart from the add-on `cert_url` option using `jq`.

### Folder paths
MeshCentral creates extra folders next to `--datapath` by default. We redirect them:
- `--filespath` CLI flag → `DATA_PATH/meshcentral-files`
- `settings.autoBackup.backupPath` → `DATA_PATH/meshcentral-backups`
- `domains[""].sessionRecording.filepath` → `DATA_PATH/meshcentral-recordings`
- `meshcentral-web` **cannot** be redirected (MeshCentral limitation)

## GitHub Actions build

- Uses `docker/build-push-action` for multi-arch builds (amd64, aarch64, armhf, armv7, i386)
- Requires **Read and write permissions** under repo Settings → Actions → Workflow permissions
- Images pushed to `ghcr.io/andlo/meshcentral-addon-{arch}`
- Build triggers on push to `meshcentral/**` and on release publish

## Related
- [ha-meshcentral integration](https://github.com/andlo/ha-meshcentral) — HACS integration
- [DEVELOPMENT.md in ha-meshcentral](https://github.com/andlo/ha-meshcentral/blob/main/DEVELOPMENT.md) — WebSocket API notes
