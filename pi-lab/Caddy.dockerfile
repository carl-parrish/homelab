# Use the specific Go version required by the plugin
FROM golang:1.23-alpine AS builder

# Install git, which is a dependency for xcaddy
RUN apk add --no-cache git

# Install the xcaddy tool
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

# Build Caddy v2.7.6 with the latest compatible cloudflare plugin
RUN /go/bin/xcaddy build v2.7.6 --with github.com/caddy-dns/cloudflare

# Final stage: start from the official Caddy 2.7.6 image
FROM caddy:2.7.6

# Copy our custom-built Caddy binary in
COPY --from=builder /go/bin/caddy /usr/bin/caddy