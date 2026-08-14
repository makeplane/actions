# Merge Multi-Arch Manifest GitHub Action

Collects the per-architecture digests produced by
[`build-push`](../build-push) in `push-by-digest` mode and publishes them as a
single tagged multi-arch manifest.

Pair it with a matrix of `build-push` jobs — one per architecture, each on a
runner native to that architecture — so multi-arch images are built without QEMU
emulation and without a remote builder.

### How it works

Each per-architecture job pushes an **untagged** manifest and gets back a content
digest. No tag exists in the registry until this action runs. It then:

1. Downloads every digest artifact matching `digest-artifact-pattern`.
2. Computes the tag list using the **same** shared script `build-push` uses, so
   the merge cannot disagree with the build about tag policy.
3. Runs `docker buildx imagetools create` with one `-t` per tag over every
   `<owner>/<name>@sha256:…` source, producing one OCI index tagged N times.
4. Verifies the merged manifest actually advertises `expected-platforms`.

That last step matters: a merge that produced a single-platform index still exits
`0`, so the platform set is asserted rather than assumed.

### Usage

```yaml
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

Use a published tag in production workflows. Examples in this README use `@main`
so they match the unreleased inputs documented on the default branch.

### Inputs

#### Authentication
| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `dockerhub-username` | DockerHub username | Yes | - |
| `dockerhub-token` | DockerHub token | Yes | - |

#### Image Options
| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `docker-image-owner` | Docker image owner/organization | Yes | - |
| `docker-image-name` | Docker image name | Yes | - |
| `digest-artifact-pattern` | Artifact name pattern holding the digests, e.g. `digest-myapp-*` | Yes | - |
| `expected-platforms` | Platforms the merged manifest must advertise. Empty skips the check. | No | `""` |

#### Release Options

These must match what `build-push` was given, so the merge applies exactly the
tags the build would have applied.

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `build-release` | Enable release build | No | `"false"` |
| `build-prerelease` | Mark as pre-release | No | `"false"` |
| `release-version` | Release version | No | `"latest"` |

#### Private Registry Options
| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `private-registry-push` | **Not supported yet** — fails fast if `"true"` | No | `"false"` |
| `private-registry-addr` | Private registry address | No | `"registry.plane.tools"` |
| `private-registry-project` | Private registry project | No | `"plane"` |

A digest is only addressable as `<repo>@sha256:…`, within the repository it was
pushed to. Merging into a private registry therefore requires the
per-architecture builds to have pushed by digest into *that* registry too, which
`build-push` does not do yet. Rather than fail deep inside `imagetools create`
with `MANIFEST_UNKNOWN`, this action refuses up front.

### Outputs

| Output | Description |
|--------|-------------|
| `tags` | Comma-separated tag list applied to the merged manifest. |

### Notes

- The merge job is a fresh runner with no credentials carried over from the build
  jobs, so it logs in again. `imagetools` talks to the registry directly and does
  not need a buildx builder instance.
- Between the build jobs and this one, the per-architecture manifests sit in the
  registry untagged. Docker Hub keeps them indefinitely, but a registry whose
  garbage collection deletes untagged artifacts could remove them out from under a
  delayed or retried merge — keep the merge in the same workflow run.
