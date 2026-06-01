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

  # —— Create Base Charset ———————————————————————————————————— #

  see::get_charset || return $?

  # —— Set Colours & Special Chars —————————————————————————— #

  local -r _NL=$'\n' _CR=$'\r' _NUL=$'\0' _SP=' '

  esc_chars[$_SP]="$_SP_char"

  if (( do_colours )) {
    esc_col="$esc_chars[esc_col]"
    reset="$_reset"
    # You have to pass the space and newline in as variables, otherwise
    #  zsh can't process the keys
    esc_chars[$_SP]="$_SP_colour$_SP_char$_reset"
    esc_chars[$_NL]="$_CRLF_colour$esc_chars[$_NL]$_reset"
    esc_chars[$_CR]="$_CRLF_colour$esc_chars[$_CR]$_reset"
    esc_chars[$_NUL]="$_NUL_colour$esc_chars[$_NUL]$_reset"
  }

  # ——————————————————————————————————————————————————————————— #

  # Text mode needs an newline for legibility
  #  Although, this newline won't be shown if it's the last char of the file
  if [[ "$u_mode" == 'text' ]] esc_chars[$_NL]+="$_NL"
}

# ——————————————————————————————————————————————————————————————————————————— #
# ——————————————————————————————————————————————————————————————————————————— #

function see::get_charset () {
  local -ra n1=( {0..31}  -1 ) n7=( {0..31} 127 )

  local -a ctrl_chars
  printf -v ctrl_chars '\\x%2x' "${(@)n7}"
  printf -v ctrl_chars '%b'     "${(@)ctrl_chars}"

  local -rA colours=(
  [unicode]="$_unicode_colour"
    [named]="$_unicode_colour"
     [none]="$_unicode_colour"
      [hex]="$_unicode_colour"
    [caret]="$_caret_colour"
    [cdash]="$_caret_colour"
   [uniesc]="$_c_style_colour"
        [c]="$_c_style_colour"
  )

  local -ra unicode=(
    ␀ ␁ ␂ ␃ ␄ ␅ ␆ ␇ ␈ ␉ ␤ ␋ ␌ ␍ ␎ ␏ ␐ ␑ ␒ ␓ ␔ ␕ ␖ ␗ ␘ ␙ ␚ ␛ ␜ ␝ ␞ ␟ ␡ )
  local -ra named=( NUL SOH STX ETX EOT ENQ ACK BEL BS HT LF VT FF CR SO
    SI DLE DC1 DC2 DC3 DC4 NAK SYN ETB CAN EM SUB ESC FS GS RS US DEL )
  local -ra c=( \\0 \\x01 \\x02 \\x03 \\x04 \\x05 \\x06 \\a \\b \\t
    \\n \\v \\f \\r \\x0E \\x0F \\x10 \\x11 \\x12 \\x13 \\x14 \\x15
    \\x16 \\x17 \\x18 \\x19 \\x1A \\e \\x1C \\x1D \\x1E \\x1F \\x7F
  )

  local -r input="${${(L)u_esc_chars:-unicode}//[-_]}"
  local -a escs; local i

  case "$input" {
    ( unicode | named | c ) escs=( "${(@P)input}" ) ;;
    ( none  )               escs=( "${(@)n1/*/?}" ) ;;

    ( caret ) escs=( $( for i ($n1) echo            '^\U'$(( [##16]i+64 )) ) );;
    ( cdash ) escs=( $( for i ($n1) echo          '\C-\U'$(( [##16]i+64 )) ) );;
    ( hex   ) escs=( $( for i ($n7) echo    0x${(l:2::0:)$(( [##16]i   ))} ) );;
    ( u*esc ) escs=( $( for i ($n7) echo '\\u'${(l:2::0:)$(( [##16]i   ))} ) );;
  }

  esc_chars=(
    esc_col "$colours[$input]"
    "${(@)ctrl_chars:^escs}"
  )
}
