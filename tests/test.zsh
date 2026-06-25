#!/usr/bin/env zsh

source "$SHD/line-functions/source/line.zsh"
source "${${(%):-%x}:a:h:h}/source/main.zsh"

function see::test () {
  clear; line -d

  echo -n "this is a normal•str"                  | see "$@"; line -d
  echo -n $'this?→\x00, its %s\nlong•"str"-\a␤\\' | see "$@"; line -d
  echo -n $'str　w \x0 a\nnewline Δ'               | see "$@"; line -d
  echo -n $'\a\b\e\f\r\n\t\v\x7F\' \\'            | see "$@"; line -d

  echo $'this isn\'t a \u0014 normal•str'         | see "$@"; line -d
  echo $'this?→\x00, is a %%s\nlong•"str"-\a␤\\'  | see "$@"; line -d
  echo $'str w \x0 a\nnew 󰟀 󰘵 󱄖  line'            | see "$@"; line -d
  echo $'\a\b\e \u0019\f\r\n\t\v\'\\'             | see "$@"; line -d
  echo $'test\e[31m str\e[m'                      | see "$@"; line -d
  echo $'test ----   str\e[m'                    | see "$@"; line -d

  # cat ../resources/control_chars.txt              | see "$@"; line -d
  # cat $0 | head -n 301 | tail -n $(( LINES - 3 )) | see "$@"; line -d
  # cat $0                                          | see "$@"; line -d
}

see::test "$@"
