# homelab-lib.sh - settings and helpers shared by the homelab-* scripts.
# This file is not run on its own. The other scripts load it with:  . /usr/local/bin/homelab-lib.sh
# shellcheck shell=bash

export LC_ALL=C.UTF-8
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

readonly HOST_IP=192.168.31.218
readonly STATE_DIR=/var/lib/homelab-update
readonly LOG_DIR=/var/log/homelab-update
readonly CONFIG_DIR=/srv/media/config
readonly MEDIA_MOUNT=/srv/media/data
readonly STAGING=/srv/media/data/backups/staging
readonly RESTIC_ENV=/etc/homelab/restic.env
readonly QUARANTINE=/var/lib/homelab-update/quarantine.json
readonly PENDING_FLAG=/var/lib/homelab-update/pending-verify
readonly LAST_RESULT=/var/lib/homelab-update/last-result

# The two compose projects (name and file), as Docker reports them.
readonly MAIN_PROJECT=compose
readonly MAIN_FILE=/home/gleb/devops-foundations/servers/home-server/compose/docker-compose.yml
readonly SIDE_PROJECT=minecraft-fabric
readonly SIDE_FILE=/home/gleb/devops-foundations/servers/mc-server/docker-compose.yml

# Apps that write databases. They are stopped while the pre-update snapshot is taken.
readonly DB_APPS="sonarr radarr prowlarr bazarr jellyfin seerr audiobookshelf cleanuparr qbittorrent"

log() { printf '%s  %s\n' "$(date '+%F %T')" "$*"; }
notify() { /usr/local/bin/homelab-notify "$@" || true; }

# compose_file PROJECT : print the compose file of a project.
compose_file() {
    case "$1" in
        "$MAIN_PROJECT") echo "$MAIN_FILE" ;;
        "$SIDE_PROJECT") echo "$SIDE_FILE" ;;
        *) return 1 ;;
    esac
}

# config_folder SERVICE : print the app's settings folder. Prints nothing for apps without one.
config_folder() {
    case "$1" in
        sonarr | radarr | prowlarr | bazarr | jellyfin | seerr | audiobookshelf | cleanuparr | \
            qbittorrent | gluetun | pihole | swag | fail2ban | recyclarr)
            echo "$CONFIG_DIR/$1"
            ;;
        *)
            echo ""
            ;;
    esac
}

# containers_json : print one JSON list describing every container of the two projects.
containers_json() {
    local ids
    ids="$(
        docker ps -a -q --filter "label=com.docker.compose.project=$MAIN_PROJECT"
        docker ps -a -q --filter "label=com.docker.compose.project=$SIDE_PROJECT"
    )"
    if [ -z "$ids" ]; then
        echo '[]'
        return 0
    fi
    # shellcheck disable=SC2086
    docker inspect $ids | jq '[.[] | {
        name: (.Name | ltrimstr("/")),
        id: .Id,
        project: .Config.Labels["com.docker.compose.project"],
        service: .Config.Labels["com.docker.compose.service"],
        image_ref: .Config.Image,
        image_id: .Image,
        status: .State.Status,
        health: (.State.Health.Status // "none"),
        restarts: .RestartCount
    }] | sort_by(.name)'
}

