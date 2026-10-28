# Build stage
ARG CADDY_VERSION
ARG GO_REPLACES="--replace golang.org/x/net=golang.org/x/net@v0.62.0 --replace github.com/go-chi/chi/v5=github.com/go-chi/chi/v5@v5.4.0 --replace github.com/go-jose/go-jose/v4=github.com/go-jose/go-jose/v4@v4.1.6"
FROM caddy:${CADDY_VERSION}-builder AS builder
ARG GO_REPLACES

# Build Caddy with the Cloudflare DNS module.
# Selected Go modules are forced to their newest releases (flags supplied by the
# workflow via GO_REPLACES) so security fixes arrive before Caddy bumps them.
RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/WeidiDeng/caddy-cloudflare-ip \
    --with github.com/fvbommel/caddy-combine-ip-ranges \
    ${GO_REPLACES}

# Final stage
FROM caddy:${CADDY_VERSION}

# Pull in the latest Alpine security patches (e.g. ca-certificates)
RUN apk upgrade --no-cache

# Copy the custom-built Caddy binary
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
