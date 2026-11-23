# Requirements

<!-- Phase 1 document. Conventions (CLAUDE.md): requirements are DECISIONS about what must be
     true of the solution, they say what not how, each cites the use cases it serves,
     acceptance criteria are in EARS form, unknowns are [NEEDS CLARIFICATION: ...]. Aim for
     5 to 8 important requirements, not completeness. Ids: FR- PR- RR- POR- SR- DR- SC-,
     never renumbered. Draft seeded by Claude on 2026-11-23 from vision.md and use-cases.md. -->

**Status:** approved by the owner on 2026-11-23 (Phase 1 gate passed)

Words used below:

- **The add-on**: what the owner installs; **openGym**: the application it carries.
- **The public address**: the one HTTPS address at which people open openGym, for example
  `https://gym.example.org`. It is openGym's own, not Home Assistant's.
- **The HTTPS front end**: whatever the owner already runs to serve HTTPS for their home
  (vision.md, Open questions: resolved). The add-on relies on it and does not replace it.

## Functional (what must it do?)

### FR-1 Install from the store and start with one required setting

Serves: UC-1, UC-9

The owner adds a repository address in the Home Assistant add-on store, installs the add-on,
enters the public address, and starts it. Nothing else is required for a first run.

- WHEN the owner starts the add-on with a public address set THE SYSTEM SHALL serve openGym
  to the HTTPS front end within 60 seconds.
- WHEN the owner starts the add-on without a public address THE SYSTEM SHALL refuse to start
  and state in its log which setting is missing.
- WHEN openGym is opened at the public address on a fresh installation THE SYSTEM SHALL let
  the owner create a profile, pick a starter plan and log a workout.
- WHEN the add-on's documentation is followed from "add repository" to "first workout" THE
  SYSTEM SHALL need no step outside Home Assistant's own screens, the HTTPS front end's
  configuration, and the phone.

### FR-2 Reachable only at the public address, with passkey sign-in

Serves: UC-1, UC-2, UC-8, UC-10

Everything openGym ties to its address (passkeys, pairing, push notifications) works at the
public address, from inside and outside the home network alike. There is no second way in.

- WHEN a person opens the public address on a phone THE SYSTEM SHALL let them register a
  passkey and sign in with it.
- WHEN a device on the home network tries to reach openGym other than through the HTTPS front
  end THE SYSTEM SHALL offer no connection.
- WHEN a person without an account opens the public address THE SYSTEM SHALL show them
  nothing beyond the sign-in screen (no guest mode).
- WHEN the owner has not turned password sign-in on THE SYSTEM SHALL offer no password
  sign-in.
- WHEN a signed-in person enables notifications THE SYSTEM SHALL deliver rest-timer and
  reminder notifications to that phone with no further setup by the owner.
- WHEN the owner sets a contact address for notifications THE SYSTEM SHALL present that
  address to push services instead of the public address.

Consequence, accepted with this requirement: the HTTPS front end must be able to reach the
add-on without a connection that other home-network devices could also use. For the
reference environment (front end on the same Home Assistant) that is expected to hold.
Decided by the owner on 2026-11-23: v1 supports an HTTPS front end on the same Home Assistant
device only; a front end on another machine is out (vision.md, Non-goals).

### FR-3 The native and watch apps connect and stay connected

Serves: UC-7, UC-10

The use case the owner cares about most. The apps are used as upstream documents them, with
the public address as the server address.

- WHEN a signed-in person requests a pairing code in the browser and enters it with the
  public address in the Android or iPhone app THE SYSTEM SHALL pair that app with their
  profile.
- WHEN a paired phone app is connected to a Garmin or Samsung watch app as upstream documents
  THE SYSTEM SHALL sync workouts between watch, phone and the instance.
- WHEN the add-on is restarted, updated, or restored from a backup THE SYSTEM SHALL keep
  every paired app paired.
- WHEN a paired app is used away from the home network THE SYSTEM SHALL sync as it does at
  home, with no extra action by the person.

### FR-4 Household profiles, with the owner in charge

Serves: UC-5, UC-10

- WHEN the owner creates the first profile on a fresh installation THE SYSTEM SHALL make that
  profile the administrator, with no file to edit and no identifier to copy.
- WHEN the administrator issues an invitation THE SYSTEM SHALL let the invited person create
  their own profile at the public address.
- WHEN a household member is signed in THE SYSTEM SHALL show them only their own data.
- WHEN the administrator opens the list of accounts THE SYSTEM SHALL show every account and
  let the administrator disable one.
- WHEN the owner has switched sign-up to invitation only THE SYSTEM SHALL refuse to create a
  profile without a valid invitation.
- WHEN the owner chooses open sign-up instead THE SYSTEM SHALL let anyone at the public
  address create a profile.

Decided by the owner on 2026-11-23: invitation only is the intended state. Upstream cannot
require invitations before the first profile exists (nobody could issue one), so the first
run has two steps: the owner creates their profile, then switches sign-up to invitation
only. The documentation presents both as part of installation. Until the second step is
done, sign-up is open.

## Performance (how fast, how much?)

No separate performance requirement in v1. The start-up time is in FR-1, the memory ceiling
in POR-1, and the installation time in SC-1.

## Reliability (how reliably?)

### RR-1 Data survives restart, update, and backup and restore

