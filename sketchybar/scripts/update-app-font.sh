#!/usr/bin/env bash

# Update the vendored sketchybar-app-font files from the newest upstream version tag.

set -o pipefail

readonly UPSTREAM_URL="https://github.com/kvndrsslr/sketchybar-app-font.git"

usage() {
  cat <<'EOF'
Usage: update-app-font.sh [--install]

Update icon_map.lua, the vendored font, its license, and the recorded upstream version.
Pass --install to also copy the updated font into ~/Library/Fonts.
EOF
}

latest_version_tag() {
  git -C "$1" for-each-ref \
    --sort=-version:refname \
    --format='%(refname:short)' \
    'refs/tags/v[0-9]*' | sed -n '1p'
}

prepare_source() {
  local source_dir="$1"

  if [[ ! -e "${source_dir}" ]]; then
    mkdir -p "$(dirname "${source_dir}")" || return 1
    git clone --quiet "${UPSTREAM_URL}" "${source_dir}" || return 1
  elif [[ ! -d "${source_dir}/.git" ]]; then
    printf 'Source path exists but is not a Git repository: %s\n' "${source_dir}" >&2
    return 1
  fi

  if [[ -n "$(git -C "${source_dir}" status --porcelain)" ]]; then
    printf 'Refusing to update dirty source cache: %s\n' "${source_dir}" >&2
    return 1
  fi

  git -C "${source_dir}" fetch --quiet --tags --prune origin
}

copy_release_files() {
  local source_dir="$1"
  local config_dir="$2"

  [[ -f "${source_dir}/dist/icon_map.lua" ]] || return 1
  [[ -f "${source_dir}/dist/sketchybar-app-font.ttf" ]] || return 1
  [[ -f "${source_dir}/LICENSE" ]] || return 1

  cp "${source_dir}/dist/icon_map.lua" "${config_dir}/icon_map.lua" || return 1
  cp \
    "${source_dir}/dist/sketchybar-app-font.ttf" \
    "${config_dir}/assets/sketchybar-app-font.ttf" || return 1
  cp "${source_dir}/LICENSE" "${config_dir}/assets/LICENSE-sketchybar-app-font.txt"
}

write_version() {
  local version_file="$1"
  local tag="$2"
  local commit="$3"

  cat >"${version_file}" <<EOF
UPSTREAM_REPOSITORY=${UPSTREAM_URL}
UPSTREAM_TAG=${tag}
UPSTREAM_COMMIT=${commit}
EOF
}

main() {
  local install_font=false
  local script_dir
  local config_dir
  local dotfiles_dir
  local source_dir
  local tag
  local commit
  local installed_font

  if (( $# > 1 )); then
    usage >&2
    return 2
  fi
  if (( $# == 1 )); then
    case "$1" in
      --install)
        install_font=true
        ;;
      --help|-h)
        usage
        return 0
        ;;
      *)
        usage >&2
        return 2
        ;;
    esac
  fi

  command -v git >/dev/null 2>&1 || return 1
  command -v sed >/dev/null 2>&1 || return 1

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)" || return 1
  config_dir="$(cd "${script_dir}/.." && pwd -P)" || return 1
  dotfiles_dir="$(cd "${config_dir}/.." && pwd -P)" || return 1
  source_dir="${dotfiles_dir}/.src/sketchybar-app-font"

  prepare_source "${source_dir}" || return 1
  tag="$(latest_version_tag "${source_dir}")"
  if [[ -z "${tag}" ]]; then
    printf 'No upstream version tag found.\n' >&2
    return 1
  fi

  git -C "${source_dir}" checkout --quiet --detach "${tag}" || return 1
  commit="$(git -C "${source_dir}" rev-parse HEAD)" || return 1
  copy_release_files "${source_dir}" "${config_dir}" || return 1
  write_version "${config_dir}/assets/sketchybar-app-font.version" "${tag}" "${commit}"

  if [[ "${install_font}" == true ]]; then
    installed_font="${HOME}/Library/Fonts/sketchybar-app-font.ttf"
    mkdir -p "$(dirname "${installed_font}")" || return 1
    cp "${config_dir}/assets/sketchybar-app-font.ttf" "${installed_font}" || return 1
  fi

  printf 'Updated sketchybar-app-font to %s at %s.\n' "${tag}" "${commit}"
  if [[ "${install_font}" == true ]]; then
    printf 'Installed the font at %s. Reload SketchyBar to use it.\n' "${installed_font}"
  fi
}

main "$@"
