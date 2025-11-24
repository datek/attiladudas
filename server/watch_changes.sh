#!/bin/bash

set -eou pipefail

while read -r filename < <(inotifywait --format "%w%f" -e modify -e create -e delete -r ./lib ./test); do
    echo "$filename has changed"
    mix format "$filename" || true
    mix compile || true
done
