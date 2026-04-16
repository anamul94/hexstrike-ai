#!/bin/bash
set -eu

MODE="${1:-server}"

if [ "$#" -gt 0 ]; then
    shift
fi

case "$MODE" in
    server)
        exec python hexstrike_server.py --port "${HEXSTRIKE_PORT:-8888}" "$@"
        ;;
    mcp)
        exec python hexstrike_mcp.py --server "${HEXSTRIKE_SERVER:-http://127.0.0.1:${HEXSTRIKE_PORT:-8888}}" "$@"
        ;;
    *)
        exec "$MODE" "$@"
        ;;
esac
