#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
DR_CH4_DOG_MOD_DIR="${DR_CH4_DOG_MOD_DIR:-$SCRIPT_DIR}"
DR_CH4_DOG_MOD_DIR="$(CDPATH= cd -- "$DR_CH4_DOG_MOD_DIR" && pwd -P)"
DR_CH4_DOG_BUILD_ROOT="${DR_CH4_DOG_BUILD_ROOT:-$DR_CH4_DOG_MOD_DIR/.build/standalone}"
DR_CH4_DOG_OUTPUT_DIR="${DR_CH4_DOG_OUTPUT_DIR:-$DR_CH4_DOG_MOD_DIR/dist}"
DR_CH4_DOG_CACHE_DIR="${DR_CH4_DOG_CACHE_DIR:-$DR_CH4_DOG_MOD_DIR/.build/cache}"

DR_CH4_DOG_KRISTAL_REPO="${DR_CH4_DOG_KRISTAL_REPO:-https://github.com/KristalTeam/Kristal.git}"
DR_CH4_DOG_KRISTAL_REF="${DR_CH4_DOG_KRISTAL_REF:-v0.10.0}"
DR_CH4_DOG_KRISTAL_EXPECTED_VERSION="${DR_CH4_DOG_KRISTAL_EXPECTED_VERSION:-0.10.0}"
DR_CH4_DOG_KRISTAL_DIR="${DR_CH4_DOG_KRISTAL_DIR:-${KRISTAL_ROOT:-$DR_CH4_DOG_MOD_DIR/.build/Kristal}}"

DR_CH4_DOG_MOD_ID="${DR_CH4_DOG_MOD_ID:-dr-ch4-dog}"
DR_CH4_DOG_PROJECT_TITLE="${DR_CH4_DOG_PROJECT_TITLE:-dr-ch4-dog}"
DR_CH4_DOG_OUTPUT_BASENAME="${DR_CH4_DOG_OUTPUT_BASENAME:-dr-ch4-dog}"
DR_CH4_DOG_EXE_BASENAME="${DR_CH4_DOG_EXE_BASENAME:-DR-CH4-DOG}"
DR_CH4_DOG_LOVE_VERSION="${DR_CH4_DOG_LOVE_VERSION:-11.5}"
DR_CH4_DOG_LOVE_ARCH="${DR_CH4_DOG_LOVE_ARCH:-win64}"
DR_CH4_DOG_LOVE_WINDOWS_ZIP_URL="${DR_CH4_DOG_LOVE_WINDOWS_ZIP_URL:-https://github.com/love2d/love/releases/download/${DR_CH4_DOG_LOVE_VERSION}/love-${DR_CH4_DOG_LOVE_VERSION}-${DR_CH4_DOG_LOVE_ARCH}.zip}"
DR_CH4_DOG_BUILD_VARIANTS="${DR_CH4_DOG_BUILD_VARIANTS:-release debug}"
DR_CH4_DOG_BUILD_WINDOWS_EXE="${DR_CH4_DOG_BUILD_WINDOWS_EXE:-1}"
DR_CH4_DOG_UPDATE_REPOS="${DR_CH4_DOG_UPDATE_REPOS:-0}"

log() {
    printf '[build] %s\n' "$*" >&2
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        printf 'Missing required command: %s\n' "$1" >&2
        exit 1
    }
}

