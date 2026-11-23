#!/usr/bin/env bash
# Tests for the add-on image and its start script. Needs only Docker.
# Usage: tests/run.sh            (run from anywhere; builds the image first)
# Each check names the requirement it covers (docs/requirements.md).
set -u   # no pipefail: `logs | grep -q` ends the pipe early on purpose
cd "$(dirname "$0")/.."

IMAGE=opengym-addon:test
NAME=opengym-addon-test
VOLUMES=()   # Docker volumes standing in for the add-on's /data; removed at the end
failures=0

# The two upstream images, exactly as the Dockerfile pins them.
API_REF=$(sed -nE 's/^FROM (ghcr\.io\/duartesantos8\/opengym-api:[^ ]+).*/\1/p' opengym/Dockerfile)
WEB_REF=$(sed -nE 's/^FROM (ghcr\.io\/duartesantos8\/opengym-web:[^ ]+).*/\1/p' opengym/Dockerfile)

cleanup() {
  docker rm -f "$NAME" >/dev/null 2>&1
  [ ${#VOLUMES[@]} -gt 0 ] && docker volume rm "${VOLUMES[@]}" >/dev/null 2>&1
}
trap cleanup EXIT

pass() { echo "ok    $1"; }
fail() { echo "FAIL  $1"; [ $# -gt 1 ] && echo "$2" | sed 's/^/        /'; failures=$((failures + 1)); }
check() { # check "<description>" <command...>
  local what=$1; shift
  if "$@" >/dev/null 2>&1; then pass "$what"; else fail "$what"; fi
}

# Docker volumes rather than folders: the API writes its data as root, and a volume can be
# removed without touching the host's files.
write_options() { # write_options <volume> <json>
  printf '%s' "$2" | docker run --rm -i -v "$1:/data" --entrypoint sh "$IMAGE" -c 'cat > /data/options.json'
}
new_data() { # new_data <label> <json>: sets DATA to a fresh volume holding these options
  DATA="opengym-addon-test-$1"
  docker volume rm "$DATA" >/dev/null 2>&1
  docker volume create "$DATA" >/dev/null
  VOLUMES+=("$DATA")
  write_options "$DATA" "$2"
}
start() { # start <volume> [ro]
  docker rm -f "$NAME" >/dev/null 2>&1
  docker run -d --name "$NAME" --init -v "$1:/data${2:+:$2}" "$IMAGE" >/dev/null
}
logs() { docker logs "$NAME" 2>&1; }
running() { [ "$(docker inspect -f '{{.State.Running}}' "$NAME" 2>/dev/null)" = true ]; }
exit_code() { docker inspect -f '{{.State.ExitCode}}' "$NAME"; }
get() { docker exec "$NAME" wget -q -O- "http://127.0.0.1:8080$1"; }
wait_for() { # wait_for <seconds> <command...>; prints the seconds it took
  local limit=$1 t=0; shift
  until "$@" >/dev/null 2>&1; do
    t=$((t + 1)); [ "$t" -ge "$limit" ] && return 1; sleep 1
  done
  echo "$t"
}
stopped() { ! running; }
tree_sum() { # tree_sum <image> <dir>: one checksum over every file under dir
  docker run --rm --entrypoint sh "$1" -c "cd $2 && find . -type f -exec sha256sum {} + | sort -k2 | sha256sum"
}
file_sum() { docker run --rm --entrypoint sha256sum "$1" "$2" | cut -d' ' -f1; }

VALID='{"public_address":"https://gym.example.org","invite_only":false,"password_login":false}'

echo "== build"
if ! docker build -q --build-arg BUILD_VERSION=test -t "$IMAGE" opengym >/dev/null; then
  echo "FAIL  the image does not build"; exit 1
fi
pass "the image builds from upstream's pinned images, nothing compiled (POR-1)"

echo "== upstream's files are unmodified (DR-1)"
[ "$(tree_sum "$IMAGE" /app)" = "$(tree_sum "$API_REF" /app)" ] \
  && pass "/app is identical to upstream's API image" || fail "/app differs from upstream's API image"
[ "$(file_sum "$IMAGE" /usr/local/bin/node)" = "$(file_sum "$API_REF" /usr/local/bin/node)" ] \
  && pass "the Node binary is the one from upstream's API image" || fail "the Node binary differs"
[ "$(tree_sum "$IMAGE" /usr/share/nginx/html)" = "$(tree_sum "$WEB_REF" /usr/share/nginx/html)" ] \
  && pass "the frontend and media are identical to upstream's web image" || fail "the web root differs"
[ "$(tree_sum "$IMAGE" /etc/nginx)" = "$(tree_sum "$WEB_REF" /etc/nginx)" ] \
  && pass "the nginx configuration and template are upstream's" || fail "/etc/nginx differs"
[ "$(tree_sum "$IMAGE" /docker-entrypoint.d)" = "$(tree_sum "$WEB_REF" /docker-entrypoint.d)" ] \
  && pass "nginx's entrypoint scripts are upstream's" || fail "/docker-entrypoint.d differs"

echo "== unusable options are refused with a message (FR-1, FR-2)"
refused() { # refused <description> <options json> <text the log must contain>
  new_data bad "$2"; start "$DATA"
  if wait_for 10 stopped >/dev/null && [ "$(exit_code)" != 0 ] && logs | grep -qF -- "$3"; then
    pass "$1"
  else
    fail "$1" "exit=$(exit_code) log: $(logs | tail -3)"
  fi
}
refused "no public address"            '{"invite_only":false}'                              'The option "public_address" is not set'
refused "a plain-HTTP address"         '{"public_address":"http://gym.example.org"}'        'has to start with https://'
refused "an IP address"                '{"public_address":"https://192.168.1.20"}'          'an IP address'
refused "an address with a path"       '{"public_address":"https://example.org/gym"}'       'with nothing after it'
refused "not an address at all"        '{"public_address":"gym"}'                           'is not an address'
refused "a bad notification contact"   '{"public_address":"https://gym.example.org","notification_contact":"nobody"}' 'not an e-mail address'

echo "== a valid configuration starts (FR-1, FR-2, FR-4, SR-1, DR-1)"
new_data good "$VALID"; GOOD=$DATA
start "$GOOD"
if took=$(wait_for 60 get /api/health); then
  pass "health answers through nginx after ${took}s (limit 60 s)"
else
  fail "health did not answer within 60 s" "$(logs | tail -5)"
fi
logs | grep -qE '^\[opengym-addon\] openGym [0-9]+\.[0-9]+\.[0-9]+ \(add-on test\), public address https://gym\.example\.org$' \
  && pass "the log names the openGym version and the public address" || fail "no version line" "$(logs | head -5)"
logs | grep -qF 'rpID=gym.example.org, origin=https://gym.example.org' \
  && pass "the API runs with the hostname and address from the option" || fail "the API has a different address"
config=$(get /api/config)
echo "$config" | grep -q '"allow_guest":false' && pass "guest mode is off" || fail "guest mode is not off" "$config"
echo "$config" | grep -q '"invite_only":false' && pass "sign-up is open until the owner closes it" || fail "invite_only is not false" "$config"
echo "$config" | grep -q '"password_login":true' && fail "password sign-in is on by default" "$config" || pass "password sign-in is off by default"
get /api/health | grep -q '"writable":true' && pass "the API reports its data folder writable" || fail "data folder not writable"
get / | grep -qi '<!doctype html>' && pass "the frontend is served" || fail "the frontend is not served"
procs=$(docker exec "$NAME" ps -o user,args | grep -vE 'ps -o|^USER|docker-init|sleep 1')
[ "$(echo "$procs" | grep -cvE 'run\.sh|node|nginx')" = 0 ] \
  && pass "only the start script, the API and nginx run" || fail "unexpected processes" "$procs"
echo "$procs" | grep 'nginx' | grep -qv '^nginx' \
  && fail "nginx does not run as upstream's unprivileged user" "$procs" || pass "nginx runs as upstream's unprivileged user"
[ "$(docker port "$NAME" | wc -l)" = 0 ] && pass "no port is published" || fail "a port is published"

docker exec "$NAME" wget -q -O- --header 'Origin: http://192.168.1.5:8080' --header 'Content-Type: application/json' \
  --post-data '{}' http://127.0.0.1:8080/api/logout >/dev/null 2>&1
logs | grep -qF 'origin="http://192.168.1.5:8080" expected=https://gym.example.org' \
  && pass "a request from another address is logged with both addresses" || fail "no address-mismatch line" "$(logs | tail -3)"

if took=$(wait_for 120 sh -c "[ \"\$(docker inspect -f '{{.State.Health.Status}}' $NAME)\" = healthy ]"); then
  pass "the container's own health check turns healthy"
else
  fail "the container's health check did not turn healthy"
fi

echo "== stopping and failing (SR-1)"
secret_before=$(docker exec "$NAME" sha256sum /data/opengym/secret)
begin=$(date +%s); docker stop -t 30 "$NAME" >/dev/null; took=$(( $(date +%s) - begin ))
{ [ "$took" -le 5 ] && [ "$(exit_code)" = 0 ]; } \
  && pass "a stop signal stops it cleanly in ${took}s (limit 5 s)" || fail "stop took ${took}s, exit $(exit_code)"

docker start "$NAME" >/dev/null; wait_for 60 get /api/health >/dev/null
[ "$(docker exec "$NAME" sha256sum /data/opengym/secret)" = "$secret_before" ] \
  && pass "data survives a restart (RR-1)" || fail "the session secret changed across a restart"
docker exec "$NAME" sh -c 'kill -9 $(pgrep -x node)'
if took=$(wait_for 10 stopped) && [ "$(exit_code)" != 0 ] && logs | grep -qF 'The openGym API stopped unexpectedly'; then
  pass "the API dying stops the container, non-zero, after ${took}s (limit 10 s)"
else
  fail "the container survived the API dying" "running=$(running && echo yes || echo no) exit=$(exit_code)"
fi

docker start "$NAME" >/dev/null; wait_for 60 get /api/health >/dev/null
docker exec "$NAME" sh -c 'kill -9 $(ps -o pid,args | awk "/nginx: [m]aster/ {print \$1}")'
if took=$(wait_for 10 stopped) && [ "$(exit_code)" != 0 ] && logs | grep -qF 'The openGym web server (nginx) stopped unexpectedly'; then
  pass "nginx dying stops the container, non-zero, after ${took}s"
else
  fail "the container survived nginx dying" "running=$(running && echo yes || echo no) exit=$(exit_code)"
fi

echo "== options (FR-2, FR-4, RR-1)"
write_options "$GOOD" '{"public_address":"https://training.example.org","invite_only":true,"password_login":true,"notification_contact":"owner@example.org"}'
docker start "$NAME" >/dev/null; wait_for 60 get /api/health >/dev/null
logs | grep -qF 'The public address changed from https://gym.example.org to https://training.example.org' \
  && pass "a changed public address is warned about" || fail "no warning about the changed address"
config=$(get /api/config)
echo "$config" | grep -q '"invite_only":true' && pass "invite_only closes sign-up" || fail "invite_only has no effect" "$config"
echo "$config" | grep -q '"password_login":true' && pass "password_login turns password sign-in on" || fail "password_login has no effect" "$config"
docker exec "$NAME" sh -c 'tr "\0" "\n" < /proc/$(pgrep -x node)/environ' | grep -qx 'VAPID_SUBJECT=mailto:owner@example.org' \
  && pass "notification_contact reaches the API" || fail "notification_contact does not reach the API"

echo "== an unwritable data folder (SR-1)"
new_data readonly "$VALID"
start "$DATA" ro
if wait_for 10 stopped >/dev/null && [ "$(exit_code)" != 0 ] && logs | grep -qF 'Cannot write to the data folder'; then
  pass "it says so and stops"
else
  fail "an unwritable data folder is not reported" "exit=$(exit_code) log: $(logs | tail -3)"
fi

echo
if [ "$failures" = 0 ]; then echo "All checks passed."; else echo "$failures check(s) failed."; fi
[ "$failures" = 0 ]
