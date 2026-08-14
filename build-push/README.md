# Docker Build & Push GitHub Action

A reusable GitHub Action for building and pushing Docker images to both DockerHub and private registries. This action supports multi-platform builds using Docker Buildx and includes features for release management.

### Features

- 🔄 Multi-platform builds using Docker Buildx
- 🏷️ Smart tagging system for releases and branches
- 🔐 Support for both DockerHub and private registries
- 📦 Build arguments support
- 🚀 Release management with semantic versioning

### Usage

```yaml
- name: Build and Push Docker Image
  uses: makeplane/actions/build-push@main
  with:
    # Required Parameters
    dockerhub-username: ${{ secrets.DOCKERHUB_USERNAME }}
    dockerhub-token: ${{ secrets.DOCKERHUB_TOKEN }}
    docker-image-owner: your-org-name
    docker-image-name: your-image-name
    dockerfile-path: ./Dockerfile

    # Optional Parameters with defaults
    build-context: "."
    buildx-driver: "docker-container"
    buildx-version: "latest"
    buildx-platforms: "linux/amd64"
    buildx-endpoint: "default"
    secrets: ""
    secret-envs: ""
    secret-files: ""
```

Use a published tag in production workflows. Examples in this README use `@main` so they match the unreleased inputs documented on the default branch.

### Inputs

#### Authentication
| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `dockerhub-username` | DockerHub username | Yes | - |
| `dockerhub-token` | DockerHub token | Yes | - |

#### Private Registry Options
| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `private-registry-push` | Enable push to private registry | No | `"false"` |
| `private-registry-username` | Private registry username | No | `""` |
| `private-registry-token` | Private registry token | No | `""` |
| `private-registry-addr` | Private registry address | No | `"registry.plane.tools"` |
| `private-registry-project` | Private registry project | No | `"plane"` |

#### Docker Image Options
| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `docker-image-owner` | Docker image owner/organization | Yes | - |
| `docker-image-name` | Docker image name | Yes | - |
| `build-context` | Build context path | No | `"."` |
| `dockerfile-path` | Path to Dockerfile | Yes | - |
| `build-args` | Build arguments | No | `""` |
| `secrets` | BuildKit inline secrets | No | `""` |
| `secret-envs` | BuildKit environment-backed secrets | No | `""` |
| `secret-files` | BuildKit file-backed secrets | No | `""` |

#### Buildx Options
| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `buildx-driver` | Buildx driver | No | `"docker-container"` |
| `buildx-version` | Buildx version | No | `"latest"` |
| `buildx-platforms` | Build platforms | No | `"linux/amd64"` |
| `buildx-endpoint` | Buildx endpoint | No | `"default"` |

#### Release Options
| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `build-release` | Enable release build | No | `"false"` |
| `build-prerelease` | Mark as pre-release | No | `"false"` |
| `release-version` | Release version | No | `"latest"` |

#### Additional Assets Options
| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `additional-assets` | Additional assets to include | No | `""` |
| `additional-assets-dir` | Additional assets directory path | No | `""` |

#### Split-Architecture Options
| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `push-by-digest` | Push an untagged manifest and return its digest instead of tags | No | `"false"` |
| `cache-scope-suffix` | Appended to the registry cache ref (`<image>:buildcache<suffix>`) | No | `""` |
| `digest-artifact-name` | Artifact name to upload the resulting digest under | No | `""` |

### Outputs

| Output | Description |
|--------|-------------|
| `digest` | Digest of the pushed manifest. Only set when `push-by-digest` is `true`. |
| `tags` | Comma-separated tag list computed for this image. |
| `image-ref` | Bare `<owner>/<name>` repository reference, with no tag. |

### Tag Generation

The action automatically generates Docker image tags based on the following rules:

1. **Release Build** (`build-release: true`):
   - Uses semantic versioning (e.g., v1.2.3)
   - Adds `:stable` tag for non-pre-releases
   - Validates version format using regex

2. **Master Branch**:
   - Tags as `:latest`

