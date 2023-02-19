# from https://www.lpalmieri.com/posts/fast-rust-docker-builds/

FROM lukemathwalker/cargo-chef:latest-rust-alpine AS chef
RUN rustup target add wasm32-unknown-unknown
RUN apk add --no-cache lld wasm-pack

FROM chef AS planner
COPY . .  
#TODO maybe copying . . prevents caching? see https://docs.docker.com/build/cache/#keep-layers-small
RUN cargo chef prepare 

FROM chef AS builder-wasm
COPY --from=planner recipe.json recipe.json
RUN cargo chef cook --release --target wasm32-unknown-unknown

FROM builder-wasm AS gh-pages
COPY . .
RUN wasm-pack build --target web --out-dir gh-pages/target --release
RUN apk add tree
RUN tree -L 3 || echo "could not run tree"

## see https://reece.tech/posts/extracting-files-multi-stage-docker/
FROM alpine:latest AS export-gh-pages   
# TODO DEBUG NOTE: this used to be scratch
COPY --from=gh-pages /gh-pages . 
RUN apk add tree
RUN tree -L 3 || echo "could not run tree"


## 
# We do not need the Rust toolchain to run the binary!
#FROM debian:bullseye-slim AS runtime
#WORKDIR app
#COPY --from=builder /app/target/release/app /usr/local/bin
#ENTRYPOINT ["/usr/local/bin/app"]

