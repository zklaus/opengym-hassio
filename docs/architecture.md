# Architecture (system specification)

<!-- Phase 2 document. This is where technology lives: components, interfaces (add-on
     options, ports, files, env vars), the image, the process model. Every component cites
     the requirements it satisfies. Non-obvious choices get a decision record in decisions/
     and are only summarised here. Ends with the traceability table. Draft seeded by Claude
     on 2026-11-23. -->

**Status:** approved by the owner on 2026-11-23 (Phase 2 gate passed).
Facts about upstream are from the v1.4.5 tag; a `release-1.4.6` branch was moving on
2026-11-23, so re-check when implementation starts.

## Overview

One add-on, one container. The container is upstream's web image with upstream's API copied
in beside it (D-001), plus one start script of ours. It listens on the internal add-on
network only (D-002). The owner's existing HTTPS front end gives it a public address.

```
phone, watch (via phone), browser
        |  https://gym.example.org
        v
+--------------------- Home Assistant device ----------------------+
|  HTTPS front end (owner's NGINX add-on; not part of this add-on) |
|        |  http://<add-on hostname>:8080, internal network only   |
|        v                                                         |
|  +---------------- openGym add-on container ------------------+  |
|  |  start script: options -> settings, checks, supervision    |  |
|  |  nginx (upstream) :8080 --/api--> API (upstream, Node) :3000|  |
|  |        static frontend + exercise media        |           |  |
|  +------------------------------------------------|-----------+  |
|                                          /data/opengym           |
|                              (Home Assistant backs up /data)     |
+------------------------------------------------------------------+
```

## Components

### C1 Add-on manifest (`opengym/config.yaml`)

Satisfies: FR-1, FR-2, RR-1, SR-1, POR-1

Tells Home Assistant what the add-on is: name, version, the prebuilt image to pull (D-003),
architectures (`aarch64`, `amd64`), the options and their schema, `backup: cold` (D-005),
`watchdog` pointing at `/api/health` through nginx, and deliberately no `ports` and no
`ingress` (D-002). `public_address` has no default, so Home Assistant itself refuses to
start the add-on until it is filled in.

### C2 Image (`opengym/Dockerfile`)

Satisfies: DR-1, POR-1

Upstream's `opengym-web:X` as the base, `/app` and the Node binary copied from
`opengym-api:X`, both pinned by digest, two packages and the start script added (D-001),
and upstream's licence and notices under `/usr/share/doc/opengym/` (D-007).
Built in CI for both architectures, never on the Green (D-003).

### C3 Start script (`opengym/run.sh`)

Satisfies: FR-1, FR-2, FR-4, SR-1, DR-1

The only logic we own (D-004). In order:

1. Reads `/data/options.json`. Stops with one plain sentence if `public_address` is not an
   `https://` address with a hostname (not an IP address) and no path.
2. Creates `/data/opengym` if needed and stops with a plain sentence if it is not writable.
3. Compares the public address with the one used last time (kept in `/data/public-address`)
   and warns in the log if it changed: passkeys made for the old address stop working.
4. Logs one line with the add-on version, the openGym version and the public address.
5. Turns the options into upstream's documented settings (table below) and starts the API
   and nginx, each exactly as its upstream image starts it.
6. Watches both. If either exits, stops the other and exits non-zero. On a stop signal,
   stops both and exits zero.

### C4 openGym API (upstream, unmodified)

Satisfies: FR-2, FR-3, FR-4, RR-1, SR-1

Accounts, passkeys, pairing codes, sessions, invitations, the administrator screens, sync and
push notifications. Everything FR-3 asks of the native and watch apps is upstream behaviour
that needs only a stable public address and persistent data. The AI Coach is here too: off
until the administrator connects a provider in the app (an API key, or a model server on the
home network), and then one outbound request per job from this process. The variants that
run an AI program in the container are absent from the image and report themselves as
unavailable. It logs refused requests with
the address used and the address expected, and reports at `/api/health` whether it is up and
its data folder writable.

### C5 openGym web server (upstream nginx, unmodified)

Satisfies: FR-1, FR-2, FR-3

Serves the frontend and the exercise media from the image and forwards `/api` to C4 on
`127.0.0.1`. Configured only through upstream's environment variables, rendered by
upstream's own entrypoint. Its framing ban stays, which is fine: there is no ingress.

### C6 Persistent data (`/data/opengym`)

Satisfies: RR-1, FR-3, FR-2

Upstream's whole data folder: database, session secret, push identity, uploads. It is a
subfolder so that Home Assistant's own `options.json` does not sit inside openGym's data, and
so that an existing openGym data folder could later be dropped in as it is. Sessions and
pairings survive restart, update and restore because the secret that signs them lives here.

### C7 Repository and release pipeline

Satisfies: FR-1, DR-1, POR-1, SC-3