Serves: UC-3, UC-4, UC-7, UC-8

Everything openGym stores lives in one place that Home Assistant keeps and backs up:
profiles, workouts, body-weight entries, custom exercises with their photos and videos,
settings, passkeys, sessions, app pairings and notification subscriptions.

- WHEN the add-on is stopped and started, or the device is rebooted, THE SYSTEM SHALL present
  all data as it was before.
- WHEN the add-on is updated to a version carrying a newer openGym THE SYSTEM SHALL run with
  the existing data with no action by the owner.
- WHEN a Home Assistant backup containing the add-on is restored on a fresh Home Assistant,
  and the public address is pointed at it, THE SYSTEM SHALL present all data as it was at the
  time of the backup, with every person still signed in and every passkey still valid.
- WHEN a backup is taken while the add-on is running THE SYSTEM SHALL produce a backup that
  restores to a working state.
- WHEN the add-on is uninstalled and installed again without restoring a backup THE SYSTEM
  SHALL start empty (data removal follows Home Assistant's own rules, not ours).

## Portability (where must it work?)

### POR-1 Runs on a Home Assistant Green beside everything else

Serves: UC-1, UC-4

- WHEN the add-on is installed or updated on a Home Assistant Green THE SYSTEM SHALL complete
  the installation without compiling or assembling openGym on the device.
- WHEN the add-on is running with five profiles and nobody training THE SYSTEM SHALL use no
  more than 200 MB of memory. (Revised 2026-11-23 in Phase 2: a spike measured about 67 MiB
  at rest on a workstation, see architecture.md, Spikes; this replaces the unmeasured
  "proposed 300 MB". The figure on the Green is taken at verification.)

Decided by the owner on 2026-11-23: the Green is the only verified device. Other Home
Assistant OS machines may work; nothing is checked or promised for them.

## Serviceability (how is it operated and debugged?)

### SR-1 The log says what is wrong, and Home Assistant knows whether openGym is up

Serves: UC-9, UC-2, UC-4

- WHEN openGym is opened at an address other than the configured public address and a
  sign-in or a save is refused THE SYSTEM SHALL write a log line naming both the address used
  and the address expected.
- WHEN the add-on cannot write its data THE SYSTEM SHALL say so in the log and stop, rather
  than run without saving.
- WHEN the add-on starts THE SYSTEM SHALL write to the log the openGym version it carries and
  the public address it is configured for.
- WHEN openGym stops answering while the add-on still appears started THE SYSTEM SHALL be
  restarted by Home Assistant without action by the owner.
- WHEN the owner opens the add-on's log in Home Assistant THE SYSTEM SHALL show the messages
  of every part of openGym there, with no second place to look.

## Design constraints (what must hold in the design?)

### DR-1 openGym is carried exactly as upstream released it

Serves: UC-4, UC-7

Vision principles 1 and 5. This is what keeps upstream's documentation, apps and future
releases valid for the add-on.

- WHEN an add-on version is published THE SYSTEM SHALL carry exactly one tagged openGym
  release, unmodified: no patched files, no replaced parts.
- WHEN an add-on version is published THE SYSTEM SHALL name the openGym release it carries in
  its version number or changelog.
- WHEN the add-on runs THE SYSTEM SHALL run nothing beyond what that openGym release needs to
  serve the app (no extra services, no AI runtime in the container). The AI Coach that an
  administrator connects in the app to an outside provider is part of openGym and stays
  available (revised 2026-11-23; see vision.md, Non-goals).
- WHEN the add-on's configuration is rendered THE SYSTEM SHALL only use settings that
  upstream documents; an upstream feature the owner has not asked for stays at upstream's
  default or off (webhooks and identity-provider sign-in: off).

## Success criteria (measurable, technology-agnostic)

### SC-1 From "add repository" to a logged workout in under ten minutes

Serves: UC-1, UC-2

A Green owner whose HTTPS front end already works, following only the add-on's own
documentation, logs a first workout on their phone within ten minutes of adding the
repository. Measured once, by the owner, with a stopwatch.

### SC-2 A backup restored on another device loses nothing

Serves: UC-3

A Home Assistant backup taken on one device and restored on another brings back every
profile, workout, body-weight entry, custom exercise with media, setting and passkey; the
Android app and a watch app sync again without re-pairing.

### SC-3 An openGym release becomes an add-on update promptly

Serves: UC-4

An add-on update carrying a new openGym release is available within 7 days of
the upstream release (decided by the owner on 2026-11-23), and installing it needs one click
and no data migration.

## Open questions for stakeholders

None open for the owner. Answered on 2026-11-23 and recorded in place: sign-up is invitation
only after the owner's profile exists (FR-4); the HTTPS front end runs on the same device
(FR-2); the Green is the only verified device (POR-1); updates within 7 days (SC-3).

Measured in Phase 2 (architecture.md, Spikes): the memory ceiling in POR-1.

Checked while drafting, against upstream v1.4.5 on 2026-11-23, so no question remains:

- SR-1, wrong address: upstream already logs the address used and the address expected.
- FR-2, notifications: upstream needs no server-side setup and keeps its push identity with
  the rest of its data (RR-1).
- FR-3, pairing: the phone apps pair with a one-time code from a signed-in browser, and stay
  paired as long as the data and the address stay the same.
