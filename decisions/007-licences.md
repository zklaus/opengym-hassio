# D-007: MIT for the packaging; upstream's parts keep their own terms and notices

**Status:** accepted (owner, 2026-11-23)
**Date:** 2026-11-23
**Satisfies:** DR-1, FR-1

## Context

The repository was about to become public (implementation-plan.md, M2) with a licence line
that nobody had decided: "AGPL-3.0-or-later, the same as openGym" was in the README from the
first draft. Three different sets of terms meet in what we publish:

- Our own files: Dockerfile, start script, tests, workflows, documents.
- openGym itself, AGPL-3.0, inside the image, unmodified (D-001).
- openGym's exercise pictures and animations, inside the image. Upstream's NOTICE.md: they
  are © Gym visual, licensed to openGym, not covered by the AGPL, "provided strictly for use
  within the openGym application"; "a non-commercial fork of openGym may keep the unmodified
  180 px media together with this notice"; any other use needs its own licence.

Nothing mandates a licence for an add-on repository (HACS does not cover add-ons). Custom:
Home Assistant's own add-ons are Apache-2.0, the Community Add-ons MIT; of the four openGym
add-ons one is MIT, one AGPL-3.0, two state none.

## Decision

1. Our own files are under the MIT licence.
2. The image is published as planned (D-003), relying on upstream's permission for a
   non-commercial fork to keep the unmodified media with the notice. To stay within it: the
   add-on is and remains non-commercial; the media are never modified, extracted or served
   from anywhere but the running app; upstream's `NOTICE.md` and `LICENSE` are in the
   repository (`opengym/upstream/`) and in the image (`/usr/share/doc/opengym/`), and the
   media folder's own notice stays where upstream put it.
3. The README and the add-on's documentation say which part is under which terms and where
   openGym's source for the carried release is.

## Alternatives rejected

- **AGPL-3.0 for the packaging.** Legitimate, and matches upstream, but nothing requires it:
  the packaging starts openGym without modifying or containing it. MIT is the add-on custom
  and does not stop upstream from adopting the files.
- **Ask upstream before publishing.** Would give certainty about the media clause. Not done
  now by the owner's choice; it stays the first step if anyone objects.
- **Publish only the Dockerfile and build on each device.** Avoids redistributing the media
  altogether, at the price of POR-1 and D-003.

## Consequences

- Whether an unmodified, non-commercial repackaging is a "non-commercial fork" in Gym
  visual's and upstream's sense is our reading, not a confirmed one. If upstream or Gym
  visual objects, the published images are withdrawn and the build-on-device alternative
  takes their place.
- The add-on can never be sold or bundled into something commercial without a media licence.
- `opengym/upstream/` has to be refreshed with every openGym release; the tests check that
  the image carries the files, and the release steps in implementation-plan.md say so.
- This is not legal advice; nobody with legal training has reviewed it.