`repository.yaml` at the root makes the repository addable in the add-on store. A GitHub
Actions workflow ("Release"), started by hand on the default branch with the new version,
builds the image for both architectures and pushes it to GitHub's container registry
(ghcr.io); it fails if `/app` or the web root differ from upstream's or if the API does not
answer in the built image. Only after the push does the same workflow write the version into
`config.yaml` and the changelog on the default branch and create a GitHub Release. A scheduled
workflow ("Upstream release") looks once a day for a new openGym release whose images are in
the registry and opens a pull request with the new tag and digests, upstream's licence and
notices, the `CHANGELOG.md` entry naming the openGym release, and the result of the image
tests; the owner reviews, merges and releases (D-003). Home Assistant
learns of an update from `config.yaml` on the default branch, not from GitHub Releases, so
the image is always pushed before the version lands there; the GitHub Release is for
readers. Changes waiting for a release sit under "Unreleased" in the changelog.

### C8 Documentation (`opengym/DOCS.md`)

Satisfies: FR-1, FR-2, FR-4, SR-1, SC-1

The ten-minute path (SC-1): the server block and certificate for the NGINX add-on, the one
option, first profile, then switching to invitation only (FR-4), turning on the Watchdog
(D-004), pairing the apps. A separate section covers connecting the AI Coach. Also what each option does and what the common log messages mean.

### Outside the add-on: the HTTPS front end

Not a component of ours, but the architecture depends on it (FR-2). Reference environment:
the official "NGINX Home Assistant SSL proxy" add-on on the same device, with its `customize`
option on and an extra server block for the openGym hostname in a file under `/share`,
forwarding to `http://<add-on hostname>:8080`, with a certificate that covers that hostname.
The block must also allow request bodies up to upstream's upload limit (112 MB; nginx's
default of 1 MB would break photo and video uploads of custom exercises), and for the AI
Coach must not buffer responses and must allow reads of at least 300 seconds, as upstream's
own nginx does.
[NEEDS CLARIFICATION: the exact server block, and how the owner's certificate comes to cover
the openGym hostname, are written and tried at the first on-device milestone.]

## Interfaces

### Add-on options

| Option | Type | Default | Becomes | Requirement |
|---|---|---|---|---|
| `public_address` | URL, required | none | `ORIGIN` (as given, no trailing slash), `RP_ID` (its hostname) | FR-1, FR-2 |
| `invite_only` | yes/no | no | `INVITE_ONLY` | FR-4 |
| `password_login` | yes/no | no | `PASSWORD_LOGIN` | FR-2 |
| `notification_contact` | e-mail, optional | empty | `VAPID_SUBJECT=mailto:...`; empty leaves upstream's default, the public address | FR-2 |

`invite_only` starts at "no" because upstream cannot issue an invitation before the first
profile exists (FR-4). Switching it automatically once a profile exists was considered and
dropped: it would mean reading upstream's database file, whose format is not an interface.

Settings the add-on always sets, all documented by upstream (DR-1):

