# D-002: Reachable on the internal add-on network only; no published port, no ingress

**Status:** accepted (owner, 2026-11-23)
**Date:** 2026-11-23
**Satisfies:** FR-2, FR-3

## Context

FR-2: no connection for home-network devices except through the HTTPS front end, which runs
on the same Home Assistant device (owner's decision, 2026-11-23). The owner's front end is
the official "NGINX Home Assistant SSL proxy" add-on. Add-ons share an internal network on
which each has a hostname; a port reaches the home network only if the add-on publishes it.

## Decision

The add-on listens on port 8080 inside its container and publishes nothing: `config.yaml`
has no `ports` entry and no `ingress`. The front end forwards to
`http://<add-on hostname>:8080`, the hostname being the one Home Assistant shows on the
add-on's Info page.

## Alternatives rejected

- **A published port, off by default.** One click would open plain HTTP on the home network,
  which FR-2 and the vision's non-goals rule out.
- **Host networking bound to 127.0.0.1.** The front end add-on is not on the host network, so
  it could not reach it.
- **Ingress.** Non-goal (vision.md).

## Consequences

- Other add-ons on the same device can reach port 8080, and also the API's own port 3000,
  which upstream binds to every interface and which trusts forwarded-address headers. Add-ons
  are software the owner installed; this is accepted and documented, not prevented.
  Reviewed with the owner on 2026-11-23 and accepted: reaching the API directly bypasses no
  sign-in; it allows forging the visitor address (throttling, activity log) and skipping
  nginx's upload limits. Rejected for now: a firewall rule in the container limiting port
  3000 to local connections. Revisit if password sign-in is on and an untrusted add-on runs
  on the same device.
- The add-on cannot be tried without a front end. Development uses `docker run -p` on a
  workstation instead.
- To be confirmed on the device at the first on-device milestone: the hostname resolves from
  the NGINX add-on, and Home Assistant's watchdog can reach an unpublished port.
