# Build stage
# Defaults let a plain `docker build .` work; CI passes exact values.
ARG CADDY_VERSION=2
# Module overrides come from the workflow, which looks up the newest releases.
# Left empty here so local builds never pin stale (older) versions.
ARG GO_REPLACES=""
ARG GO_TOOLCHAIN=local
FROM caddy:${CADDY_VERSION}-builder AS builder
ARG GO_REPLACES
ARG GO_TOOLCHAIN

# Build Caddy with the Cloudflare DNS module.
# Selected Go modules are forced to their newest releases (flags supplied by the
# workflow via GO_REPLACES) so security fixes arrive before Caddy bumps them.
# GO_TOOLCHAIN (e.g. go1.27.4) makes Go fetch a newer toolchain than the builder
# image ships, so stdlib fixes land too. "local" = use the image's Go.
RUN GOTOOLCHAIN=${GO_TOOLCHAIN} xcaddy build \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/WeidiDeng/caddy-cloudflare-ip \
    --with github.com/fvbommel/caddy-combine-ip-ranges \
    --with github.com/mholt/caddy-ratelimit \
    ${GO_REPLACES}

# Final stage
FROM caddy:${CADDY_VERSION}

# Pull in the latest Alpine security patches (e.g. ca-certificates)
RUN apk upgrade --no-cache

# Copy the custom-built Caddy binary
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