| Setting | Value | Why |
|---|---|---|
| `DATA_DIR` | `/data/opengym` | C6 |
| `FIRST_USER_ADMIN` | `1` | FR-4: first profile is the administrator |
| `ALLOW_GUEST` | `0` | FR-2: no guest mode |
| `TRUST_PROXY` | `1` | as upstream's compose file; see D-006 |
| `PORT` | `3000` | API, as upstream |
| `NGINX_PORT` | `8080` | unprivileged port, as upstream's Kubernetes example |
| `BACKEND`, `RESOLVER` | `127.0.0.1` | API is in the same container; no DNS lookup (upstream's Kubernetes example does the same) |

Everything else stays at upstream's default.

Upstream features and what v1 does with them (v1.4.5):

| Feature | Upstream default | In v1 |
|---|---|---|
| AI Coach by API key or home-network model server | off until the administrator connects it | available, in the app |
| AI Coach with a runtime in the container | needs a different build | not packaged (vision.md, Non-goals) |
| Personal API tokens, calendar feed, WebDAV backup of an export, imports from other apps, module switches | on, per profile | available, in the app |
| Webhooks, identity-provider sign-in | off | off, decided 2026-11-23 |
| Community library, trainers and gyms, activity log, Strava, default language, administrator's view of members' data | off or unset | not exposed; each would be one more option |
| MCP server for AI assistants (also the way to use a Claude or ChatGPT plan, as a connector) | separate image, built on Node 22 where the API runs Node 26 | not packaged; candidate for later (use-cases.md, Candidates). Would be a third program in the container, off by default, with the Node question settled by a spike |

Two consequences of the "available" rows, for the documentation (C8): a calendar feed address
or an API token gives access to one profile without a passkey, by upstream's design; and a
provider key for the AI Coach is stored in the data folder beside the secret that decrypts
it, so it is in every Home Assistant backup.

### Ports and network

| Port | Listener | Reachable from |
|---|---|---|
| 8080 | nginx (C5) | the internal add-on network: the HTTPS front end, Home Assistant's watchdog |
| 3000 | API (C4) | the same network (upstream binds every interface; accepted in D-002) |

Nothing is published to the home network. Outbound, the API contacts push services when
notifications are used, and the AI provider or home-network model server when the Coach is.

### Files and persistent data

| Path | Owner | Contents | In backups |
|---|---|---|---|
| `/data/options.json` | Home Assistant | the options above | yes |
| `/data/opengym/` | upstream API | all openGym data (C6) | yes |
| `/data/public-address` | start script | the public address last started with | yes |
| `/app`, `/usr/share/nginx/html`, `/etc/nginx/templates` | upstream, in the image | application, frontend, media, nginx template | no (replaced by updates) |

### Log

Both programs and the start script write to the container's output, which is the add-on's
Log tab (SR-1). No log files.

## Decisions (summary, details in decisions/)

| Id | Decision | Status |
|---|---|---|
| D-001 | One container: upstream's web image plus upstream's API copied in, nothing edited | accepted |
| D-002 | Internal add-on network only; no published port, no ingress | accepted |
| D-003 | Prebuilt image per upstream release, built by GitHub Actions and pulled from ghcr.io; version `X.Y.Z-n`; owner releases | accepted |
| D-004 | One start script supervises both programs; either stopping stops the container | accepted |
| D-005 | Cold backup of the whole data folder | accepted |
| D-006 | The API sees all visitors at the front end's address in v1 | accepted |
| D-007 | MIT for the packaging; openGym stays AGPL and its exercise media stay under Gym visual's terms, carried unmodified with upstream's notices | accepted |

## Spikes

- 2026-11-23, workstation (amd64), v1.4.5: the D-001 image builds and runs; health answers
  within 2 seconds; about 67 MiB at rest with no profiles. Two findings went into D-004
  (shell supervision, nginx output). This replaces the "proposed 300 MB" in POR-1 with an
  evidence-based 200 MB ceiling; the figure on the Green itself is still to be measured,
  as the POR-1 row in verification.md.

## Open questions

For the owner: none open. Answered on 2026-11-23 (D-003): the repository will live under the
owner's own GitHub account for now and stays local until something needs CI; nothing is
pushed or published before the owner says so.

Confirmed on the owner's Green on 2026-11-23 (M3):

- The add-on installs from the published repository; the Green pulls the image (POR-1).
- Starting without `public_address` is refused by Home Assistant itself, with a pop-up that
  names the option and offers a button to the configuration (FR-1).
- With the option set, the add-on starts and logs its version line (SR-1).
- The add-on's hostname resolves from the NGINX add-on, and the server block of DOCS.md
  works with a wildcard certificate: `/api/health` answers at the public address
  (D-002, FR-2).
- On 2026-11-24 (M4): a photo and a video of a custom exercise upload through the block,
  and a rest-timer notification sent by the server arrives in the phone's browser with
  the screen off (FR-2). The app shrinks videos before uploading, so an upload near the
  112 MB limit has not been tried.
- On 2026-11-24 (M5): the AI Coach with an Anthropic API key works on the unchanged
  image: the container reaches the provider, and a plan is proposed and applied through
  the block (DR-1, FR-2). Deleting data in the browser also empties the paired app (FR-3).

- No openGym port is reachable from the home network: ports 3000 and 8080 on the Green
  show as closed from another machine (FR-2, D-002).
- The Watchdog switch is off after installation and has to be turned on by the owner
  (D-004; SR-1 reworded). With it on, the Supervisor log shows no complaint about reaching
  the unpublished port; an actual restart of a hung add-on has not been provoked on the
  device.

Still to be confirmed on the device:

1. D-003: that Home Assistant offers `1.4.6-1` after `1.4.5-n` (with openGym 1.4.6). That
   `1.4.5-2` follows `1.4.5-1` was confirmed on 2026-11-25, with the first store update.

## Traceability

| Requirement | Satisfied by |
|---|---|
| FR-1 | C1 (required option, image), C3 (validation, start), C5, C7 (store repository), C8 |
| FR-2 | C1 and D-002 (no port, no ingress), C3 (address, guest and password settings), C4, C5, C6 |
| FR-3 | C4 (pairing, sync), C5, C6 (pairings persist), D-002 (one stable address) |
| FR-4 | C3 (`FIRST_USER_ADMIN`, `invite_only`), C4, C8 (two-step first run) |
| RR-1 | C6, C1 and D-005 (cold backup), C4 (reads existing data after an update) |
| POR-1 | C2 and D-001 (nothing compiled), C7 and D-003 (nothing assembled on the device), C1 |
| SR-1 | C3 (messages, version line, supervision; D-004), C4 (address mismatch line, health), C1 (watchdog), C8 |
| DR-1 | C2 and D-001, C3 (documented settings only; D-006), C7 (identity check, changelog) |
| SC-1 | C8, C1 (one required option) |
| SC-2 | C6, D-005 |
| SC-3 | C7, D-003 |
