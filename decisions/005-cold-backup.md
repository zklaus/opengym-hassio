# D-005: Backups stop the add-on for their duration

**Status:** accepted (owner, 2026-11-23)
**Date:** 2026-11-23
**Satisfies:** RR-1

## Context

RR-1: a backup taken while the add-on is running restores to a working state. openGym keeps
its data as files in one folder (a JSON database, a secret, uploads). We have not established
that every one of those files is consistent at every instant.

## Decision

`backup: cold`. Home Assistant stops the add-on, copies its data, and starts it again. The
whole data folder is included; nothing is excluded, uploads included (UC-3 names them).

## Alternatives rejected

- **Hot backup.** No interruption, but correctness would rest on an unverified property of
  upstream's file writing, and a backup that fails only sometimes is the worst kind.
- **Excluding uploads to keep backups small.** Upstream documents it, but UC-3 and SC-2
  require the media back.

## Consequences

- openGym is unreachable for the seconds a backup takes, typically at night. The apps work
  offline and sync afterwards; a reminder due in that window is sent up to 15 minutes late
  (upstream behaviour).
- Revisit if backups grow slow with many uploads, or if upstream documents safe hot copies.
