#!/bin/sh

###
# usage: replace-ember-config.sh /path/to/config.json /path/to/index.html
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

    for i in $(seq 1 ${#1}); do
        local c=$(echo $1 | head -c $i | tail -c 1)
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done

    LC_COLLATE=$old_lc_collate
}

encoded=$(urlencode "$(cat ${1})")

sed -i 's/\(meta name=".*\/config\/environment" content="\)\(.*\)\("\)/\1'"${encoded}"'\3/' $2