3. **Other Branches**:
   - Uses sanitized branch name as tag

### Example Workflows

#### Basic Usage
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Build and Push
        uses: makeplane/actions/build-push@main
        with:
          dockerhub-username: ${{ secrets.DOCKERHUB_USERNAME }}
          dockerhub-token: ${{ secrets.DOCKERHUB_TOKEN }}
          docker-image-owner: myorg
          docker-image-name: myapp
          dockerfile-path: ./Dockerfile
```

#### Multi-Platform Release Build
```yaml
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: Build and Push Release
        uses: makeplane/actions/build-push@main
        with:
          dockerhub-username: ${{ secrets.DOCKERHUB_USERNAME }}
          dockerhub-token: ${{ secrets.DOCKERHUB_TOKEN }}
          docker-image-owner: myorg
          docker-image-name: myapp
          dockerfile-path: ./Dockerfile
          build-release: "true"
          release-version: "v1.0.0"
          buildx-platforms: "linux/amd64,linux/arm64"
```

#### BuildKit Secrets
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Build with BuildKit secrets
        uses: makeplane/actions/build-push@main
        with:
          dockerhub-username: ${{ secrets.DOCKERHUB_USERNAME }}
          dockerhub-token: ${{ secrets.DOCKERHUB_TOKEN }}
          docker-image-owner: myorg
          docker-image-name: myapp
          dockerfile-path: ./Dockerfile
          secret-envs: |
            sentry_auth_token=SENTRY_AUTH_TOKEN
          secret-files: |
            npmrc=.npmrc
        env:
          SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
```

#### Split-Architecture Build (native runners, no emulation)

Build each architecture on a runner native to it, then merge the results into one
multi-arch manifest with [`merge-manifest`](../merge-manifest). This avoids QEMU
emulation and removes any dependency on a remote builder.

```yaml
jobs:
  build:
    strategy:
      fail-fast: false
      matrix:
        include:
          - arch: amd64
            platform: linux/amd64
            runner: blacksmith-4vcpu-ubuntu-2404
          - arch: arm64
            platform: linux/arm64
            runner: blacksmith-4vcpu-ubuntu-2404-arm
    runs-on: ${{ matrix.runner }}
    steps:
      - uses: makeplane/actions/build-push@main
        with:
          dockerhub-username: ${{ secrets.DOCKERHUB_USERNAME }}
          dockerhub-token: ${{ secrets.DOCKERHUB_TOKEN }}
          docker-image-owner: myorg
          docker-image-name: myapp
          dockerfile-path: ./Dockerfile
          buildx-platforms: ${{ matrix.platform }}
          push-by-digest: "true"
          cache-scope-suffix: -${{ matrix.arch }}
          digest-artifact-name: digest-myapp-${{ matrix.arch }}

  merge:
    needs: [build]
    runs-on: blacksmith-2vcpu-ubuntu-2404
    steps:
      - uses: makeplane/actions/merge-manifest@main
        with:
          dockerhub-username: ${{ secrets.DOCKERHUB_USERNAME }}
          dockerhub-token: ${{ secrets.DOCKERHUB_TOKEN }}
          docker-image-owner: myorg
          docker-image-name: myapp
          digest-artifact-pattern: digest-myapp-*
          expected-platforms: linux/amd64,linux/arm64
```

Three things matter here and are easy to get wrong:

- **`cache-scope-suffix` is not optional in practice.** The registry cache manifest
  is not platform-indexed, so two legs writing the same `:buildcache` ref overwrite
  each other and roughly half of all legs go cold every run.
- **`digest-artifact-name` must be unique per image *and* architecture.** Digests
  travel as artifacts rather than job outputs because every matrix leg writes the
  same job-output key — only the last leg to finish would survive, silently
  producing a single-platform manifest.
- **One platform per job.** `push-by-digest` rejects a comma-separated
  `buildx-platforms`, and is incompatible with `fips-docker-file-path` (that input
  builds a second image, which would need a second digest stream).