# regressions BASE NOW : print the names of checks that were OK in BASE and are not OK in NOW.
regressions() {
    if ! jq -e '.checks' "$2" > /dev/null 2>&1; then
        echo "health-check-did-not-run"
        return 0
    fi
    jq -r -n --slurpfile b "$1" --slurpfile n "$2" '
        ($n[0].checks | map({key: .name, value: .status}) | from_entries) as $now
        | $b[0].checks[]
        | select(.status == "OK")
        | select(($now[.name] // "MISSING") != "OK")
        | .name'
}

# blamed_apps BASE NOW : print the apps blamed for the regressions, one per line.
# The blame comes from the current result: a check of an app that is down itself
# blames only that app, not the apps it talks to.
blamed_apps() {
    if ! jq -e '.checks' "$2" > /dev/null 2>&1; then
        return 0
    fi
    jq -r -n --slurpfile b "$1" --slurpfile n "$2" '
        ($n[0].checks | map({key: .name, value: .}) | from_entries) as $now
        | $b[0].checks[]
        | select(.status == "OK")
        | $now[.name]
        | select(. != null and .status != "OK")
        | .blames[]' | sort -u
}

# wait_healthy BASE OUT : run the health check until nothing has regressed, for up to 10 minutes.
# Returns 0 when there is no regression left. OUT holds the last result.
wait_healthy() {
    local base="$1" out="$2" deadline=$((SECONDS + 600)) left
    while :; do
        # The quick form skips the indexer tests, so indexer sites are not hammered while waiting.
        /usr/local/bin/homelab-smoke-test --no-indexers --json "$out" > /dev/null 2>&1 || true
        left="$(regressions "$base" "$out" | grep -v '^indexer:' | tr '\n' ' ' || true)"
        if [ -z "$left" ] || [ "$SECONDS" -ge "$deadline" ]; then
            break
        fi
        log "  not healthy yet: $left"
        sleep 30
    done
    # One full run, indexers included. If only indexers fail, try once more a minute later.
    /usr/local/bin/homelab-smoke-test --json "$out" > /dev/null 2>&1 || true
    left="$(regressions "$base" "$out" | tr '\n' ' ')"
    if [ -n "$left" ] && [ -z "$(regressions "$base" "$out" | grep -v '^indexer:' || true)" ]; then
        log "  only indexer checks fail, one more try in a minute: $left"
        sleep 60
        /usr/local/bin/homelab-smoke-test --json "$out" > /dev/null 2>&1 || true
        left="$(regressions "$base" "$out" | tr '\n' ' ')"
    fi
    if [ -n "$left" ]; then
        log "  regressions: $left"
        return 1
    fi
    return 0
}

# newest_kernel : print the newest kernel version installed in /boot.
newest_kernel() {
    local f newest=""
    for f in /boot/vmlinuz-*; do
        if [ -e "$f" ]; then
            newest="$(printf '%s\n%s\n' "$newest" "${f#/boot/vmlinuz-}" | sort -V | tail -n 1)"
        fi
    done
    if [ -z "$newest" ]; then
        newest="$(uname -r)"
    fi
    echo "$newest"
}

# reboot_needed : true if a newer kernel is installed or Debian asks for a reboot.
reboot_needed() {
    [ "$(newest_kernel)" != "$(uname -r)" ] || [ -e /run/reboot-required ]
}

# nvidia_ready : true if the NVIDIA driver is built for the newest installed kernel.
nvidia_ready() {
    dkms status 2> /dev/null | grep -E '^nvidia' | grep -F ", $(newest_kernel)," | grep -q ': installed'
}

# load_restic : make restic use the vault.
load_restic() {
    set -a
    # shellcheck disable=SC1090
    . "$RESTIC_ENV"
    set +a
    export RESTIC_CACHE_DIR=/var/cache/homelab-restic
}

# send_summary RUN_DIR HEADLINE : build the summary of a run, send it and remember it.
send_summary() {
    local run_dir="$1" headline="$2" text updated rolled quarantined minutes
    updated="$(awk -F'\t' '{printf "%s %s -> %s; ", $1, substr($3, 8, 12), substr($4, 8, 12)}' "$run_dir/updated.tsv" 2> /dev/null || true)"
    rolled="$(tr '\n' ' ' < "$run_dir/rolled-back.txt" 2> /dev/null || true)"
    quarantined="$(jq -r 'keys | join(" ")' "$QUARANTINE" 2> /dev/null || true)"
    minutes=$((($(date +%s) - $(cat "$run_dir/start-epoch")) / 60))
    text="$headline
Snapshot: $(cat "$run_dir/snapshot-id" 2> /dev/null || echo none)
Debian packages upgraded: $(cat "$run_dir/apt-count" 2> /dev/null || echo 0)
Containers updated: ${updated:-none}
Kernel: $(cat "$run_dir/kernel-before" 2> /dev/null || echo '?') -> $(uname -r)
Rolled back: ${rolled:-none}
Quarantined: ${quarantined:-none}
Duration: $minutes min"
    log "$text"
    notify "$text"
    printf '%s  %s\n' "$(date '+%F %T')" "$headline" > "$LAST_RESULT"
}
