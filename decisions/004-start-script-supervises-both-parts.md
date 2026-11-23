# D-004: One start script runs both parts; if either stops, the container stops

**Status:** accepted (owner, 2026-11-23)
**Date:** 2026-11-23
**Satisfies:** SR-1, FR-1, DR-1

## Context

The container holds two long-running programs (D-001). Something must read the add-on's
options, start both, pass their output to the add-on log, and react when one dies. Vision
principle 5: keep the packaging small.

## Decision

A single shell script, started under the container's built-in init (`init: true`, the add-on
default). It validates the options and stops with a clear message if they are unusable,
checks that the data folder is writable, logs the openGym version and public address, starts
the API as upstream does (as root) and nginx through upstream's entrypoint as upstream's
unprivileged user, and then waits. When either program exits, or on a stop signal, it stops
the other and exits, non-zero in the first case. Restarting is left to Home Assistant.

## Alternatives rejected

- **s6-overlay**, the usual choice in add-ons. Restarts each program on its own and handles
  signals well, but adds a third body of software and its own start-up conventions to an
  image that is otherwise upstream's.
- **Starting only nginx and letting it spawn the API.** nginx does not supervise programs.

## Consequences

- The script is the one piece of logic we own, so it gets tests (bad options, a dying
  program, a stop signal).
- Spike finding, 2026-11-23: the obvious form (`wait -n` plus a `trap`) did not work in the
  image's shell: after the API was killed the container kept running with nginx alone, and a
  stop took the full 10-second timeout. The script must poll, as the community add-on does,
  and the tests above must cover exactly these two cases.
- nginx can only write to the container's output after the script hands the output streams
  to nginx's user (also found in the spike).
- Home Assistant restarts a crashed or unresponsive add-on only if the add-on's Watchdog
  switch is on, and that switch is the owner's. [NEEDS CLARIFICATION: confirm on the device;
  if so, turning it on becomes an installation step and SR-1's fourth criterion is reworded.]
