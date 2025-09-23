# Alternative Dockerfile: Try with older Cloudflare plugin version
# This attempts to use an older version of the plugin that might be compatible with Go 1.22
FROM golang:1.22-alpine AS builder

# Install git (required for xcaddy to fetch dependencies)
RUN apk add --no-cache git

# Install xcaddy
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

# Try building with an older version of the Cloudflare plugin
# Note: If this fails, you'll need to use the main solution with Go 1.23+
RUN /go/bin/xcaddy build v2.7.6 --with github.com/caddy-dns/cloudflare@v0.1.0

# Stage 2: Final image based on official Caddy image
FROM caddy:2.7.6

# Copy the custom-built Caddy binary from the builder stage
COPY --from=builder /go/caddy /usr/bin/caddy

# Expose standard HTTP and HTTPS ports
EXPOSE 80 443

# Use the default Caddy entrypoint
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
