#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 1 ]; then
  printf 'usage: %s MINIMUM_VERSION\n' "$0" >&2
  exit 2
fi

minimum=$1
current=${TMUX_VERSION_OVERRIDE:-$(tmux -V)}
current=${current#tmux }

version_pattern='^([0-9]+)\.([0-9]+)([a-z]*)$'

if [[ $current =~ $version_pattern ]]; then
  current_major=${BASH_REMATCH[1]}
  current_minor=${BASH_REMATCH[2]}
  current_suffix=${BASH_REMATCH[3]}
else
  exit 2
fi

if [[ $minimum =~ $version_pattern ]]; then
  minimum_major=${BASH_REMATCH[1]}
  minimum_minor=${BASH_REMATCH[2]}
  minimum_suffix=${BASH_REMATCH[3]}
else
  exit 2
fi

if ((10#$current_major != 10#$minimum_major)); then
  if ((10#$current_major > 10#$minimum_major)); then
    exit 0
  fi
  exit 1
fi

if ((10#$current_minor != 10#$minimum_minor)); then
  if ((10#$current_minor > 10#$minimum_minor)); then
    exit 0
  fi
  exit 1
fi

[[ $current_suffix == "$minimum_suffix" || $current_suffix > $minimum_suffix ]]
