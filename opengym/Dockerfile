# openGym as a Home Assistant add-on: upstream's web image, with upstream's API copied in
# beside it. No upstream file is edited (docs/requirements.md DR-1, decisions/001).
# Both images must be the same openGym release and are pinned by digest; change tag and
# digest together.
FROM ghcr.io/duartesantos8/opengym-api:1.4.5@sha256:397c83e9ac33a413bc8f21e66b2e55038100fc7f9da900d80be28b30fbb12ea8 AS api

FROM ghcr.io/duartesantos8/opengym-web:1.4.5@sha256:e621677554302a0e1745e3b8c90acddc7d7149e118c4d683d51c13aa88f47d27

USER root

# libatomic: needed by the Node binary copied below (the API image has it, the web image
# does not). su-exec: lets the start script run nginx as upstream's unprivileged user.
RUN apk add --no-cache libatomic su-exec

COPY --from=api /usr/local/bin/node /usr/local/bin/node
COPY --from=api /app /app

# Fail the build here, not on someone's device, if the copied Node cannot run in this base.
RUN node -e "require('/app/package.json')" && node --version

# Settings that never vary in the add-on (docs/architecture.md, Interfaces). All are
# upstream's own, documented settings. NODE_ENV and PORT are what the API image sets.
ENV NODE_ENV=production \
    PORT=3000 \
    NGINX_PORT=8080 \
    BACKEND=127.0.0.1 \
    RESOLVER=127.0.0.1

ARG BUILD_VERSION=dev
RUN mkdir -p /opt/opengym-addon && printf '%s\n' "$BUILD_VERSION" > /opt/opengym-addon/version
COPY --chmod=755 run.sh /opt/opengym-addon/run.sh
COPY settings.mjs /opt/opengym-addon/settings.mjs

# Through nginx to the API, so it covers both programs.
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD wget --spider -q "http://127.0.0.1:8080/api/health" || exit 1

# The web image asks to be stopped with SIGQUIT, which suits nginx alone. The start script
# is what gets the signal here, and it stops both programs.
STOPSIGNAL SIGTERM

ENTRYPOINT []
CMD ["/opt/opengym-addon/run.sh"]
