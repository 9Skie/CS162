#!/usr/bin/env bash
# Run from anywhere: bash /path/to/this/cs162.sh
# Optional command: bash cs162.sh make
set -euo pipefail

cs162_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
cs162_image="cs162-hw0:amd64"
cs162_container="cs162-study"

if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is not installed or is not on your PATH. Install Docker Desktop first." >&2
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    if [[ "$(uname -s)" != Darwin ]]; then
        echo "Start Docker, then run this script again." >&2
        exit 1
    fi
    echo "Starting Docker Desktop..." >&2
    open -a Docker
    for ((cs162_wait = 0; cs162_wait < 60; cs162_wait++)); do
        if docker info >/dev/null 2>&1; then break; fi
        sleep 2
    done
    if ! docker info >/dev/null 2>&1; then
        echo "Docker is not ready yet. Finish any Docker Desktop prompts, then try again." >&2
        exit 1
    fi
fi

if ! docker container inspect "$cs162_container" >/dev/null 2>&1; then
    if ! docker image inspect "$cs162_image" >/dev/null 2>&1; then
        echo "Preparing the Linux compiler image (first run only)..." >&2
        docker build --platform linux/amd64 -t "$cs162_image" - <<'DOCKERFILE'
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y --no-install-recommends build-essential && rm -rf /var/lib/apt/lists/*
WORKDIR /work
DOCKERFILE
    fi
    docker run -d --init --platform linux/amd64 \
        --name "$cs162_container" \
        --label "cs162.workspace=$cs162_root" \
        --mount "type=bind,source=$cs162_root,target=/work" \
        -w /work "$cs162_image" sleep infinity >/dev/null
fi

# Never reuse an unrelated container or silently mount an old course location.
cs162_mounted="$(docker inspect --format '{{index .Config.Labels "cs162.workspace"}}' "$cs162_container")"
if [[ "$cs162_mounted" != "$cs162_root" ]]; then
    echo "The container '$cs162_container' belongs to a different folder: $cs162_mounted" >&2
    echo "Change cs162_container in this script to an unused name, then run it again." >&2
    exit 1
fi
if [[ "$(docker inspect --format '{{.State.Running}}' "$cs162_container")" != true ]]; then
    docker start "$cs162_container" >/dev/null
fi

# Preserve your current subfolder when launching from inside the course folder.
cs162_here="$(pwd -P)"
cs162_workdir=/work
case "$cs162_here" in
    "$cs162_root"/*) cs162_workdir="/work${cs162_here#"$cs162_root"}" ;;
esac
cs162_terminal=(-i)
if [[ -t 0 && -t 1 ]]; then cs162_terminal+=(-t); fi
if [[ $# -eq 0 ]]; then
    echo "CS162 Linux: the full course folder is at /work. Type exit to leave." >&2
    set -- bash
fi
exec docker exec "${cs162_terminal[@]}" -w "$cs162_workdir" "$cs162_container" "$@"
