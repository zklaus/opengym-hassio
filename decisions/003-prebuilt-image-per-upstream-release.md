# D-003: A prebuilt image per upstream release, built in CI, not on the Green

**Status:** accepted (owner, 2026-11-23)
**Date:** 2026-11-23
**Satisfies:** POR-1, DR-1, SC-3

## Context

POR-1: nothing compiled or assembled on the Green. SC-3: an add-on update within 7 days of
an openGym release; upstream releases about every 10 days. DR-1: the release carried is named.

## Decision

Each add-on version is an image built by GitHub Actions for aarch64 and amd64 and pushed
to GitHub's container registry (ghcr.io); `config.yaml` names it with `image:`, so the Green
only pulls.

How a release reaches a Green: Home Assistant does not read GitHub Releases. It reads
`config.yaml` on the repository's default branch and pulls the image whose tag equals the
`version` there. So a release is two steps in a fixed order: the workflow pushes the image
for the new version, then the version bump lands on the default branch. A GitHub Release
with the changelog entry is created as well, for people, but nothing depends on it. The Dockerfile pins both upstream images by tag and digest. The add-on version is the
openGym version plus a packaging counter (`1.4.5-1`, `1.4.5-2`, then `1.4.6-1`). A scheduled
job notices a new upstream tag and prepares the version bump for the owner to review and
release; nothing is released without the owner.

## Alternatives rejected

- **Let the Supervisor build the Dockerfile on the device.** No compiling, but it downloads
  both upstream images and assembles them on the Green, which POR-1 excludes, and a failed
  build would surface on the owner's device instead of before release. Still used for
  development, from a local add-on folder.
- **Fully automatic releases.** Meets SC-3 with no effort but ships an unreviewed upstream
  release to a device holding the household's data.
- **Add-on version equal to the openGym version.** Leaves no way to ship a packaging fix.

## Consequences

- Needs a public GitHub repository and a public package on ghcr.io (the Green pulls without
  credentials). Decided by the owner on 2026-11-23: it will live under the owner's own
  GitHub account for now, and the repository stays local until there is something that
  needs CI. Until then the add-on is built from a local add-on folder (see Alternatives:
  development). The repository name is chosen when it is created.
  Revised by the owner later the same day: publishing moves ahead of the on-device work
  (implementation-plan.md, M2), so that the Green pulls the CI-built image from the first
  install. The local add-on folder remains for quick fixes only.
- If the version bump reaches the default branch before the image exists, every Green
  offered the update fails to install it. The workflow must make that order impossible.
- amd64 is built because upstream publishes it and it costs nothing, but only the Green is
  verified (POR-1).
- To be confirmed: Home Assistant orders `1.4.5-2` after `1.4.5-1` and before `1.4.6-1`.
