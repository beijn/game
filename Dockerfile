FROM rust:alpine AS builder
ENV TARGET=wasm32-unknown-unknown
RUN apk --no-cache add lld wasm-pack
RUN rustup target add $TARGET
WORKDIR /build
COPY Cargo.toml Cargo.lock ./
RUN mkdir -p src && echo "fn main() {}" > src/lib.rs &&\
    cargo build --release --target $TARGET &&\
    rm -rf ./src/ $(echo target/$TARGET/release{/deps,}/game*) ## see * buildx bug

