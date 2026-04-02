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
