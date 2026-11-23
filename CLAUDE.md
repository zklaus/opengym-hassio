# CLAUDE.md

Working conventions for this repository. They apply to humans and to Claude Code alike.

## What this is

A Home Assistant add-on packaging of openGym (upstream: `~/src/openGym`, a clone of
github.com/DuarteSantos8/openGym). Target device: Home Assistant Green (aarch64, 4 GB RAM,
Home Assistant OS). The add-on code lives under `opengym/`; `tests/run.sh` builds the image
and checks it (needs Docker, about 3 minutes).

## Spec-driven: the rules

1. **Specs are primary, version-controlled artifacts.** Implementation work starts from
   `docs/`, not from a prompt. A change in behaviour edits the spec first, then the code.
2. **Use cases are evidence, requirements are decisions.** `docs/use-cases.md` records what
   people want to do. `docs/requirements.md` decides what must be true of the solution.
   One use case may yield several requirements; one requirement may serve several use cases.
3. **Requirements say what, not how.** No technology, file names or Docker details in
   `requirements.md`. Those belong in `docs/architecture.md`.
4. **Non-goals are written down**, in `docs/vision.md`. A good spec reduces the solution space.
5. **Never guess silently.** An unknown is written as `[NEEDS CLARIFICATION: the question]`
   and listed under Open questions. It is resolved by asking, by a decision record, or by a
   time-boxed spike whose outcome is recorded.
6. **Traceability, lightweight.** Every requirement cites the use cases it serves. Every
   component in `architecture.md` cites the requirements it satisfies. Every task in
   `implementation-plan.md` and every row in `verification.md` cites requirement ids.
   `scripts/check-trace.sh` flags ids that are defined but never referenced.
7. **Refinement, not waterfall.** Lower-level work exposes missing or conflicting
   requirements. Go back and edit the earlier document; do not patch around it.
8. **Decisions get a record.** Anything non-obvious (single container vs two, how the image
   is built, ingress or not) gets a file in `decisions/` from `000-template.md`, including
   the alternatives rejected and why.

## Identifiers

| Prefix | Meaning | Lives in |
|---|---|---|
| `UC-n` | Use case | docs/use-cases.md |
| `FR-n` | Functional requirement: what must it do? | docs/requirements.md |
| `PR-n` | Performance requirement: how fast / how much? | docs/requirements.md |
| `RR-n` | Reliability requirement: how reliably? | docs/requirements.md |
| `POR-n` | Portability requirement: where must it work? | docs/requirements.md |
| `SR-n` | Serviceability requirement: how is it operated and debugged? | docs/requirements.md |
| `DR-n` | Design constraint: what must hold in the design? | docs/requirements.md |
| `SC-n` | Success criterion: measurable, technology-agnostic outcome | docs/requirements.md |
| `D-nnn` | Decision record | decisions/nnn-slug.md |

Ids are never reused or renumbered. A withdrawn requirement stays in the file, struck through,
with one line saying why.

## Acceptance criteria

EARS form, one line each:

    WHEN <event or condition> THE SYSTEM SHALL <observable behaviour>

Scenarios that need setup use Given / When / Then. Criteria must be checkable by a person
with the device in front of them or by a script; "should be fast" is not a criterion.

## Phases and gates

0. Vision and use cases. Gate: the owner has read both and confirmed, cut or added use cases.
1. Requirements (5 to 8 important ones, not a complete list). Gate: every requirement cites
   a use case; open questions listed.
2. Architecture and decisions. Gate: every component traces to a requirement.
3. Implementation plan, then the add-on code under `opengym/`.
4. Verification against `docs/verification.md`, on a real Home Assistant.

One phase per session is a good rhythm. Do not start a phase whose gate is not passed.

## Upstream facts worth remembering

Verified against the openGym v1.4.5 tag on GitHub on 2026-11-22 (the local clone was updated
on 2026-11-23 and sits on main, past v1.4.5; read tagged files with `git show v1.4.5:<path>`).
Upstream moves fast, four releases in six weeks: re-check before relying on these.

