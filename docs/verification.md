# Verification

<!-- Phase 4 document, drafted alongside requirements (Phase 1) so that every requirement has
     a check from the start. One row per requirement: the scenario (Given/When/Then or the
     EARS line), whether it is automated or manual, and the milestone where it is first run.
     Findings from real use feed back into requirements.md. -->

**Status:** rows drafted on 2026-11-23 with requirements.md; nothing run yet. "First checked
at" is filled in Phase 3, when the milestones exist.

| Id | Scenario | How | First checked at | Result |
|---|---|---|---|---|
| FR-1 | Given a Green with no openGym add-on, when the owner adds the repository, installs, sets the public address and starts, then openGym answers at the public address within 60 s and a first workout can be logged. | Manual, on the Green | | |
| FR-1 | Given no public address is set, when the add-on is started, then it stops and the log names the missing setting. | Manual; scriptable | | |
| FR-2 | Given the add-on is running, when a phone opens the public address, then a passkey can be registered and used to sign in. | Manual, phone | | |
| FR-2 | Given the add-on is running, when another device on the home network scans the Home Assistant device for an openGym listener, then none is reachable. | Script from a second machine | | |
| FR-2 | Given default options, when the sign-in screen is opened, then it offers neither guest mode nor password sign-in. | Manual | | |
| FR-2 | Given a signed-in phone with notifications enabled, when a rest timer ends with the screen off, then a notification arrives. | Manual, phone | | |
| FR-3 | Given a signed-in browser, when a pairing code is entered in the Android app with the public address, then the app shows the profile's data. Repeat on iPhone if available. | Manual, phone | | |
| FR-3 | Given a paired phone app, when the Garmin and the Samsung watch apps are connected as upstream documents, then a workout logged on the watch appears in the browser. | Manual, watches | | |
| FR-3 | Given a paired app, when the add-on is restarted, and again after an update, then the app syncs without re-pairing. | Manual | | |
| FR-3 | Given a paired app on mobile data, away from the home network, when a workout is logged, then it appears in the browser at home. | Manual | | |
| FR-4 | Given a fresh installation, when the owner creates the first profile, then the administrator screens are available to it. | Manual | | |
| FR-4 | Given two profiles, when each signs in, then neither sees the other's workouts; the administrator sees both accounts and can disable the second. | Manual | | |
| FR-4 | Given sign-up switched to invitation only, when a profile is created without an invitation, then it is refused; with an invitation issued by the administrator, it succeeds. | Manual | | |
| RR-1 | Given data from the FR checks, when the device is rebooted, then all of it is still shown. | Manual | | |
| RR-1 | Given a backup taken while the add-on runs, when it is restored on a fresh Home Assistant and the public address is pointed there, then all data is shown, the browser is still signed in and the passkey still works. | Manual, second installation | | |
| RR-1 | Given an installation with data on the previous add-on version, when the update is installed, then openGym runs the new version with the same data. | Manual | | |
| POR-1 | Given a Green, when the add-on is installed, then no build of openGym runs on the device (installation log), and memory use at rest with five profiles stays under the ceiling. | Manual, Home Assistant's add-on statistics | | |
| SR-1 | Given the add-on is running, when openGym is opened at a different address and sign-in is tried, then the log names the address used and the address expected. | Manual; scriptable | | |
| SR-1 | Given the data location is made unwritable, when the add-on starts, then the log says so and the add-on stops. | Manual, development environment | | |
| SR-1 | Given the add-on is running, when openGym is made to stop answering, then Home Assistant restarts it unprompted. | Manual | | |
| DR-1 | Given a published add-on version, when what it carries is compared with the upstream release it names, then the two are identical. | Script | | |
| DR-1 | Given a running add-on, when its settings are listed, then every one is documented by upstream, and webhooks and identity-provider sign-in are off. | Script plus review | | |
| SC-1 | The owner times the path from "add repository" to a logged workout, following DOCS only: under ten minutes. | Manual, stopwatch | | |
| SC-2 | Backup on one device, restore on another: every item in the SC-2 list is back and the Android app and a watch sync without re-pairing. | Manual, second device | | |
| SC-3 | For each of the next three openGym releases, record the days until the add-on update was available and whether it installed in one click. | Record in CHANGELOG | | |
