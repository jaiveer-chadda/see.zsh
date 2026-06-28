#!/usr/bin/env zsh

function see::make_charset () {

  # —— Decide Whether to do Colours ——————————————————————————— #

  case "$u_do_colours" {
    ( always | [y1] ) do_colours=1 ;;
    ( never  | [n0] ) do_colours=0 ;;
    # if stdout (`1`) is writing to a tty (`-t`) and `$NO_COLOUR` is unset
    #  i.e. if the output isn't being being piped
    ( *auto* | [a-] ) if [[ -t 1 && -z "$NO_COLOR" ]] do_colours=1 ;;
    ( * ) see::error colour; return 1 ;;
  }

  # —— Get Base Charset ——————————————————————————————————————— #

  see::get_charset || return $?

  # —— Set Colours & Special Chars —————————————————————————— #

  local -r NL=$'\n' DLET=$'\x7F'
  local -rA custom_chars=(
    [$DLET]=$'⇉ \e[1;30;41m' #  ␛41m
    [$'\b']=$'⇇ \e[1;30;41m' #  ␛41m
    [$'\f']=$'⇟ \e[1;30;43m' #  ␛43m
    [$'\a']=$'🯺 \e[1;30;42m' #  ␛42m
    [''' ']=$'· \e[38;5;26m' #  #06D
    [$'\e']=$'  \e[48;5;26m' #  #06D
    [$'\t']=$'⇥ \e[48;5;18m' #  #008
    [$'\v']=$'⤓ \e[48;5;18m' #  #008
    [$'\0']=$'  \e[1;7m'     #  ␛07m
    [$'\n']=$'↩ \e[33m'      #  ␛33m
    [$'\r']=$'⏎ \e[33m'      #  ␛33m
  )

  if (( do_colours )) reset=$'\e[m' unprintable=$'\e[36m'

  local char val repr colour
  for char in "${(@k)esc_chars}" "${(@k)custom_chars}" ; {
    val="$custom_chars[$char]"

    if (( do_colours )) colour="${${val##* }:-$esc_col}"
    repr="${${${val% *}# }:-$esc_chars[$char]}"

    esc_chars[$char]="$colour$repr$reset"
  }

  # ———————————————————————————————————————— #

  # Text mode needs an newline for legibility
  #  Although, this newline won't be shown if it's the last char of the file,
  #  or if `$u_show_nl` is unset
  if [[ "$u_mode" == 'text' ]] && (( u_show_nl )) esc_chars[$NL]+="$NL"
}

# ——————————————————————————————————————————————————————————————————————————— #

function see::get_charset () {
  local input
  if   [[ -n "$u_esc_chars" ]] { input="$u_esc_chars"; } \
  elif [[ ! -t 1            ]] { input='C'           ; } \
  else                         { input='unicode'     ; }

  input="${${(L)input}//[-_ ]}"

  # ——————————————————————————————————————————————————————————— #

  if (( do_colours )) {
    local -r unicode=$'\e[1;48;5;88;97m'    # bg #940000  fg #DFE7FF
    local -r c_style=$'\e[1;48;5;236;38;5;33m'   #303030     #008BFF
    local -r   caret=$'\e[1;48;5;18;38;5;226m'   #00008D     #FEFF00

    local -rA colours=(
    [unicode]="$unicode"  [caret]="$caret"  [uniesc]="$c_style"
      [named]="$unicode"  [cdash]="$caret"       [c]="$c_style"
       [none]="$unicode"
        [hex]="$unicode"
    )

    esc_col="$colours[$input]"
  }

  # ——————————————————————————————————————————————————————————— #

  local -ra unicode=(
    ␀ ␁ ␂ ␃ ␄ ␅ ␆ ␇ ␈ ␉ ␤ ␋ ␌ ␍ ␎ ␏ ␐ ␑ ␒ ␓ ␔ ␕ ␖ ␗ ␘ ␙ ␚ ␛ ␜ ␝ ␞ ␟ ␡ )
  local -ra named=( NUL SOH STX ETX EOT ENQ ACK BEL BS HT LF VT FF CR SO
    SI DLE DC1 DC2 DC3 DC4 NAK SYN ETB CAN EM SUB ESC FS GS RS US DEL )
  local -ra c=( \\0 \\1 \\2 \\3 \\4 \\5 \\6 \\a \\b \\t \\n \\v \\f \\r
    \\x0E \\x0F \\x10 \\x11 \\x12 \\x13 \\x14 \\x15 \\x16 \\x17 \\x18 \\x19
    \\x1A  \\e  \\x1C \\x1D \\x1E \\x1F \\x7F
  )

  local -ra n1=( {0..31} -1 ) n7=( {0..31} 127 )

  # ———————————————————————————————————————— #

  local  -a ctrl_chars
  printf -v ctrl_chars '\\x%2x' "${(@)n7}"
  printf -v ctrl_chars '%b'     "${(@)ctrl_chars}"

  # ———————————————————————————————————————— #

  local -a escs; local -i 10 i

  case "$input" {
    ( named | unicode | c ) escs=( "${(@P)input}" ) ;;
    ( none  )               escs=( "${(@)n1/*/?}" ) ;;

    ( caret ) escs=($( for i ($n1) echo            '^\U'$(( [##16]i+64 )) )) ;;
    ( cdash ) escs=($( for i ($n1) echo          '\C-\U'$(( [##16]i+64 )) )) ;;
    ( hex   ) escs=($( for i ($n7) echo    0x${(l:2::0:)$(( [##16]i   ))} )) ;;
    ( *esc* ) escs=($( for i ($n7) echo '\\u'${(l:2::0:)$(( [##16]i   ))} )) ;;

    (   *   ) see::error charset; return 1 ;;
  }

  # ——————————————————————————————————————————————————————————— #

  esc_chars=( "${(@)ctrl_chars:^escs}" )
}

# ——————————————————————————————————————————————————————————————————————————— #
