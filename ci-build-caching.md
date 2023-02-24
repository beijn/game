# Options for Build Caching

Software works nicely locally to cache stuff to save ressources, but on CI additional care must be taken for this to work.
Things to cache to save ressources in (ci) builds:

- software prerequisites (rust toolchain, wasm-pack)
- build dependencies 
- incremental compiltion
  - less _usefull_ in CI, because overhead and pushed changes usually bigger
  - incremental release builds might be less optimized → see in `Cargo.toml` wether `[profile.release] incremental = true` 


###<a name="section-1"></a> Caching Installed Software in GitHub Actions
see https://stackoverflow.com/questions/59269850/caching-apt-packages-in-github-actions-workflow
- con: easy breakage (caching dependencies), complicated 
- better use docker 

## sccache
- has limitations https://github.com/mozilla/sccache#known-caveats

## No Docker, GitHub workflow cache
- need to specify everything to cache (not that bad)

### Bazel
- pro: optimal caching; future
- + independence from GitHub Actions
- caching includes required build software! 
  - otherwise see [above|#section-1]


## GitHub Workflow Rust Action 
- con: low level tie to githubs CI
- pro: smart(est?) caching
- easy in complex polyglot scenarios?


## Costum Docker Containers for Build Caching



#### cache invalidation 
- (structure RUNs and COPYs and so to minimize cache miss (often changing goes down))
- major problem: loose every later layer whenever something down changes even a bit

### Layer Caching
see https://docs.docker.com/build/ci/github-actions/examples/#cache
#### container registry

```yaml
## .github/workflows/builder.yml
...
jobs:
  build-and-push-image:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Log in to the container registry
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ github.token }} 

      - name: Build and push Docker image
        uses: docker/build-push-action@v4
        with:
          pull: true
          push: true
          tags: ghcr.io/${{ github.repository }}:builder-${{ env.target }}
          build-args: TARGET=${{ env.target }}
```

#### Actions Cache
TODO 

### Result Extraction
#### docker run + cp
- remember that this is very overkill compared to specifying the container argument to the job directly (see below)
```yaml
## .github/workflows/gh-pages.yml
jobs:
  build: 
    steps:
    - name: Build and extract wasm packed for gh-pages from container
      run: |
        echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin
        docker run --name builder -w /build $builder wasm-pack build --target web --out-dir gh-pages --release --no-typescript
        docker cp builder:/build/gh-pages .
```
#### inside container
- favorable against above since simpler
```yaml
jobs: 
  build:
    container:
      image: ${{ env.builder }}
      credentials:
         username: ${{ github.actor }}
         password: ${{ github.token }}

    steps: 
    - name: Build and push wasm packed for gh-pages
      run: |
        wasm-pack build --target web --out-dir gh-pages --release --no-typescript
```

#### FROM scratch AS export
see https://github.com/rust-lang/cargo/issues/2644#issuecomment-1425891749 (for expansion)
```dockerfile
## Dockerfile
FROM xx as builder
# ...
COPY src/ ./src/  

FROM builder AS build-gh-pages
RUN wasm-pack build --out-dir gh-pages --no-typescript --target web --release
WORKDIR gh-pages
RUN rm .gitignore README.md package.json

FROM scratch AS export-gh-pages
COPY --from build-gh-pages . .
```
```yaml
## .github/workflows/gh-pages.yml
docker build -
```

### Still Problems

- Needless recompilation of all dependencies due to cache miss, when anything in `Cargo.toml` or `Cargo.lock` change
  - need external volume for caching or not use docker

- Same with incremental builds!


