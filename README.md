# opengym-hassio

A Home Assistant add-on that packages [openGym](https://github.com/DuarteSantos8/openGym),
the self-hosted gym and body-weight tracker, so it runs on Home Assistant OS devices such as
the Home Assistant Green.

**Status: not ready.** The add-on builds and passes its tests on a workstation, but it has
not yet run on a Home Assistant device. Do not install it for real use.

To try it anyway: in Home Assistant, Settings → Add-ons → Add-on Store → ⋮ → Repositories, add
`https://github.com/zklaus/opengym-hassio`, then install "openGym" and read its Documentation
tab. You need an HTTPS reverse proxy on the same device.

This project is run spec-first. The documents under `docs/` are the primary artifacts;
the add-on under `opengym/` is derived from them. `tests/run.sh` builds and checks the image
(needs Docker).

| Document | Answers |
|---|---|
| [docs/vision.md](docs/vision.md) | Why this exists, who it is for, what it is *not* |
| [docs/use-cases.md](docs/use-cases.md) | What people actually want to do (evidence) |
| [docs/requirements.md](docs/requirements.md) | What must be true of the solution (decisions) |
| [docs/architecture.md](docs/architecture.md) | How the pieces fit, traced back to requirements |
| [docs/implementation-plan.md](docs/implementation-plan.md) | Milestones and tasks |
| [docs/verification.md](docs/verification.md) | How we know each requirement is met |
| [decisions/](decisions/) | One short record per non-obvious choice |

See [CLAUDE.md](CLAUDE.md) for the working conventions.

## Licences

- **This repository** (Dockerfile, start script, tests, workflows, documents): MIT, see
  [LICENSE](LICENSE).
- **openGym**, which the published image contains unmodified: GNU AGPL v3.0, © Duarte Santos.
  Its source for the carried release is at
  [github.com/DuarteSantos8/openGym](https://github.com/DuarteSantos8/openGym), under the tag
  named in the add-on's changelog. Its licence and notices are in
  [opengym/upstream/](opengym/upstream/) and inside the image under `/usr/share/doc/opengym/`.
- **The exercise pictures and animations** inside the image are not open: © Aliaksandr
  Makatserchyk, Gym visual, licensed for use in openGym only. This add-on is non-commercial
  and carries them unmodified, with upstream's notice. Do not copy them out of the image or a
  running instance; any other use needs your own licence from gymvisual.com.

See [decisions/007-licences.md](decisions/007-licences.md).
