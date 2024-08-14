#!/usr/bin/env bash

set -e

cache() {
    [[ -f "${1}" ]] || return 1
    print " ---> Found in cache: ${1}"
}

error() {
    printf "%b\n" "${*:-}"  1>&2
    exit 1
}

download() {
    print " ---> Downloading: ${1:-}/${2:-}"
    curl "${1:-}/${2:-}" -# -O -f --stderr -
}

mirrorlist() {
    local date="2024/08/03"
    local repository="Server = https://archive.archlinux.org/repos/${date:-}/\$repo/os/\$arch"
    local locale="en_US.UTF-8 UTF-8"
    print " ---> Setting up mirrorlist: /etc/pacman.d/mirrorlist"
    print " ---> ${repository:-}"
    echo "${repository}" > "${2:-}/etc/pacman.d/mirrorlist"
    echo "${locale}" > "${2:-}/etc/locale.gen"
}

print() {
    printf "%b\n" "${*:-}"  2>&1
}

unpack() {
    print " ---> Unpack archive: ${1:-} into path: ${2:-}"
    zstdcat "${1:-}" | tar -xf - -C "${2:-}"
    mkdir -p "${2:-}/etc/pacman.d" ||  error "Failed to create /etc/pacman.d directory"
    mkdir -p "${2:-}/etc/pacman.d/gnupg" || error "Failed to create /etc/pacman.d/gnupg directory"
}

verify() {
    print " ---> Verifying signature"
    gpg --auto-key-retrieve --verify ${1:-} >/dev/null 2>&1 && return 0 || error "Failed to verify: ${1:-}"
}

workdir() {
    print " ---> Setting up workdir: ${1:-}"
    mkdir -p "${1:-}" || error "Failed to create workdir: ${1:-}"
}

main() {
    local mirror="${1:-https://archive.archlinux.org}"
    local latest="2024.08.01"
    local base_url="${mirror}/iso/${latest}"
    local bootstrap="archlinux-bootstrap-x86_64.tar.zst"
    local signature="${bootstrap}.sig"
    local workdir="./bootstrap"

    print " ---> Latest version: ${latest}-x86_64"
    cache "${bootstrap}" || download "${base_url}" "${bootstrap}"
    cache "${signature}" || download "${base_url}" "${signature}"
    verify "${signature}"
    workdir "${workdir}"
    unpack "${bootstrap}" "${workdir}"
    mirrorlist "${latest}" "${workdir}"
}

main

