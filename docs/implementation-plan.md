# Implementation plan

<!-- Phase 3 document. Milestones in order, each with tasks that cite requirement ids.
     Draft seeded by Claude on 2026-11-23 from architecture.md and decisions D-001 to D-006.
     The candidate milestones from the planning session of 2026-10-13 are replaced: two of
     them (LAN password sign-in, an ingress spike) were ruled out in Phase 0. -->

**Status:** approved by the owner on 2026-11-23, after reordering (publishing ahead of the
on-device work) and splitting the on-device work into smaller milestones. M1 is done:
`tests/run.sh` passed all 34 checks on the workstation (amd64) on 2026-11-23.

## Milestones

Each milestone ends in something that can be shown. "Where" says who can do it.

| | Milestone | Where | Done when |
|---|---|---|---|
| M1 | The image builds and the start script behaves | workstation | done: `tests/run.sh` passes |
| M2 | Published | GitHub, owner's go-ahead for every push | done 2026-11-23, except the optional required check: the repository is public; CI tests and pushes the image for aarch64 and amd64 to ghcr.io; the repository can be added to an add-on store |
| M3 | Installed on the Green, first workout | Green, owner | done 2026-11-23 (SC-1 not timed): add-on installed from the published repository, reachable at the public address through the NGINX add-on, passkey sign-in, a workout logged; the on-device questions of architecture.md answered |
| M4 | The Android app and notifications | Green, owner | done 2026-11-24 (reminder on a planned day not yet seen; contact option check skipped): the app is paired, syncs at home and on mobile data, and stays paired across an add-on restart; a rest-timer notification arrives with the screen off |
| M5 | The AI Coach | Green, owner | done 2026-11-24: connected with an Anthropic API key, a plan proposed and applied |
| M6 | Household and watches | Green, owner | a second profile created by invitation and isolated from the first; the Garmin and Samsung watch apps sync |
| M7 | Data survives | Green, owner | reboot, backup and restore, and a store update keep everything; memory measured |
| M8 | Upstream releases are followed | GitHub | a new upstream release produces a prepared update for the owner to release |
| M9 | Verified | Green, owner | every row of verification.md has a result (Phase 4) |

Why publishing comes second: the Green then pulls the image CI built from the first install
on, so POR-1 ("nothing assembled on the device") and the store update in M5 are tested as
they will be used, and problems with the registry or the build show up before the on-device
work. The price: the repository is public before the add-on has run on a device, so its
README says "not ready" until M7 is done, and nothing is announced. For quick fixes during
M3 to M6 a local add-on folder on the Green remains available (D-003).

## Tasks

### M1 The image builds and the start script behaves

- [x] `opengym/Dockerfile`: upstream's web image as base, `/app` and the Node binary from
      upstream's API image, both pinned by tag and digest; static settings; health check on
      `/api/health` (DR-1, POR-1, D-001)
- [x] `opengym/settings.mjs`: reads the options, rejects an unusable public address with
      one plain sentence, prints upstream's settings (FR-1, FR-2, FR-4)
- [x] `opengym/run.sh`: data folder check, address-change warning, version line, starts both
      programs as upstream does, stops everything when one stops or on a stop signal
      (FR-1, SR-1, DR-1, D-004)
- [x] `opengym/config.yaml`: options and schema, no ports, no ingress, cold backup, watchdog
      (FR-1, FR-2, RR-1, SR-1, D-002, D-005)
- [x] `tests/run.sh`, needing only Docker (SR-1, DR-1, FR-1, FR-2):
      - application files identical to upstream's two images
      - missing, plain-HTTP, IP-address and with-a-path public addresses are each refused
        with a message
      - a valid address: health answers within 60 s, the version line is logged, only the
        start script, the API and nginx run
      - guest mode off, password sign-in off unless the option is on
      - a request from another address is logged with both addresses
      - the API dying stops the container, non-zero, within 10 s
      - a stop signal stops the container cleanly within 5 s
      - an unwritable data folder is reported and the add-on stops
      - data survives a restart; a changed public address is warned about (RR-1)

### M2 Published

Prepared locally first; creating the repository and every push are the owner's, or done on
the owner's explicit go-ahead for that one push (nothing is pushed otherwise). Names used:
repository `zklaus/opengym-hassio`, image `ghcr.io/zklaus/opengym-addon`.

- [x] `repository.yaml` at the root; the root `README.md` says what this is and that it is
      not ready; `LICENSE` (MIT) and upstream's licence and notices in `opengym/upstream/`
      and in the image (FR-1, DR-1, D-007)
- [x] `opengym/README.md`, `opengym/CHANGELOG.md` naming the openGym release,
      `opengym/icon.png`, `opengym/logo.png` (sources in `assets/`) (FR-1, DR-1)
- [x] `opengym/DOCS.md`, first version: the ten-minute path, with the NGINX server block
      marked as untested until M3 (FR-1, SC-1)
- [x] `opengym/translations/en.yaml`: names and help texts for the options (FR-1)
- [x] `.github/workflows/ci.yml`, on pull requests and pushes to main:
      `scripts/check-trace.sh` and `tests/run.sh` (DR-1, SR-1)
- [x] `.github/workflows/publish.yml`, started by hand on the branch carrying a new version:
      build for aarch64 (native runner) and amd64, run `tests/run.sh` on both, push to
      ghcr.io under the add-on version; `image:` in `config.yaml` (POR-1, DR-1, D-003)
- [x] The order "image first, version bump second": the publish workflow refuses to replace
      a published version, and CI fails when the version in `config.yaml` has no published
      image (`scripts/addon-image.sh`) (POR-1, D-003)
