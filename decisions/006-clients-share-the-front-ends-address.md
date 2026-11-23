# D-006: In v1 the API sees every visitor at the front end's address

**Status:** accepted (owner, 2026-11-23)
**Date:** 2026-11-23
**Satisfies:** DR-1, FR-2

## Context

Upstream's nginx overwrites the forwarded-address headers with the address of whoever
connects to it. In a compose setup that is the visitor or the user's proxy; here it is always
the HTTPS front end. Upstream throttles wrong passwords per name and per address, and its
optional activity log can record addresses (off by default).

## Decision

Leave it so. The add-on sets no address-forwarding setting, and password sign-in and the
activity log's addresses stay off by default.

## Alternatives rejected

- **An extra nginx configuration file that trusts the front end's forwarded address** (what
  misterblokhead/ha-opengym does). Works, but it is configuration upstream does not document
  (DR-1), and it trusts the whole internal add-on network.
- **Upstream's `CF_CONNECTING_IP` setting pointed at the front end's header.** A documented
  setting used for something it was not written for; correct only as long as nothing but the
  front end can reach the add-on.

## Consequences

- With password sign-in turned on, throttling by address acts on the household as a whole:
  one person's wrong passwords can slow sign-in for everyone. The documentation says so next
  to the option.
- If the owner later wants addresses in the activity log, this decision is the one to revisit.
