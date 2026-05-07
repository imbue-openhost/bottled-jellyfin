# Jellyfin packaged for OpenHost.
#
# Layout:
#
#   /opt/openhost-jellyfin/
#     start.sh             — supervises Jellyfin + the auth-proxy sidecar
#     auth_proxy.py        — owner localStorage-shim sidecar (Pattern B)
#     bootstrap_admin.py   — first-boot setup wizard automation +
#                            admin token mint
#
# We base on the official jellyfin/jellyfin image (Debian Bookworm
# slim, includes ffmpeg + .NET runtime) and add only what we need
# for the sidecar:
#
#   * python3        — auth_proxy.py + bootstrap_admin.py runtime
#   * tini           — PID-1 reaper / signal forwarder
#   * gosu           — drop privileges to the jellyfin user (uid 1000)
#   * curl           — readiness probes (some are easier than urllib)

FROM docker.io/jellyfin/jellyfin:latest

USER root

# Override the upstream ENTRYPOINT/CMD; we run our own start.sh.
ENV JELLYFIN_CONFIG_DIR="" \
    JELLYFIN_DATA_DIR="" \
    JELLYFIN_CACHE_DIR="" \
    JELLYFIN_LOG_DIR="" \
    JELLYFIN_WEB_DIR=""

RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends \
        python3 \
        tini \
        gosu \
        curl \
        ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Application files.
COPY start.sh             /opt/openhost-jellyfin/start.sh
COPY auth_proxy.py        /opt/openhost-jellyfin/auth_proxy.py
COPY bootstrap_admin.py   /opt/openhost-jellyfin/bootstrap_admin.py

# OpenHost-routed port (auth-proxy).  Jellyfin's own port (8096)
# remains loopback-only.
EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--", "/opt/openhost-jellyfin/start.sh"]
