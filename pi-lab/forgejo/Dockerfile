# Build stage
FROM golang:1.26-alpine AS builder
WORKDIR /app
# Install git to clone the repo
RUN apk add --no-cache git
RUN git clone https://codeberg.org/goern/forgejo-mcp.git .
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -o forgejo-mcp .

# Final stage
FROM alpine:latest
RUN apk add --no-cache ca-certificates
WORKDIR /root/
COPY --from=builder /app/forgejo-mcp .

# Allow token to be passed via environment variable
ENV FORGEJO_TOKEN=""

# Run in SSE mode by default for Tailnet access
EXPOSE 8080
ENTRYPOINT ["/bin/sh", "-c", "exec ./forgejo-mcp --transport sse --sse-port 8080 --token \"$FORGEJO_TOKEN\""]