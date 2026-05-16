# Stage 1: Build aw-server-rust
FROM rust:1.88 as builder-server

RUN apt-get update && apt-get install -y clang pkg-config libssl-dev make git \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
ARG AW_SERVER_RUST_REF
RUN git clone --recurse-submodules https://github.com/ActivityWatch/aw-server-rust.git . \
 && git checkout $AW_SERVER_RUST_REF \
 && cargo build --release


# Stage 2: Build aw-webui
FROM node:22-slim as builder-webui

WORKDIR /webui
RUN git clone --recurse-submodules https://github.com/ActivityWatch/aw-webui.git . \
 && npm install \
 && npm run build


# Stage 3: Runtime image
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates sqlite3 \
 && rm -rf /var/lib/apt/lists/*

# Copy server binary
COPY --from=builder-server /src/target/release/aw-server-rust /usr/local/bin/aw-server-rust

# Copy web UI into place
COPY --from=builder-webui /webui/dist /usr/local/share/aw-webui

EXPOSE 5600
VOLUME ["/root/.activitywatch"]

CMD ["aw-server-rust", "server", "--webui-path", "/usr/local/share/aw-webui"]
