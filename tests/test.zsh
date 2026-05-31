#!/usr/bin/env zsh

() {
  local -r _line="\e[2m${(r:$COLUMNS::─:)}\e[m"   ; clear   ; echo "$_line"
  echo -n "this is a normal•str"                  | see "$@"; echo "$_line"
  echo -n $'this?→\x00, its %s\nlong•"str"-\a␤\\' | see "$@"; echo "$_line"
  echo -n $'str w \x0 a\nnewline Δ'               | see "$@"; echo "$_line"
  echo -n $'\a\b\e\f\r\n\t\v\'\\'                 | see "$@"; echo "$_line"
  echo $'this isn\'t a \u0014 normal•str'         | see "$@"; echo "$_line"
  echo $'this?→\x00, is a %%s\nlong•"str"-\a␤\\'  | see "$@"; echo "$_line"
  echo $'str w \x0 a\nnew 󰟀 󰘵 󱄖  line'            | see "$@"; echo "$_line"
  echo $'\a\b\e \u0019\f\r\n\t\v\'\\'             | see "$@"; echo "$_line"
  echo $'test\e[31m str\e[m'                      | see "$@"; echo "$_line"
  echo $'test ----   str\e[m'                    | see "$@"; echo "$_line"

  # cat ../resources/control_chars.txt              | see "$@"; echo "$_line"
  # cat $0 | head -n 301 | tail -n $(( LINES - 3 )) | see "$@"; echo "$_line"
  # cat $0                                          | see "$@"; echo "$_line"
}