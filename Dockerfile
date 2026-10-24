# Build stage
ARG CADDY_VERSION
FROM caddy:${CADDY_VERSION}-builder AS builder

# Build with the newest Go release and the newest golang.org/x/* modules.
# The official builder image ships the Go version that was current when that
# Caddy release was cut, and Caddy's go.mod pins x/* to the versions it was
# released with. Both end up in the binary, so fixes released since then
# (Go stdlib, x/net, etc.) are missing unless we override them here.
RUN set -eu; \
    GOTOOLCHAIN="$(wget -qO- 'https://go.dev/VERSION?m=text' | head -n1)"; \
    export GOTOOLCHAIN; \
    case "$GOTOOLCHAIN" in go1.*) ;; *) echo "Could not determine latest Go version: '$GOTOOLCHAIN'" >&2; exit 1 ;; esac; \
    go version; \
    REPLACES=""; \
    for mod in golang.org/x/net golang.org/x/crypto golang.org/x/text golang.org/x/sys; do \
        ver="$(go list -m -f '{{.Version}}' "${mod}@latest")"; \
        echo "${mod} -> ${ver}"; \
        REPLACES="${REPLACES} --replace ${mod}=${mod}@${ver}"; \
    done; \
    xcaddy build \
        --with github.com/caddy-dns/cloudflare \
        --with github.com/WeidiDeng/caddy-cloudflare-ip \
        --with github.com/fvbommel/caddy-combine-ip-ranges \
        ${REPLACES}

# Final stage
FROM caddy:${CADDY_VERSION}

# Pull in the latest Alpine security patches (e.g. ca-certificates, brotli-libs)
RUN apk upgrade --no-cache

# Copy the custom-built Caddy binary
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
