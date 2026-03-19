#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
JANUS_DIR="$SCRIPT_DIR/opensim/janus-gateway"
LOGFILE="${JANUS_BUILD_LOGFILE:-$SCRIPT_DIR/janus-build-wsl.log}"
INSTALL_DEPS="${JANUS_WSL_INSTALL_DEPS:-1}"

APT_PACKAGES=(
    autoconf
    automake
    build-essential
    git
    libconfig-dev
    libcurl4-openssl-dev
    libglib2.0-dev
    libjansson-dev
    libmicrohttpd-dev
    libnice-dev
    libogg-dev
    libopus-dev
    libsrtp2-dev
    libssl-dev
    libtool
    meson
    ninja-build
    pkg-config
)

if [ ! -f "$JANUS_DIR/configure.ac" ]; then
    echo "FEHLER: Janus-Quellverzeichnis nicht gefunden: $JANUS_DIR" >&2
    exit 1
fi

mkdir -p "$(dirname "$LOGFILE")"
exec > >(tee "$LOGFILE") 2>&1

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "FEHLER: Benoetigtes Linux-Tool fehlt: $1" >&2
        exit 1
    fi
}

normalize_file_to_lf() {
    local file_path="$1"

    if [ -f "$file_path" ]; then
        sed -i 's/\r$//' "$file_path"
    fi
}

normalize_autotools_inputs() {
    normalize_file_to_lf "$JANUS_DIR/autogen.sh"
    normalize_file_to_lf "$JANUS_DIR/configure.ac"
    normalize_file_to_lf "$JANUS_DIR/Makefile.am"
    normalize_file_to_lf "$JANUS_DIR/src/Makefile.am"
    normalize_file_to_lf "$JANUS_DIR/html/Makefile.am"
    normalize_file_to_lf "$JANUS_DIR/docs/Makefile.am"
    normalize_file_to_lf "$JANUS_DIR/janus-gateway.pc.in"
}

purge_build_artifacts() {
    echo "Entferne alte Build-Artefakte aus dem Janus-Baum ..."

    find "$JANUS_DIR" \( -name .libs -o -name _libs -o -name autom4te.cache \) -type d -prune -exec rm -rf {} +

    find "$JANUS_DIR" -type f \( \
        -name '*.o' -o \
        -name '*.lo' -o \
        -name '*.la' -o \
        -name '*.a' -o \
        -name '*.so' -o \
        -name '*.so.*' -o \
        -name '*.exe' -o \
        -name 'version.c' -o \
        -name 'janus' -o \
        -name 'janus-cfgconv' -o \
        -name 'config.status' -o \
        -name 'libtool' -o \
        -name 'stamp-h1' \
    \) -delete

    rm -f \
        "$JANUS_DIR/Makefile" \
        "$JANUS_DIR/src/Makefile" \
        "$JANUS_DIR/html/Makefile" \
        "$JANUS_DIR/docs/Makefile" \
        "$JANUS_DIR/janus-gateway.pc" \
        "$JANUS_DIR/conf/janus.jcfg.sample"
}

ensure_apt_dependencies() {
    if [ "$INSTALL_DEPS" != "1" ]; then
        return
    fi

    if ! command -v apt-get >/dev/null 2>&1; then
        return
    fi

    echo "Installiere Linux-Abhaengigkeiten via apt ..."

    if command -v sudo >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y "${APT_PACKAGES[@]}"
    elif [ "$(id -u)" = "0" ]; then
        apt-get update
        apt-get install -y "${APT_PACKAGES[@]}"
    else
        echo "FEHLER: apt ist verfuegbar, aber weder sudo noch Root-Rechte sind vorhanden." >&2
        exit 1
    fi
}

ensure_pkg_config_modules() {
    local missing_modules=()
    local module

    for module in libmicrohttpd jansson openssl glib-2.0 nice opus ogg libcurl libconfig libsrtp2; do
        if ! pkg-config --exists "$module"; then
            missing_modules+=("$module")
        fi
    done

    if [ "${#missing_modules[@]}" -gt 0 ]; then
        echo "FEHLER: Fehlende pkg-config-Module: ${missing_modules[*]}" >&2
        echo "Pruefe die Linux-Abhaengigkeiten in Janus-Build-WSL.sh oder setze JANUS_WSL_INSTALL_DEPS=1." >&2
        exit 1
    fi
}

require_command bash
require_command sed
require_command tee

ensure_apt_dependencies

require_command autoreconf
require_command make
require_command pkg-config
require_command gcc

ensure_pkg_config_modules

cd "$JANUS_DIR"

echo "============================================================"
echo " Janus Build in WSL2/Linux: $JANUS_DIR"
echo "============================================================"

if [ -f Makefile ]; then
    echo "Bereinige vorhandenen Build ..."
    make clean || true
fi

normalize_autotools_inputs
purge_build_artifacts

echo "Setze Ausfuehrungsrechte fuer autogen.sh ..."
chmod +x "$JANUS_DIR/autogen.sh"

echo "Starte autogen.sh ..."
"$JANUS_DIR/autogen.sh"

if command -v nproc >/dev/null 2>&1; then
    JOBS="$(nproc)"
else
    JOBS=1
fi

echo "Starte configure ..."
./configure

echo "Starte make -j$JOBS ..."
make -j"$JOBS"

echo "Starte make install ..."
if command -v sudo >/dev/null 2>&1; then
    sudo make install
elif [ "$(id -u)" = "0" ]; then
    make install
else
    echo "FEHLER: Fuer make install werden sudo oder Root-Rechte benoetigt." >&2
    exit 1
fi

echo "Janus Build unter WSL2 abgeschlossen."