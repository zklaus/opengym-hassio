# Vision

<!-- Phase 0 document. Owner reviews and edits freely; this is a draft seeded by Claude on
     2026-10-13 from the openGym repo, the Home Assistant add-on docs, and the owner's stated
     interest. Ids and conventions: see CLAUDE.md. -->

**Status:** approved by the owner on 2026-11-23 (Phase 0 gate passed)

## The problem

openGym is a self-hosted gym and body-weight tracker that keeps all data in a folder the
user owns. It ships as two Docker containers started with `docker compose`. Many households
already run one always-on box: a Home Assistant Green (or other Home Assistant OS device).
That box cannot run `docker compose`; it runs only Supervisor-managed add-ons. So a person
who already has a Green and wants openGym has to buy and maintain a second machine, or go
without.

Community add-ons for openGym exist (see Existing alternatives), but they are built around
the Home Assistant sidebar, where openGym's native and watch apps cannot connect, and most
of them modify openGym to fit there.

## Existing alternatives

Found on GitHub on 2026-11-22; none is endorsed or mentioned by upstream. All four are built
around Home Assistant ingress (the sidebar). Re-check before relying on this.

| Add-on | openGym carried | How it differs from what we want |
|---|---|---|
| mzspicoli/opengym-homeassistant | not checked | Own prebuilt image; ingress plus a direct port; untouched since 2026-09-05. |
| Amantux/opengym-ha | 1.4.2 | Patches the openGym API to sign Home Assistant users in; bundles an integration. |
| ChadJPetersen/home-assistant-opengym | 1.4.4 | Re-assembles the app on a Home Assistant base image; adds MQTT sensors. |
| misterblokhead/ha-opengym | 1.4.3 | Closest in spirit: upstream images pinned by digest, two response headers changed so the app can be framed. Ingress only, refuses to start without an HTTPS address, no LAN port. |

Two Home Assistant integrations also exist (JImmyB0nes/OpenGym-HomeAssistant, and the one
bundled by Amantux), which supports keeping an integration out of scope here.

What this add-on does differently: upstream's images byte-for-byte (principle 1), served at
its own HTTPS address rather than inside the sidebar, so that the native and watch apps
(UC-7) and upstream's own sign-in methods work as upstream documents them. This project is also a practice run for spec-driven development, so an
existing alternative does not end it.

## What we want

An add-on that a Home Assistant user adds from a repository URL, installs with one click,
configures with a handful of options, and then uses openGym from their phone, with their
data covered by ordinary Home Assistant backups and upgrades tracking openGym releases.

## Who it is for

- **The owner-operator**: one person who runs Home Assistant at home and wants openGym for
  themselves and possibly their household. This is the primary stakeholder and, for now,
  the only one whose needs are written down from first-hand evidence.
- **openGym upstream** (secondary): the project might one day want to point at or adopt the
  add-on. We keep the packaging honest so that is possible.
- **Home Assistant add-on store conventions** (constraint, not a person): what a repository
  must look like to be installable and well-behaved.

## Principles (the short constitution)

1. **Unmodified upstream.** The add-on packages openGym's own released images or build
   output. No fork, no patches. Anything openGym needs changed is proposed upstream.
2. **Nothing built on the device.** Installing on a Green pulls or builds a small image;
   it never compiles the frontend or fetches exercise media at start-up.
3. **Data is the user's and survives everything.** One persistent directory, included in
   Home Assistant backups, untouched by add-on upgrades.
4. **Secure by default.** openGym is reached over HTTPS only. Sign-in is by passkey;
   password sign-in only when the user turns it on.
5. **Keep the add-on as small as the app.** openGym is dependency-light on purpose; the
   packaging should be too. No sidecars, no databases, no extra services.

## Non-goals

These are out of scope. Each one could be a separate project later.

- **Not a Home Assistant integration.** No entities, sensors, automations or dashboard cards
  derived from workouts. The add-on only hosts the app. (Since v1.4.4 openGym itself can send
  signed webhooks to Home Assistant; exposing that switch would not make the add-on an
  integration, but see "No webhooks in v1" below.)
- **Not a fork of openGym.** No feature work in the app itself.
- **Not an HTTPS or reverse-proxy tutorial.** The add-on documents which hostname and origin
  settings each common Home Assistant HTTPS setup implies, and points to upstream's guides
  for the rest.
- **No AI coach by default.** Upstream's optional coach image target is a separate concern
  and may never be packaged.
- **No authentication of our own.** No Remote-User header, no signing Home Assistant users
  in automatically, nothing beyond what upstream ships. Upstream's own sign-in methods
  (passkeys, password, guest, and since v1.4.5 an OIDC provider) are upstream features.
  Passkeys are the primary method here; OIDC is not planned (decided 2026-11-23).
- **No multi-instance or multi-tenant support.** One add-on instance, one openGym instance.
- **No Home Assistant ingress.** openGym does not appear in the sidebar behind Home
  Assistant's login. It would need upstream's web server modified, adds a second login, and
  the native and watch apps cannot use it. Decided 2026-11-23; existing add-ons cover it.
- **No plain-HTTP access.** Not on the LAN either. Decided 2026-11-23: HTTPS is already set
  up on the owner's Home Assistant, and the apps matter more than LAN convenience.
- **No webhooks in v1.** Upstream's webhook integration stays off; exposing it as an option
  is a candidate for later.

## Success looks like

- A Home Assistant Green owner goes from "add repository" to logging a workout on their
  phone in under ten minutes, following only the add-on's own documentation.
- A Home Assistant backup taken on one Green and restored on another brings openGym back
  with every profile, workout and setting intact.
- An openGym release becomes an add-on update within days, with no manual data migration.

## Open questions

None open. Resolved on 2026-11-23:

- Sign-in: passkeys are the primary, documented and verified method. No OIDC is planned.
  (GitHub sign-in is not OIDC; Google is, but sends no groups, so openGym could not limit
  who gets a profile without further, unverified measures. Not pursued.)
- HTTPS route: the owner's existing nginx reverse proxy serves openGym at its own hostname
  and forwards to the add-on. The add-on does not terminate TLS itself. UC-10 is met the
  same way Home Assistant is reached from outside today.
- The owner's setup, as the reference environment: the nginx proxy runs as an add-on on the
  same Green; Home Assistant is already reachable from outside through it; DNS is at
  Cloudflare, DNS only (not proxied).
- Ingress: non-goal (see Non-goals; UC-6 struck).
- Clients in use: the Android app, possibly the iPhone app, and Garmin and Samsung watch
  apps, besides the browser (UC-7).
- Webhooks: off for v1, possible option later.
- Plain HTTP on the LAN: out.