- Images: `ghcr.io/duartesantos8/opengym-api` and `opengym-web`, linux/amd64 + linux/arm64,
  tags `X.Y.Z`, `X.Y`, `latest` (releases) and `edge` (main). web and api must be the same
  version. A third, optional image `opengym-mcp` (MCP over HTTPS, port 3100, holds no data)
  sits behind a compose profile.
- nginx (web image) is `nginxinc/nginx-unprivileged:1-alpine`, uid 101, renders
  `/etc/nginx/templates/default.conf.template` with the stock entrypoint. Env:
  `NGINX_PORT`, `BACKEND`, `PORT`, `RESOLVER`, `BASE_PATH`, `MEDIA_UPLOAD_MAX` (112m),
  `CF_CONNECTING_IP`, `MCP_BACKEND`, `MCP_PORT`, `CONTENT_SECURITY_POLICY`. `RESOLVER`
  defaults to Docker DNS; an unreachable resolver makes `/api` hang. The Kubernetes manifest
  uses `BACKEND=127.0.0.1` to avoid DNS entirely.
- The web image forbids framing: `X-Frame-Options "DENY"` is hard-coded in the template and
  the default `CONTENT_SECURITY_POLICY` ends in `frame-ancestors 'none'`. Home Assistant
  ingress shows add-ons in a frame, so ingress needs the template changed.
- API (api image) is `node:26-alpine`, no `USER` line (root), `node server.js`,
  `DATA_DIR=/data`, health at `/api/health` (image health check every 30 s, 20 s start
  period). `RP_ID`/`ORIGIN` default silently to `localhost` / `http://localhost:8080`. The
  API now reads `BASE_PATH` too (it did not in v1.4.1).
- Passkeys need HTTPS (localhost excepted) and an exact hostname match. Fallbacks:
  `PASSWORD_LOGIN=1`, guest mode, and since v1.4.5 an OIDC provider (`OIDC_ISSUER`, ...).
  The native apps (Android, iPhone) and watch apps pair with a one-time code instead.
- Webhooks to Home Assistant and others since v1.4.4: `INTEGRATIONS=webhook`, plus
  `INTEGRATIONS_ALLOW_LAN=1` for targets on the home network. Upstream `docs/INTEGRATIONS.md`.
- The frontend is fully relative (`base: './'`), so a sub-path deployment needs `BASE_PATH`.
- Full env contract: upstream `docs/SELF_HOSTING.md` and `.env.example` (about 400 lines).
- Existing community add-ons and integrations: see `docs/vision.md`, Existing alternatives.

## Home Assistant add-on facts

From developers.home-assistant.io on 2026-10-13.

- `config.yaml` required keys: `name`, `version`, `slug`, `description`, `arch`. With `image`,
  `version` must equal the image tag. Options go in `options`/`schema` and arrive in
  `/data/options.json`. `/data` is the persistent, backed-up volume.
- `ports: {"8099/tcp": 8099}` publishes a port; `ingress: true` with `ingress_port` (default
  8099) serves it through Home Assistant's authenticated proxy, which adds `X-Ingress-Path`
  and connects from `172.30.32.2`.
- `watchdog: http://[HOST]:[PORT:8099]/...` for health; `backup: hot|cold`,
  `backup_exclude`. `init: false` when the image brings its own init (s6-overlay).
- A custom repository is a git repo with `repository.yaml` at the root and one folder per
  add-on (`config.yaml`, `Dockerfile`, `build.yaml`, `DOCS.md`, `README.md`, `CHANGELOG.md`,
  `icon.png` 128x128, `logo.png` ~250x100). Users add the repo URL in the add-on store.
- Home Assistant Green: Rockchip RK3566, 4x Cortex-A55 1.8 GHz, 4 GB LPDDR4X, 32 GB eMMC.

## Housekeeping

- The repository is github.com/zklaus/opengym-hassio (public since 2026-11-23); issue and
  pull request numbers refer to it. The image is ghcr.io/zklaus/opengym-addon.
- Nothing here is pushed or published until the owner says so.
- Do not modify the openGym clone from this repository. Upstream changes are proposed upstream.