- [x] Owner: create the repository under the owner's account; first push (FR-1, D-003).
      Done 2026-11-23.
- [x] Owner: run "Publish image" once; make the image on ghcr.io public if it starts
      private (POR-1, D-003). Done 2026-11-23: both architectures built, tested and pushed
      as `1.4.5-1`; the image can be read without credentials.
- [x] Re-run CI on main: its first run failed as designed, because it ran before the image
      existed (POR-1, D-003). Green on 2026-11-23.
- [ ] Owner, once CI is green: make "Image for this version is published" a required check
      on main, so a version without an image cannot be merged (POR-1, D-003)
- [x] From the workstation: pull the published image by tag and compare it with upstream's,
      as `tests/run.sh` does (DR-1). Done 2026-11-23 for amd64: identical. aarch64 cannot be
      run on the workstation; its evidence is the publish run, where the same comparison
      passed on a native arm64 runner immediately before the push.

### M3 Installed on the Green, first workout

- [x] Add the repository in the add-on store, install, set the public address (FR-1, POR-1).
      Done 2026-11-23; a missing public address is refused by Home Assistant with a pop-up.
- [x] Server block for the NGINX add-on: own hostname, certificate, 112 MB bodies, no
      response buffering, 300 s reads; corrected in DOCS.md once it works (FR-2). Works as
      written, 2026-11-23, with a wildcard certificate; uploads and streaming are tried in
      M4 and M5.
- [x] Answer on the device and record in architecture.md: hostname resolves from the NGINX
      add-on; watchdog reaches an unpublished port; whether the Watchdog switch is manual
      (then reword SR-1); a missing public address is refused by Home Assistant itself
      (FR-2, SR-1, D-002, D-004). Done 2026-11-23; the switch is manual, SR-1 reworded.
- [x] Passkey registration and sign-in on the phone, first workout; time it (FR-2, SC-1).
      Done 2026-11-23; not timed, so SC-1 is still to be measured on a fresh run.
- [x] The first profile is the administrator; switch sign-up to invitation only straight
      away, since the address is public from this point on (FR-4). Done 2026-11-23; still
      signed in after the restart.
- [x] From a second device on the home network: no openGym listener reachable (FR-2).
      Done 2026-11-23: ports 3000 and 8080 closed.

### M4 The Android app and notifications

- [x] Pair the Android app with a one-time code from the signed-in browser (FR-3).
      Done 2026-11-24, with the APK from upstream's release page; a workout logged in the
      app shows in the browser.
- [x] Log a workout in the app at home, and one on mobile data away from home; both appear
      in the browser (FR-3). Done 2026-11-24.
- [x] Restart the add-on: the app syncs without re-pairing (FR-3, RR-1). Done 2026-11-24.
- [x] Upload a photo and a video of a custom exercise through the front end (FR-2, RR-1).
      Done 2026-11-24; the app shrinks videos, so nothing near 112 MB was sent.
- [x] Notifications from the server: in the phone's browser, enable them; a rest-timer
      notification arrives with the screen off, and a training-day reminder on a planned
      day. (The Android app raises its own rest-timer and reminder notifications on the
      phone; the server's are what the add-on has to get right.) (FR-2). Rest timer done
      2026-11-24; the training-day reminder is still to be seen on a planned day.
- [x] The same in the Android app: rest-timer alert with the screen off (FR-2, FR-3).
      Done 2026-11-24.
- [ ] ~~With `notification_contact` set, restart and check notifications still arrive~~
      (FR-2). Skipped by the owner on 2026-11-24: the option stays empty on the Green.
      `tests/run.sh` checks that the option reaches openGym; delivery with it set is
      untested.

### M5 The AI Coach

- [x] Create an Anthropic API key with a spend limit; connect it on the administrator's AI
      Coach card, choose a model, "Test the Coach" (DR-1). Done 2026-11-24.
- [x] Go through the intake, get a plan proposed and apply it; check that answers stream
      through the front end without stalling (FR-2). Done 2026-11-24: plan proposed and
      applied without a stall; whether the text arrived piece by piece was not noted.
- [x] Write the DOCS.md section: the steps, what leaves the device, that the key is shared
      by all profiles and is in backups (FR-1, DR-1)

### M6 Household and watches

- [ ] Issue an invitation; a second person creates their profile with it; without an
      invitation it is refused (FR-4)
- [ ] Neither profile sees the other's data; the administrator sees both accounts and can
      disable the second (FR-4)
- [ ] Connect the Garmin and the Samsung watch apps; a workout logged on a watch appears in
      the browser. iPhone app if at hand (FR-3)

### M7 Data survives

- [ ] Reboot the Green: data, sessions and pairings intact (RR-1, FR-3)
- [ ] Backup, restore on a fresh Home Assistant, point the address there (RR-1, SC-2)
- [ ] Store update from one published version to the next with data present; this also
      confirms how Home Assistant orders `X.Y.Z-n` versions (RR-1, D-003)
- [ ] Memory at rest with five profiles, from Home Assistant's add-on statistics (POR-1)
- [ ] Remove "not ready" from the README (FR-1)

### M8 Upstream releases are followed

- [ ] Workflow: notice a new upstream release, prepare the digest and version bump, the
      refreshed `opengym/upstream/` files and the changelog entry for the owner to review
      (SC-3, DR-1, D-007)
- [ ] Until then, follow upstream by hand; openGym 1.4.6 is the first practice run
      (SC-3, RR-1)

### M9 Verified

- [ ] Fill "First checked at" and "Result" for every row of verification.md
      (FR-1, FR-2, FR-3, FR-4, RR-1, POR-1, SR-1, DR-1, SC-1, SC-2, SC-3)
