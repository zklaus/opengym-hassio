#!/usr/bin/env sh
# The add-on image in the registry, and the files a release changes.
# The image name comes from opengym/config.yaml. The version is the one in config.yaml, or
# the one in ADDON_VERSION when a release is being made (decisions/003).
# Used by the workflows; `ref`, `check`, `unpublished` and `can-release` change nothing.
#
#   scripts/addon-image.sh ref            print <image>:<version>
#   scripts/addon-image.sh check          succeed if that version is published
#   scripts/addon-image.sh unpublished    succeed if that version is NOT published
#   scripts/addon-image.sh can-release    succeed if ADDON_VERSION can be released from here
#   scripts/addon-image.sh push-arch A    build for the current machine as arch A, push <ref>-A
#   scripts/addon-image.sh manifest       join <ref>-amd64 and <ref>-aarch64 into <ref>
#   scripts/addon-image.sh release-files  write the version into config.yaml and CHANGELOG.md
#   scripts/addon-image.sh notes          print the changelog entry of the version
set -eu
cd "$(dirname "$0")/.."

value() { sed -nE "s/^$1: *\"?([^\"#]+)\"? *$/\1/p" opengym/config.yaml; }
IMAGE=$(value image)
VERSION=${ADDON_VERSION:-$(value version)}
CHANGELOG=opengym/CHANGELOG.md
[ -n "$IMAGE" ] && [ -n "$VERSION" ] || { echo "Cannot read image and version from opengym/config.yaml" >&2; exit 2; }
REF="$IMAGE:$VERSION"

published() { docker manifest inspect "$REF" >/dev/null 2>&1; }
# The changelog entry under the heading "## $1", without the heading.
entry() { awk -v h="## $1" '$0 == h {on=1; next} /^## / {on=0} on' "$CHANGELOG"; }
fail() { echo "$*" >&2; exit 1; }

case "${1:-}" in
  ref)
    echo "$REF" ;;
  check)
    if published; then echo "$REF is published."; else
      echo "$REF is not published. The version in opengym/config.yaml is written by the 'Release' workflow, after it has pushed the image; do not change it by hand." >&2
      exit 1
    fi ;;
  unpublished)
    if published; then
      echo "$REF is already published. Choose the next version instead of replacing it." >&2
      exit 1
    else echo "$REF is not published yet."; fi ;;
  can-release)
    echo "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+-[1-9][0-9]*$' \
      || fail "\"$VERSION\" is not an add-on version. Expected the openGym version and a counter, like 1.4.5-2."
    carried=$(sed -nE 's|^FROM .*/opengym-web:([0-9.]+)@.*|\1|p' opengym/Dockerfile)
    [ "${VERSION%-*}" = "$carried" ] \
      || fail "Version $VERSION names openGym ${VERSION%-*}, but the Dockerfile carries openGym $carried."
    [ "$VERSION" != "$(value version)" ] || fail "$VERSION is the version already in opengym/config.yaml."
    [ -n "$(entry Unreleased | tr -d '[:space:]')" ] \
      || fail "$CHANGELOG has nothing under \"## Unreleased\". Say there what this version changes."
    echo "$VERSION can be released." ;;
  release-files)
    sed -i -E "s/^version: .*/version: \"$VERSION\"/" opengym/config.yaml
    sed -i -E "s/^## Unreleased\$/## $VERSION/" "$CHANGELOG"
    [ "$(value version)" = "$VERSION" ] && [ -n "$(entry "$VERSION" | tr -d '[:space:]')" ] \
      || fail "Could not write $VERSION into opengym/config.yaml and $CHANGELOG." ;;
  notes)
    entry "$VERSION" ;;
  push-arch)
    arch=${2:?architecture name, amd64 or aarch64}
    docker build --build-arg BUILD_VERSION="$VERSION" --build-arg BUILD_ARCH="$arch" -t "$REF-$arch" opengym
    docker push "$REF-$arch" ;;
  manifest)
    docker buildx imagetools create -t "$REF" "$REF-amd64" "$REF-aarch64" ;;
  *)
    sed -n '2,15p' "$0" >&2; exit 2 ;;
esac
