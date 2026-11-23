# openGym

[openGym](https://github.com/DuarteSantos8/openGym) is a self-hosted gym and body-weight
tracker. This add-on runs it on Home Assistant, exactly as upstream released it, at an HTTPS
address of its own, so that passkeys and openGym's phone and watch apps work as upstream
documents them.

It does not appear in the Home Assistant sidebar and has no port on your home network: you
need an HTTPS reverse proxy on the same Home Assistant device, for example the NGINX Home
Assistant SSL proxy add-on. See the Documentation tab.
