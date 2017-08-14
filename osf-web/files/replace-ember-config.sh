#!/usr/bin/env sh

###
# usage: replace-ember-config.sh /path/to/config.json
###

if [ ! -e $1 ]; then
    echo "$1 does not exist."
    exit 1
fi

# https://gist.github.com/cdown/1163649
urlencode() {
    # urlencode <string>
    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C

    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done

    LC_COLLATE=$old_lc_collate
}

encoded=$(urlencode "$(<${1})")

sed -i .bak 's/\(meta name=".*\/config\/environment" content="\)\(.*\)\("\)/\1'"${encoded}"'\3/' /code/dist/index.html
