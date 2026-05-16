FROM rust:1.79 as builder
WORKDIR /src
ARG AW_SERVER_RUST_REF=master
RUN apt-get update && apt-get install -y clang pkg-config libssl-dev make git \
 && git clone --recurse-submodules https://github.com/ActivityWatch/aw-server-rust.git \
 && cd aw-server-rust \
 && git checkout $AW_SERVER_RUST_REF \
 && cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /src/aw-server-rust/target/release/aw-server-rust /usr/local/bin/aw-server-rust
EXPOSE 5600
CMD ["aw-server-rust", "server"]
