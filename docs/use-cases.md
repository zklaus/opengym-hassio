# Use cases

<!-- Phase 0 document. Use cases are EVIDENCE of what people want to do, not requirements.
     Each one has an actor, a trigger, the flow, and what "done" looks like. The owner should
     strike the ones that do not apply and add the ones that are missing. Draft seeded by
     Claude on 2026-10-13. Ids are never renumbered. -->

**Status:** reviewed with the owner on 2026-11-23. Confirmed: UC-1 to UC-5, UC-7 to UC-10
(UC-1 and UC-2 follow from the decision that passkeys are the primary sign-in). Struck: UC-6.
Approved by the owner on 2026-11-23 (Phase 0 gate passed).

Actors:

- **Owner**: runs Home Assistant at home, administers the add-on, trains with openGym.
- **Household member**: uses openGym on their own phone, does not touch Home Assistant.
- **Upstream**: the openGym project publishing releases.

## UC-1 Install and log a first workout

**Actor:** Owner. **Trigger:** has a Home Assistant Green, wants openGym without a second machine.

1. Adds the add-on repository URL in the Home Assistant add-on store.
2. Installs the openGym add-on, sets the few required options, starts it.
3. Opens openGym on a phone at its HTTPS address.
4. Creates a profile, picks a starter plan, logs a workout.

**Done when:** the workout is saved, and reopening openGym on the phone later shows it.
Revised 2026-11-23: plain HTTP on the LAN is out (vision.md, Non-goals); HTTPS is a
precondition. The owner signs in with a passkey (UC-2).

## UC-2 Sign in with a passkey from the phone

**Actor:** Owner. **Trigger:** wants the default openGym sign-in, not passwords.

1. The owner's reverse proxy serves openGym over HTTPS at its own stable hostname
   (revised 2026-11-23; the hostname is openGym's own, not Home Assistant's).
2. The add-on is configured with the matching hostname and origin.
3. On the phone, the owner registers a passkey and signs in with it.

**Done when:** passkey registration and sign-in succeed on the phone; a wrong hostname
setting produces an understandable error rather than a silent failure.

## UC-3 Back up and restore with Home Assistant

**Actor:** Owner. **Trigger:** a Green dies, or is replaced.

1. Owner takes an ordinary Home Assistant backup (full or add-on only).
2. Restores it on a fresh Home Assistant installation.

**Done when:** every profile, workout, body-weight entry, custom exercise with its media,
setting and passkey is back; nobody has to sign in again unless they chose to.

## UC-4 Update when openGym releases

**Actor:** Owner; Upstream publishes. **Trigger:** openGym tags a new version.

1. The add-on store shows an update for the add-on.
2. Owner clicks update.

**Done when:** the new openGym version runs with the existing data, no manual migration,
and the add-on's changelog says which openGym version it carries.

## UC-5 Household members with their own profiles

**Actor:** Household member. **Trigger:** wants to use the same instance.

1. Owner enables sign-ups (or creates an invite, if invite-only).
2. Member opens the URL on their phone, creates their own profile, trains.

**Done when:** members never see each other's data; the owner can see who has an account
and remove one.

## ~~UC-6 Open openGym from the Home Assistant sidebar (ingress)~~

Struck 2026-11-23: ingress is a non-goal (vision.md). The text is kept for the record.

**Actor:** Owner. **Trigger:** wants openGym inside the Home Assistant UI, protected by
Home Assistant's own login.

1. Owner clicks the add-on's sidebar entry.
2. openGym opens inside Home Assistant, already authenticated at the HA level.

**Done when:** the app works fully under Home Assistant's proxy path. Known tension: passkeys
bind to the Home Assistant origin and the app's offline worker only registers over HTTPS.
This may become a non-goal after a spike. As of v1.4.5 upstream's web server also forbids
being framed, so this use case cannot be met with unmodified images (vision principle 1).

## UC-7 Connect the native and watch apps to the instance

**Actor:** Owner or household member. **Trigger:** prefers openGym's own apps to the browser.
Clients the owner expects to use: the Android app, possibly the iPhone app, and the Garmin
and Samsung watch apps.

1. In the phone app, enters the server address and signs in or pairs the way upstream
   offers for the instance's sign-in method.
2. Connects the watch app the way upstream documents for that watch.

**Done when:** phone and watch sync with the instance; later sessions do not need
re-pairing. This is the use case the owner cares about most (2026-11-23).

## UC-8 Rest-timer and reminder notifications

**Actor:** Owner. **Trigger:** wants push notifications for rest-timer-over and training-day
reminders.

1. In openGym settings, enables notifications on the phone.
2. Phone receives a push when the rest timer ends, even with the screen off.

**Done when:** notifications arrive. Requires HTTPS and a push subject; the add-on supplies
both from its configuration.

## UC-9 See why it is not working

**Actor:** Owner. **Trigger:** the add-on starts but the app does not load, or sign-in fails.

1. Opens the add-on's Log tab in Home Assistant.
2. Reads what openGym and the web server report.

**Done when:** the log names the misconfiguration (hostname mismatch, data directory not
writable, port in use) in words the owner can act on.

## UC-10 Use openGym away from home

**Actor:** Owner or household member. **Trigger:** trains at a gym, not at home.
Promoted from the candidates on 2026-11-23.

1. Away from the home network, opens openGym in the app or the browser on the phone.
2. Logs a workout as at home.

**Done when:** the workout reaches the instance without the person doing anything special
(no manual VPN toggle unless they chose that route), and nobody without an account can get
past the sign-in screen.

## Candidate use cases not written up

Add here, or promote to a numbered use case:

- Move an existing docker-compose openGym instance's data folder into the add-on.
- Run on an amd64 Home Assistant (Blue, Yellow, generic x86) rather than a Green.
- Have Home Assistant react when a workout is finished or a weigh-in is logged, using
  upstream's webhooks (v1.4.4). Off for v1, possible option later (2026-11-23).
- Sign in through an identity provider (upstream OIDC, v1.4.5). Not planned (2026-11-23).
- Let an AI assistant the person already pays for (Claude, ChatGPT) read and change their own
  profile as a connector, using upstream's MCP server (v1.4.5): "make me three routines",
  "log today's squats". No API key; each person connects their own account. Candidate for
  later (2026-11-23); needs a third upstream program in the add-on (architecture.md).
