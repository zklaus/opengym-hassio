#!/bin/sh
# Start script of the openGym add-on (docs/architecture.md C3, decisions/004).
# Reads the options, checks what can be checked, starts upstream's API and upstream's nginx
# exactly as their images do, and stops everything when either stops.
set -eu

ADDON_DIR=/opt/opengym-addon
OPTIONS=/data/options.json
LAST_ADDRESS=/data/public-address
export DATA_DIR=/data/opengym

log() { echo "[opengym-addon] $*"; }

# 1. Options -> upstream's settings. settings.mjs explains itself on failure.
settings=$(node "$ADDON_DIR/settings.mjs" "$OPTIONS") || exit 1
while IFS='=' read -r name value; do
  [ -n "$name" ] && export "$name=$value"
done <<SETTINGS
$settings
SETTINGS

# 2. The data folder has to be writable: every save goes through it.
if ! { mkdir -p "$DATA_DIR" && touch "$DATA_DIR/.write-test" && rm -f "$DATA_DIR/.write-test"; } 2>/dev/null; then
  log "Cannot write to the data folder ($DATA_DIR). openGym could not save anything, so it is not started. Check the free space on the device and restart the add-on."
  exit 1
fi

# 3. Passkeys belong to one address. Say so when it changes.
if [ -f "$LAST_ADDRESS" ]; then
  last=$(cat "$LAST_ADDRESS")
  if [ "$last" != "$ORIGIN" ]; then
    log "The public address changed from $last to $ORIGIN. Passkeys made for $last do not work at the new address; change it back, or have everyone register a new passkey."
  fi
fi
printf '%s\n' "$ORIGIN" > "$LAST_ADDRESS"

# 4. One line that says what is running.
opengym_version=$(node -p "require('/app/package.json').version")
log "openGym $opengym_version (add-on $(cat "$ADDON_DIR/version")), public address $ORIGIN"

# 5. Settings that are always the same (docs/architecture.md, Interfaces), then both programs.
export TRUST_PROXY=1 FIRST_USER_ADMIN=1 ALLOW_GUEST=0

(cd /app && exec node server.js) &
api=$!

# nginx runs as upstream's unprivileged user and logs to the container's output, which it
# can only open once it owns the streams. No redirection on this line: /dev/stderr is
# "whatever this command's stderr is", so `2>/dev/null` would hand over /dev/null instead.
chown nginx /dev/stdout /dev/stderr || log "Could not hand the log output to nginx; nginx may fail to start."
su-exec nginx /docker-entrypoint.sh nginx -g 'daemon off;' &
web=$!

# 6. Wait until one of them stops or we are told to stop. Polling on purpose: `wait -n`
# did not notice a dead program in this image's shell (decisions/004).
stop_requested=0
# QUIT as well: upstream's web image declares it as its stop signal, and the Dockerfile's
# own STOPSIGNAL could be lost in a rebuild.
trap 'stop_requested=1' TERM INT QUIT

alive() { kill -0 "$1" 2>/dev/null; }

while [ "$stop_requested" = 0 ] && alive "$api" && alive "$web"; do
  sleep 1 &
  wait $! || true
done

if [ "$stop_requested" = 1 ]; then
  log "Stopping openGym."
  status=0
elif alive "$web"; then
  log "The openGym API stopped unexpectedly (its last messages are above). Stopping the add-on so that Home Assistant can restart it."
  status=1
else
  log "The openGym web server (nginx) stopped unexpectedly (its last messages are above). Stopping the add-on so that Home Assistant can restart it."
  status=1
fi

kill -TERM "$api" "$web" 2>/dev/null || true
wait "$api" 2>/dev/null || true
wait "$web" 2>/dev/null || true
exit "$status"
