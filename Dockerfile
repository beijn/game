# from https://www.lpalmieri.com/posts/fast-rust-docker-builds/

FROM lukemathwalker/cargo-chef:latest-rust-alpine AS chef
RUN rustup target add wasm32-unknown-unknown
RUN apk add --no-cache lld wasm-pack

FROM chef AS planner
COPY . .
RUN cargo chef prepare 

FROM chef AS builder-wasm
COPY --from=planner recipe.json recipe.json
RUN cargo chef cook --release --target wasm32-unknown-unknown
COPY . .
#↓RUN cargo build --release --bin app
RUN wasm-pack build --target web --out-dir gh-pages/target --release


## 
# We do not need the Rust toolchain to run the binary!
#FROM debian:bullseye-slim AS runtime
#WORKDIR app
#COPY --from=builder /app/target/release/app /usr/local/bin
#ENTRYPOINT ["/usr/local/bin/app"]

