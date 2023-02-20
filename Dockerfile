# from https://github.com/rust-lang/cargo/issues/2644#issuecomment-1425891749 (see for expansion)
# see also https://www.lpalmieri.com/posts/fast-rust-docker-builds/ (uses cargo-chef)

FROM rust:1.67.1-alpine3.17 AS builder
ARG TARGET
RUN if [ "$TARGET" = "wasm32-unknown-unknown" ]; then \
      apk add --no-cache lld wasm-pack; \
    fi
RUN rustup target add $TARGET
WORKDIR /build
COPY Cargo.toml Cargo.lock ./
RUN mkdir -p src && echo "fn main() {}" > src/lib.rs   # NOTE: later change lib.rs to main.rs (see Cargo.toml note)
RUN cargo build --release --target ${TARGET}
RUN rm -rf ./src/ $(echo target/${TARGET}/release{/deps,}/game*) ## Theres a bug with * in docker buildx - do I need to remove these or will they be overwritten in any case?
COPY . .  

