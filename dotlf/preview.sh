#!/bin/sh
mime_type=$(file --dereference --brief --mime-type "$1")
case "$mime_type" in
    text/* | application/json | application/*+json | application/x-ndjson)
        bat --color=always --paging=never "$1" || true;;
    *zip | *rar) atool --list "$1" || exit 1;;
    *) exiftool "$1";;
esac
