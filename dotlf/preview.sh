#!/bin/sh
mime_type=$(file --dereference --brief --mime-type "$1")
case "$mime_type" in
    text/*) bat --color=always "$1";;
    *zip | *rar) atool --list "$1" || exit 1;;
    *) exiftool "$1";;
esac
