#!/usr/bin/env zsh

function see::make_charset () {

  # —— Decide Whether to do Colours ——————————————————————————— #

  case "$u_do_colours" {
    # if stdout (`1`) is writing to a tty (`-t`) and `$NO_COLOUR` is unset
    #  i.e. if the output isn't being being piped
    ( always | [y1] ) do_colours=1 ;;
    ( never  | [n0] ) do_colours=0 ;;
    ( *auto* | [a-] ) if [[ -t 1 && -z "$NO_COLOR" ]] do_colours=1 ;;

    ( * ) >&2 {
      echo -n "$funcstack[2]: unsupported colour value '$u_do_colours' "
      echo '(must be always, *auto*, or never)'
      return 1
    } ;;
  }

  # —— Get Base Charset ——————————————————————————————————————— #

  see::get_charset || return $?

  # —— Set Colours & Special Chars —————————————————————————— #

  if (( do_colours )) reset=$'\e[m'

  # ———————————————————————————————————————— #


  local -r NL=$'\n' CR=$'\r' NU=$'\0' SP=' '
  local -rA custom_chars=(
    [$SP]=$'· \e[0;38;5;26m' # ~␛34m
    [$NU]=$'  \e[0;1;7m'     #  ␛7m
    [$NL]=$'↩ \e[0;33m'      #  ␛33m
    [$CR]=$'  \e[0;33m'      #  ␛33m
  )

  local char val repr colour
  for char in "${(@k)esc_chars}" "${(@k)custom_chars}" ; {
    val="$custom_chars[$char]"

    if (( do_colours )) colour="${${val##* }:-$esc_col}"
    repr="${${${val% *}# }:-$esc_chars[$char]}"

    esc_chars[$char]="$colour$repr$reset"
  }

  # ———————————————————————————————————————— #

  # Text mode needs an newline for legibility
  #  Although, this newline won't be shown if it's the last char of the file
  if [[ "$u_mode" == 'text' ]] esc_chars[$NL]+="$NL"
}

# ——————————————————————————————————————————————————————————————————————————— #

function see::get_charset () {

  local -r input="${${(L)u_esc_chars:-unicode}//[-_]}"

  # ——————————————————————————————————————————————————————————— #

  if (( do_colours )) {
    local -r unicode=$'\e[1;48;5;88;97m'    # bg #940000  fg #DFE7FF
    local -r c_style=$'\e[1;48;5;236;38;5;33m'   #303030     #008BFF
    local -r   caret=$'\e[1;48;5;18;38;5;226m'   #00008D     #FEFF00

    local -rA colours=(
    [unicode]="$unicode"  [named]="$unicode" [none]="$unicode" [hex]="$unicode"
      [caret]="$caret"    [cdash]="$caret"
    [uniesc]="$c_style"      [c]="$c_style"
    )

    esc_col="$colours[$input]"
  }

  # ——————————————————————————————————————————————————————————— #

  local -ra unicode=(
    ␀ ␁ ␂ ␃ ␄ ␅ ␆ ␇ ␈ ␉ ␤ ␋ ␌ ␍ ␎ ␏ ␐ ␑ ␒ ␓ ␔ ␕ ␖ ␗ ␘ ␙ ␚ ␛ ␜ ␝ ␞ ␟ ␡ )
  local -ra named=( NUL SOH STX ETX EOT ENQ ACK BEL BS HT LF VT FF CR SO
    SI DLE DC1 DC2 DC3 DC4 NAK SYN ETB CAN EM SUB ESC FS GS RS US DEL )
  local -ra c=( \\0 \\x01 \\x02 \\x03 \\x04 \\x05 \\x06 \\a \\b \\t
    \\n \\v \\f \\r \\x0E \\x0F \\x10 \\x11 \\x12 \\x13 \\x14 \\x15
    \\x16 \\x17 \\x18 \\x19 \\x1A \\e \\x1C \\x1D \\x1E \\x1F \\x7F
  )

  local -ra n1=( {0..31} -1 ) n7=( {0..31} 127 )

  # ———————————————————————————————————————— #

  local  -a ctrl_chars
  printf -v ctrl_chars '\\x%2x' "${(@)n7}"
  printf -v ctrl_chars '%b'     "${(@)ctrl_chars}"

  # ———————————————————————————————————————— #

  local -a escs; local -i 10 i

  case "$input" {
    ( unicode | named | c ) escs=( "${(@P)input}" ) ;;
    ( none  )               escs=( "${(@)n1/*/?}" ) ;;

    ( caret ) escs=($( for i ($n1) echo            '^\U'$(( [##16]i+64 )) )) ;;
    ( cdash ) escs=($( for i ($n1) echo          '\C-\U'$(( [##16]i+64 )) )) ;;
    ( hex   ) escs=($( for i ($n7) echo    0x${(l:2::0:)$(( [##16]i   ))} )) ;;
    ( u*esc ) escs=($( for i ($n7) echo '\\u'${(l:2::0:)$(( [##16]i   ))} )) ;;
  }

  # ——————————————————————————————————————————————————————————— #

  esc_chars=( "${(@)ctrl_chars:^escs}" )
}

# ——————————————————————————————————————————————————————————————————————————— #
