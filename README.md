# Plane GitHub Actions

A collection of reusable GitHub Actions for Plane's CI/CD workflows.

## Available Actions

### [Docker Build & Push](./build-push)
Build and push Docker images to DockerHub and private registries with support for:
- Multi-platform builds using Docker Buildx
- Smart tagging system for releases
- Private registry support
- Build arguments and more
- Split-architecture builds that push by digest, for merging with `merge-manifest`

### [Merge Multi-Arch Manifest](./merge-manifest)
Collects the per-architecture digests produced by `build-push` and publishes them
as a single tagged multi-arch manifest. Together the two actions let one image be
built by several jobs in parallel, each on a runner native to its architecture,
with no QEMU emulation and no remote builder.

## Shared tag policy

Both actions derive their tags from [`scripts/compute-tags.sh`](./scripts/compute-tags.sh).
Keep it that way: if the merge re-implemented the release/master/branch regimes
separately, drift would silently publish images under tags that release notes and
compose files do not reference.

## Usage

Each action has its own README with detailed documentation and examples. Click the links above to learn more about specific actions.