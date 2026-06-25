#!/usr/bin/env zsh

source "$SHD/line-functions/source/line.zsh"
source "${${(%):-%x}:a:h:h}/source/main.zsh"

clear; line -d
echo -n "a test •str" | see    "$@"          ; line -d
echo -n "a test •str" | see -M "$@"          ; line -d
echo -n "a test •str" | xxd -c 18 -R always  ; line -d
echo -n "a test •str" | od -tx1 -c           ; line -d
