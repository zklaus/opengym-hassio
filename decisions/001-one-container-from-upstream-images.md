# D-001: One container, assembled from upstream's two released images

**Status:** accepted (owner, 2026-11-23)
**Date:** 2026-11-23
**Satisfies:** DR-1, FR-1, POR-1

## Context

openGym ships as two images that must be the same version: `opengym-web` (nginx serving the
frontend and forwarding `/api`) and `opengym-api` (Node). A Home Assistant add-on is exactly
one container. DR-1 demands one tagged release, unmodified; FR-1 demands one installation
with one required setting.

## Decision

The add-on image starts from upstream's `opengym-web` image and copies in, from upstream's
`opengym-api` image of the same version, the application directory (`/app`) and the Node
binary it runs with. Our own additions are two operating-system packages (`libatomic`, which
that Node binary needs, and `su-exec`) and one start script. The web side keeps upstream's
own entrypoint, which renders upstream's own nginx template; the API is started with
upstream's own command. No upstream file is edited.

Spike on 2026-11-23 (amd64, v1.4.5, throwaway image): builds without compiling anything,
`/api/health` answers through nginx within 2 seconds of start, about 67 MiB of memory at rest
with no profiles. Both upstream images sit on the same Alpine release (3.24.4), which is what
makes copying the Node binary work.

## Alternatives rejected

- **Two add-ons, each a thin wrapper around one upstream image.** Closest to upstream's
  layout, but two installations, two versions to keep equal and two logs: fails FR-1 and SR-1.
- **Start from the API image and install the distribution's nginx** (what
  misterblokhead/ha-opengym does). Replaces upstream's nginx build and entrypoint, so our
  script would have to render the template itself and track every variable upstream adds
  (three were added between v1.4.1 and v1.4.5).
- **Build openGym from source in our image.** Reproduces upstream's build and its media
  download; fails DR-1 in spirit and makes every release slower to follow.
- **A Home Assistant base image with s6-overlay.** Brings the conventional add-on tooling
  but a different operating-system base than either upstream image; see D-004.

## Consequences

- Each release needs a check that `/app` and the web root in our image are identical to
  upstream's (verification.md, DR-1), and that the two upstream images still share an Alpine
  release. If they diverge, the Node binary may stop loading; the build must fail then, not
  the add-on on the device.
- The image is about 460 MB, almost all of it upstream's exercise media and Node.
- What "unmodified" covers is openGym's files. The container around them is ours.
