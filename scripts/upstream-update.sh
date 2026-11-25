#!/usr/bin/env sh
# Following openGym releases (decisions/003, docs/architecture.md C7).
# Used by the "Upstream release" workflow; safe to run by hand. Needs docker and curl.
#
#   scripts/upstream-update.sh carried    print the openGym version the Dockerfile carries
#   scripts/upstream-update.sh latest     print upstream's latest release, once both of its
#                                         images are in the registry; nothing before that
#   scripts/upstream-update.sh apply V    change the working tree to carry openGym V:
#                                         tag and digests in the Dockerfile, upstream's
#                                         licence and notices, an "Unreleased" changelog entry
#
# `apply` does not touch the add-on version: the "Release" workflow writes that.
set -eu
cd "$(dirname "$0")/.."

UPSTREAM=DuarteSantos8/openGym
REGISTRY=ghcr.io/duartesantos8
DOCKERFILE=opengym/Dockerfile
CHANGELOG=opengym/CHANGELOG.md

fail() { echo "$*" >&2; exit 1; }
carried() { sed -nE 's|^FROM .*/opengym-web:([0-9.]+)@.*|\1|p' "$DOCKERFILE"; }
# The digest of the multi-architecture image, which is what the Dockerfile pins.
digest() { docker buildx imagetools inspect "$1" 2>/dev/null | awk '/^Digest:/ {print $2; exit}'; }

case "${1:-}" in
  carried)
    carried ;;
  latest)
    # The address of the latest release redirects to its tag; no API token needed.
    tag=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$UPSTREAM/releases/latest" | sed -nE 's|.*/releases/tag/v([0-9]+\.[0-9]+\.[0-9]+)$|\1|p')
    [ -n "$tag" ] || fail "Could not read upstream's latest release."
    # A release is only usable once both images exist; they can lag behind the tag.
    [ -n "$(digest "$REGISTRY/opengym-api:$tag")" ] && [ -n "$(digest "$REGISTRY/opengym-web:$tag")" ] || exit 0
    echo "$tag" ;;
  apply)
    new=${2:?openGym version, like 1.4.6}
    echo "$new" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || fail "\"$new\" is not an openGym version."
    old=$(carried)
    for name in api web; do
      d=$(digest "$REGISTRY/opengym-$name:$new")
      [ -n "$d" ] || fail "$REGISTRY/opengym-$name:$new is not in the registry."
      # What the registry answers goes into the Dockerfile; accept nothing but a digest.
      echo "$d" | grep -Eq '^sha256:[0-9a-f]{64}$' || fail "Unexpected digest for opengym-$name:$new: $d"
      sed -i -E "s|^(FROM $REGISTRY/opengym-$name):[^ ]+|\1:$new@$d|" "$DOCKERFILE"
    done
    [ "$(carried)" = "$new" ] || fail "Could not write openGym $new into $DOCKERFILE."
    for file in LICENSE NOTICE.md; do
      curl -fsSL -o "opengym/upstream/$file" "https://raw.githubusercontent.com/$UPSTREAM/v$new/$file" \
        || fail "Could not fetch $file of openGym $new."
    done
    sed -i "s/(currently v[0-9.]*)/(currently v$new)/" opengym/upstream/README.md
    if [ "$old" != "$new" ]; then
      line="- Carries openGym $new, unmodified (was $old). What changed in openGym: https://github.com/$UPSTREAM/releases/tag/v$new"
      if grep -q '^## Unreleased$' "$CHANGELOG"; then
        sed -i "/^## Unreleased\$/{n;a\\
$line
}" "$CHANGELOG"
      else
        first=$(grep -n '^## ' "$CHANGELOG" | head -1 | cut -d: -f1)
        sed -i "${first}i\\
## Unreleased\\
\\
$line\\
" "$CHANGELOG"
      fi
    fi
    echo "Working tree now carries openGym $new (was $old)." ;;
  *)
    sed -n '2,13p' "$0" >&2; exit 2 ;;
esac