ensure_kristal() {
    if [ -d "$DR_CH4_DOG_KRISTAL_DIR/.git" ]; then
        if [ "$DR_CH4_DOG_UPDATE_REPOS" = "1" ]; then
            git -C "$DR_CH4_DOG_KRISTAL_DIR" fetch --tags origin
        fi
    elif [ -e "$DR_CH4_DOG_KRISTAL_DIR" ]; then
        printf 'Kristal path exists but is not a Git checkout: %s\n' "$DR_CH4_DOG_KRISTAL_DIR" >&2
        exit 1
    else
        mkdir -p "$(dirname "$DR_CH4_DOG_KRISTAL_DIR")"
        git clone --filter=blob:none "$DR_CH4_DOG_KRISTAL_REPO" "$DR_CH4_DOG_KRISTAL_DIR"
    fi

    if ! git -C "$DR_CH4_DOG_KRISTAL_DIR" rev-parse --verify --quiet "${DR_CH4_DOG_KRISTAL_REF}^{commit}" >/dev/null; then
        git -C "$DR_CH4_DOG_KRISTAL_DIR" fetch --depth 1 origin "refs/tags/${DR_CH4_DOG_KRISTAL_REF}:refs/tags/${DR_CH4_DOG_KRISTAL_REF}"
    fi

    version="$(git -C "$DR_CH4_DOG_KRISTAL_DIR" show "${DR_CH4_DOG_KRISTAL_REF}:VERSION" | tr -d '\r\n')"
    if [ "$version" != "$DR_CH4_DOG_KRISTAL_EXPECTED_VERSION" ]; then
        printf 'Kristal %s reports VERSION=%s, expected %s\n' "$DR_CH4_DOG_KRISTAL_REF" "$version" "$DR_CH4_DOG_KRISTAL_EXPECTED_VERSION" >&2
        exit 1
    fi
}

export_kristal() {
    stage_dir="$1"
    rm -rf "$stage_dir"
    mkdir -p "$stage_dir"
    git -C "$DR_CH4_DOG_KRISTAL_DIR" archive --format=tar "$DR_CH4_DOG_KRISTAL_REF" | tar -x -C "$stage_dir"
    rm -rf "$stage_dir/.github" "$stage_dir/mods" "$stage_dir/build" "$stage_dir/output"
}

copy_mod() {
    stage_mod="$1"
    variant="$2"
    mkdir -p "$stage_mod"
    rsync -a \
        --exclude='/.git/' \
        --exclude='.git' \
        --exclude='/.github/' \
        --exclude='/.build/' \
        --exclude='/dist/' \
        --exclude='/.emacs/' \
        --exclude='/.helix/' \
        --exclude='/.vscode/' \
        --exclude='/.worktrees/' \
        --exclude='/tests/' \
        --exclude='/docs/' \
        --exclude='/Makefile' \
        --exclude='/justfile' \
        --exclude='/build_standalone.sh' \
        --exclude='/build_standalone.py' \
        --exclude='/release-please-config.json' \
        --exclude='/.release-please-manifest.json' \
        --exclude='/.gitmodules' \
        --exclude='/.gitignore' \
        --exclude='*.tiled-project' \
        --exclude='*.tiled-session' \
        "$DR_CH4_DOG_MOD_DIR/" "$stage_mod/"

    if [ "$variant" = "release" ]; then
        rm -rf "$stage_mod/libraries/kristal-object-selector-plus"
        rm -rf "$stage_mod/libraries/terminal-cli"
        rm -rf "$stage_mod/libraries/kristal-debug-tools"
    fi
}

zip_dir() {
    output="$1"
    source="$2"
    prefix="${3:-}"
    mkdir -p "$(dirname "$output")"
    rm -f "$output"
    if command -v zip >/dev/null 2>&1; then
        if [ -n "$prefix" ]; then
            (cd "$(dirname "$source")" && zip -9 -q -r "$output" "$(basename "$source")")
        else
            (cd "$source" && zip -9 -q -r "$output" .)
        fi
    else
        python3 "$DR_CH4_DOG_MOD_DIR/build_standalone.py" zip-dir "$output" "$source" "$prefix"
    fi
}

