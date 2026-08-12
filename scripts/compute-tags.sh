#!/usr/bin/env bash
#
# Single source of truth for Plane image tag policy.
#
# Both build-push and merge-manifest call this, so a per-arch build and the
# manifest merge that tags it can never disagree about what the tag should be.
# If this logic is ever duplicated instead, drift silently publishes images
# under tags that the release notes and compose files do not reference.
#
# Reads configuration from the environment (all optional unless noted):
#   IMG_OWNER                 required, e.g. makeplane
#   IMG_NAME                  required, e.g. web-commercial
#   BUILD_RELEASE             "true" selects the release tag regime
#   IS_PRERELEASE             "true" suppresses the :stable tag on a release
#   REL_VERSION               semver, required when BUILD_RELEASE=true
#   TARGET_BRANCH             github.ref_name; "master" selects the :latest regime
#   PRIVATE_REGISTRY_PUSH     "true" duplicates every tag into the private registry
#   PRIVATE_REGISTRY_ADDR     e.g. registry.plane.tools
#   PRIVATE_REGISTRY_PROJECT  e.g. plane
#   FIPS_DOCKER_FILE_PATH     when non-empty, also computes the -fips tag list
#
# Writes DOCKER_TAGS (and DOCKER_TAGS_FIPS when applicable) to both $GITHUB_ENV
# and $GITHUB_OUTPUT, and echoes them for the job log.

set -euo pipefail

: "${IMG_OWNER:?IMG_OWNER is required}"
: "${IMG_NAME:?IMG_NAME is required}"

BUILD_RELEASE="${BUILD_RELEASE:-false}"
IS_PRERELEASE="${IS_PRERELEASE:-false}"
REL_VERSION="${REL_VERSION:-latest}"
TARGET_BRANCH="${TARGET_BRANCH:-}"
PRIVATE_REGISTRY_PUSH="${PRIVATE_REGISTRY_PUSH:-false}"
PRIVATE_REGISTRY_ADDR="${PRIVATE_REGISTRY_ADDR:-registry.plane.tools}"
PRIVATE_REGISTRY_PROJECT="${PRIVATE_REGISTRY_PROJECT:-plane}"
FIPS_DOCKER_FILE_PATH="${FIPS_DOCKER_FILE_PATH:-}"

# Strip anything that is not legal in a docker tag. Branch names routinely
# carry slashes (feat/PAI-123-thing), which would otherwise be read as a
# registry path separator.
FLAT_BRANCH_VERSION=$(printf '%s' "$TARGET_BRANCH" | sed 's/[^a-zA-Z0-9.-]//g')

# Validate up front, not inside compute_tags_for: that function is called from a
# command substitution, where `exit 1` would only kill the subshell.
if [ "$BUILD_RELEASE" == "true" ]; then
  SEMVER_REGEX="^v([0-9]+)\.([0-9]+)\.([0-9]+)(-[a-zA-Z0-9]+(-[a-zA-Z0-9]+)*)?$"
  if [[ ! $REL_VERSION =~ $SEMVER_REGEX ]]; then
    echo "Invalid Release Version Format : ${REL_VERSION}" >&2
    echo "Please provide a valid SemVer version" >&2
    echo "e.g. v1.2.3 or v1.2.3-alpha-1" >&2
    echo "Exiting the build process" >&2
    exit 1
  fi
fi

# Emits the comma-separated tag list for one image name, following whichever
# regime the build type selects. Kept as a function so the regular and -fips
# image names cannot drift apart.
compute_tags_for() {
  local name="$1"
  local tags

  if [ "$BUILD_RELEASE" == "true" ]; then
    tags="${IMG_OWNER}/${name}:${REL_VERSION}"
    if [ "$PRIVATE_REGISTRY_PUSH" == "true" ]; then
      tags="${tags},${PRIVATE_REGISTRY_ADDR}/${PRIVATE_REGISTRY_PROJECT}/${name}:${REL_VERSION}"
    fi

    if [ "$IS_PRERELEASE" != "true" ]; then
      tags="${tags},${IMG_OWNER}/${name}:stable"
      if [ "$PRIVATE_REGISTRY_PUSH" == "true" ]; then
        tags="${tags},${PRIVATE_REGISTRY_ADDR}/${PRIVATE_REGISTRY_PROJECT}/${name}:stable"
      fi
    fi
  elif [ "$TARGET_BRANCH" == "master" ]; then
    tags="${IMG_OWNER}/${name}:latest"
    if [ "$PRIVATE_REGISTRY_PUSH" == "true" ]; then
      tags="${tags},${PRIVATE_REGISTRY_ADDR}/${PRIVATE_REGISTRY_PROJECT}/${name}:latest"
    fi
  else
    tags="${IMG_OWNER}/${name}:${FLAT_BRANCH_VERSION}"
    if [ "$PRIVATE_REGISTRY_PUSH" == "true" ]; then
      tags="${tags},${PRIVATE_REGISTRY_ADDR}/${PRIVATE_REGISTRY_PROJECT}/${name}:${FLAT_BRANCH_VERSION}"
    fi
  fi

  printf '%s' "$tags"
}

emit() {
  local key="$1" value="$2"
  echo "${key}=${value}"
  if [ -n "${GITHUB_ENV:-}" ]; then
    echo "${key}=${value}" >>"$GITHUB_ENV"
  fi
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "${key}=${value}" >>"$GITHUB_OUTPUT"
  fi
}

DOCKER_TAGS=$(compute_tags_for "$IMG_NAME")
emit "DOCKER_TAGS" "$DOCKER_TAGS"

if [ -n "$FIPS_DOCKER_FILE_PATH" ]; then
  DOCKER_TAGS_FIPS=$(compute_tags_for "${IMG_NAME}-fips")
  emit "DOCKER_TAGS_FIPS" "$DOCKER_TAGS_FIPS"
fi
