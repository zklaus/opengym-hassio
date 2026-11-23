# Implementation plan

<!-- Phase 3 document. Milestones in order, each with tasks that cite requirement ids.
     Draft seeded by Claude on 2026-11-23 from architecture.md and decisions D-001 to D-006.
     The candidate milestones from the planning session of 2026-10-13 are replaced: two of
     them (LAN password sign-in, an ingress spike) were ruled out in Phase 0. -->

**Status:** draft of 2026-11-23, not yet reviewed by the owner. M1 is done: `tests/run.sh`
passed all 34 checks on the workstation (amd64) on 2026-11-23. Later milestones need the
owner and the Green.

## Milestones

Each milestone ends in something that can be shown. "Where" says who can do it: the
workstation milestones need only Docker; the device milestones need the owner at the Green.

| | Milestone | Where | Done when |
|---|---|---|---|
| M1 | The image builds and the start script behaves | workstation | `tests/run.sh` passes: built from upstream's pinned images, identical application files, every start-script case covered |
| M2 | Installed on the Green, first workout | Green, owner | add-on installed from a local add-on folder, reachable at the public address through the NGINX add-on, passkey sign-in, a workout logged; the four on-device questions of architecture.md answered |
| M3 | Everything people use | Green, owner | apps and watches paired, a second profile by invitation, notifications arriving, AI Coach connected with an Anthropic API key |
| M4 | Data survives | Green, owner | reboot, backup and restore, and an update keep everything; memory measured |
| M5 | Published | GitHub, owner's go-ahead | repository public, CI builds and pushes the image, a new upstream release produces a prepared update |
| M6 | Verified | Green, owner | every row of verification.md has a result (Phase 4) |

M2 and M3 build the image on the Green from the local folder. D-003 allows that for
development only; from M5 on the Green pulls the image CI built.

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

### M2 Installed on the Green, first workout

- [ ] `opengym/DOCS.md`, first version: the ten-minute path (FR-1, SC-1)
- [ ] `opengym/translations/en.yaml`: names and help texts for the options (FR-1)
- [ ] Server block for the NGINX add-on: own hostname, certificate, 112 MB bodies, no
      response buffering, 300 s reads; written into DOCS.md once it works (FR-2)
- [ ] Copy the folder to the Green's local add-ons, install, set the public address (FR-1)
- [ ] Answer on the device and record in architecture.md: hostname resolves from the NGINX
      add-on; watchdog reaches an unpublished port; whether the Watchdog switch is manual
      (then reword SR-1); a missing public address is refused by Home Assistant itself
      (FR-2, SR-1, D-002, D-004)
- [ ] Passkey registration and sign-in on the phone, first workout; time it (FR-2, SC-1)
- [ ] From a second device on the home network: no openGym listener reachable (FR-2)

### M3 Everything people use

- [ ] Pair the Android app; connect the Garmin and Samsung watch apps; iPhone if at hand
      (FR-3)
- [ ] First profile is the administrator; switch to invitation only; invite a second
      profile; check isolation and the account list (FR-4)
- [ ] Notifications with the screen off (FR-2)
- [ ] Use openGym on mobile data, away from home (FR-3)
- [ ] Connect the AI Coach with an Anthropic API key; write the DOCS.md section, including
      that the key is in backups (DR-1, FR-1)
- [ ] Upload a photo and a video of a custom exercise through the front end (FR-2, RR-1)

### M4 Data survives

- [ ] Reboot the Green: data, sessions and pairings intact (RR-1, FR-3)
- [ ] Backup, restore on a fresh Home Assistant, point the address there (RR-1, SC-2)
- [ ] Update from one packaging version to the next with data present (RR-1)
- [ ] Memory at rest with five profiles, from Home Assistant's add-on statistics (POR-1)

### M5 Published

- [ ] `repository.yaml`, add-on `README.md`, `CHANGELOG.md`, `icon.png`, `logo.png` (FR-1)
- [ ] Workflow: build for aarch64 and amd64, run `tests/run.sh`, push to ghcr.io; `image:`
      in `config.yaml`; image always pushed before the version bump lands
      (POR-1, DR-1, D-003)
- [ ] Workflow: notice a new upstream release, prepare the bump and changelog entry for the
      owner (SC-3, DR-1)
- [ ] Confirm Home Assistant's ordering of `X.Y.Z-n` versions (D-003)
- [ ] Reinstall on the Green from the published repository (FR-1, POR-1)

### M6 Verified

- [ ] Fill "First checked at" and "Result" for every row of verification.md
      (FR-1, FR-2, FR-3, FR-4, RR-1, POR-1, SR-1, DR-1, SC-1, SC-2, SC-3)