prepare_stage() {
    variant="$1"
    case "$variant" in
        release)
            release_mode=true
            mod_dev=false
            object_editor=false
            ;;
        debug)
            release_mode=false
            mod_dev=true
            object_editor=true
            ;;
        *)
            printf 'Unknown build variant: %s\n' "$variant" >&2
            exit 1
            ;;
    esac

    stage_dir="$DR_CH4_DOG_BUILD_ROOT/$variant/source"
    export_kristal "$stage_dir"
    stage_mod="$stage_dir/mods/$DR_CH4_DOG_MOD_ID"
    copy_mod "$stage_mod" "$variant"
    if [ "$variant" = "release" ]; then
        identity="$DR_CH4_DOG_MOD_ID"
        title="$DR_CH4_DOG_PROJECT_TITLE"
    else
        identity="${DR_CH4_DOG_MOD_ID}_debug"
        title="${DR_CH4_DOG_PROJECT_TITLE} Debug"
    fi
    python3 "$DR_CH4_DOG_MOD_DIR/build_standalone.py" patch-lua-config \
        "$stage_dir" "$DR_CH4_DOG_MOD_ID" "$release_mode" \
        "$identity" "$title"
    python3 "$DR_CH4_DOG_MOD_DIR/build_standalone.py" patch-mod-manifest \
        "$stage_mod/mod.json" "$mod_dev" "$object_editor"
    printf '%s\n' "$stage_dir"
}

ensure_love_windows() {
    [ "$DR_CH4_DOG_BUILD_WINDOWS_EXE" = "1" ] || return 0
    mkdir -p "$DR_CH4_DOG_CACHE_DIR"
    love_zip="$DR_CH4_DOG_CACHE_DIR/love-${DR_CH4_DOG_LOVE_VERSION}-${DR_CH4_DOG_LOVE_ARCH}.zip"
    love_dir="$DR_CH4_DOG_CACHE_DIR/love-${DR_CH4_DOG_LOVE_VERSION}-${DR_CH4_DOG_LOVE_ARCH}"
    if [ ! -f "$love_zip" ]; then
        curl --fail --location --output "$love_zip" "$DR_CH4_DOG_LOVE_WINDOWS_ZIP_URL"
    fi
    if [ ! -d "$love_dir" ]; then
        extract_dir="$DR_CH4_DOG_CACHE_DIR/love-${DR_CH4_DOG_LOVE_VERSION}-${DR_CH4_DOG_LOVE_ARCH}.extract"
        rm -rf "$extract_dir"
        mkdir -p "$extract_dir"
        unzip -q "$love_zip" -d "$extract_dir"
        extracted="$(find "$extract_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
        [ -n "$extracted" ] || {
            printf 'Could not locate the extracted LÖVE directory\n' >&2
            exit 1
        }
        mv "$extracted" "$love_dir"
        rm -rf "$extract_dir"
    fi
    test -f "$love_dir/love.exe"
}

build_variant() {
    variant="$1"
    stage_dir="$(prepare_stage "$variant")"
    love_file="$DR_CH4_DOG_OUTPUT_DIR/${DR_CH4_DOG_OUTPUT_BASENAME}-${variant}.love"
    zip_dir "$love_file" "$stage_dir"

    if [ "$DR_CH4_DOG_BUILD_WINDOWS_EXE" = "1" ]; then
        love_dir="$DR_CH4_DOG_CACHE_DIR/love-${DR_CH4_DOG_LOVE_VERSION}-${DR_CH4_DOG_LOVE_ARCH}"
        package_name="${DR_CH4_DOG_OUTPUT_BASENAME}-${variant}-${DR_CH4_DOG_LOVE_ARCH}"
        package_dir="$DR_CH4_DOG_OUTPUT_DIR/$package_name"
        exe_name="${DR_CH4_DOG_EXE_BASENAME}-${variant}.exe"
        rm -rf "$package_dir"
        mkdir -p "$package_dir"
        cat "$love_dir/love.exe" "$love_file" > "$package_dir/$exe_name"
        cp "$love_dir"/*.dll "$package_dir/"
        test ! -f "$love_dir/license.txt" || cp "$love_dir/license.txt" "$package_dir/"
        zip_dir "$DR_CH4_DOG_OUTPUT_DIR/${package_name}.zip" "$package_dir" "$package_name"
    fi
}

need_cmd git
need_cmd python3
need_cmd rsync
need_cmd tar
need_cmd unzip
need_cmd curl
need_cmd zip
ensure_kristal
mkdir -p "$DR_CH4_DOG_OUTPUT_DIR"
ensure_love_windows
for variant in $DR_CH4_DOG_BUILD_VARIANTS; do
    build_variant "$variant"
done
