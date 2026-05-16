# Stage 1: Build the Web UI and Server
FROM rust:bookworm as builder

# Install Node.js (needed to build the frontend)
RUN apt-get update && apt-get install -y nodejs npm git

# Clone the repo with submodules (essential for the WebUI)
WORKDIR /usr/src
RUN git clone --recursive https://github.com/ActivityWatch/aw-server-rust.git

WORKDIR /usr/src/aw-server-rust

# "make build" automatically:
# 1. Builds the aw-webui (npm install && npm build)
# 2. Builds the rust server (cargo build --release)
# 3. Bundles the UI assets into the binary (so you don't need separate folders)
RUN make build

# Stage 2: The Runtime (Tiny & Clean)
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Copy the static binary we just built
COPY --from=builder /usr/src/aw-server-rust/target/release/aw-server /usr/local/bin/aw-server

# Expose the port
EXPOSE 5600

# Bind to 0.0.0.0 so you can access it via Tailscale/LAN
CMD ["aw-server", "--host", "0.0.0.0"]
