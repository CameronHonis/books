#!/bin/bash

TEMP=$(getopt -o 'p:t' --long 'port:,tmux' -- "$@")
if [ $? -ne 0 ]; then
    echo "Error parsing arguments" >&2
    exit 1
fi

eval set -- "$TEMP"
unset TEMP

PORT=8888
IN_TMUX=false
while true; do
    case "$1" in
    '-p' | '--port')
        PORT="$2"
        shift 2
        ;;
    '-t' | '--tmux')
        IN_TMUX=true
        shift
        ;;
    '--')
        shift
        break
        ;;
    *)
        echo "Internal error" >&2
        exit 1
        ;;
    esac
done

port_check() {
    local p=$1
    if command -v ss &>/dev/null; then
        ss -tln | grep -q ":$p "
    elif command -v netstat &>/dev/null; then
        netstat -tln | grep -q ":$p "
    else
        python3 -c "import socket; s=socket.socket(); s.bind(('',$p))" 2>/dev/null
    fi
}

ORIGINAL_PORT=$PORT
ATTEMPTS=0
while port_check $PORT; do
    if [ $ATTEMPTS -ge 10 ]; then
        echo "Error: port $ORIGINAL_PORT to $((ORIGINAL_PORT + ATTEMPTS)) are all in use" >&2
        exit 1
    fi
    echo "port $PORT in use, trying $((PORT + 1))"
    PORT=$((PORT + 1))
    ATTEMPTS=$((ATTEMPTS + 1))
done

set -m

# do tmux redirect here, passing all original args to the tmux process
if [ "$IN_TMUX" = true ]; then
    if [ -z "$TMUX" ]; then
        exec tmux new-session -s "books-server-$PORT" "$0 $@"
        exit 0
    else
        echo "Already in a tmux session"
    fi
fi

echo "using port $PORT"

cd "$(dirname "$0")"

if [ ! -f "pdf.js/package.json" ]; then
    git submodule update --init --recursive
fi

cp -r books pdf.js/books

cd pdf.js

npm install >/dev/null

npx gulp server --port $PORT &

open "http://localhost:${PORT}/books" >/dev/null

fg
