#!/usr/bin/env sh
# The add-on image in the registry, by the name and version in opengym/config.yaml.
# Used by the workflows; `check` and `unpublished` are also safe to run by hand.
#
#   scripts/addon-image.sh ref            print <image>:<version>
#   scripts/addon-image.sh check          succeed if that version is published
#   scripts/addon-image.sh unpublished    succeed if that version is NOT published
#   scripts/addon-image.sh push-arch A    build for the current machine as arch A, push <ref>-A
#   scripts/addon-image.sh manifest       join <ref>-amd64 and <ref>-aarch64 into <ref>
set -eu
cd "$(dirname "$0")/.."

value() { sed -nE "s/^$1: *\"?([^\"#]+)\"? *$/\1/p" opengym/config.yaml; }
IMAGE=$(value image)
VERSION=$(value version)
[ -n "$IMAGE" ] && [ -n "$VERSION" ] || { echo "Cannot read image and version from opengym/config.yaml" >&2; exit 2; }
REF="$IMAGE:$VERSION"

published() { docker manifest inspect "$REF" >/dev/null 2>&1; }

case "${1:-}" in
  ref)
    echo "$REF" ;;
  check)
    if published; then echo "$REF is published."; else
      echo "$REF is not published. Run the 'Publish image' workflow on the branch with this version before it reaches main." >&2
      exit 1
    fi ;;
  unpublished)
    if published; then
      echo "$REF is already published. Raise the version in opengym/config.yaml instead of replacing it." >&2
      exit 1
    else echo "$REF is not published yet."; fi ;;
  push-arch)
    arch=${2:?architecture name, amd64 or aarch64}
    docker build --build-arg BUILD_VERSION="$VERSION" --build-arg BUILD_ARCH="$arch" -t "$REF-$arch" opengym
    docker push "$REF-$arch" ;;
  manifest)
    docker buildx imagetools create -t "$REF" "$REF-amd64" "$REF-aarch64" ;;
  *)
    sed -n '2,10p' "$0" >&2; exit 2 ;;
esac
