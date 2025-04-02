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

cp -r books pdf.js/books

cd pdf.js

npm install >/dev/null

npx gulp server &

xdg-open "http://localhost:${PORT}/books" >/dev/null

fg
