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

  # ——————————————————————————————————————————————————————————— #

  local -ra charsets=( none c unicode caret cdash hex uni-esc named )
  local -A "_${(@)^charsets//-/_}_esc_chars"

  see::get_charset || return $?

  # ——————————————————————————————————————————————————————————— #

  # recreate the esc charset variable name from input
  local -r _charset_name="_${(L)${u_esc_chars//-/_}:-unicode}_esc_chars"
  # then pass that input by name (P) into the
  #  assoc array that's gonna be used for displaying chars
  esc_chars=( "${(@Pkv)_charset_name}" )

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
  if [[ "$1" == test ]] {
  shift

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
  local -ra c_=( '0' x01 x02 x03 x04 x05 x06 a b t n v f r x0E x0F x10 
    x11 x12 x13 x14 x15 x16 x17 x18 x19 x1A e x1C x1D x1E x1F x7F )
  local -a c; local i; for i ("${(@)c_}") c+="\\$i"

  local -ra n1=( {0..31}  -1 ) n7=( {0..31} 127 )

  local -a escs
  local -r input="${(L)1//[-_]}"

  case "$input" {
    ( unicode | named | c ) escs=( "${(@P)input}" ) ;;
    ( none  )               escs=( "${(@)n1/*/?}" ) ;;

    ( caret ) escs=( $( for i ($n1) echo            '^\U'$(( [##16]i+64 )) ) );;
    ( cdash ) escs=( $( for i ($n1) echo          '\C-\U'$(( [##16]i+64 )) ) );;
    ( hex   ) escs=( $( for i ($n7) echo    0x${(l:2::0:)$(( [##16]i   ))} ) );;
    ( u*esc ) escs=( $( for i ($n7) echo '\\u'${(l:2::0:)$(( [##16]i   ))} ) );;
  }

  echo -E "${(@F)escs}"

  return
  }

# ——————————————————————————————————————————————————————————————————————————— #
# ——————————————————————————————————————————————————————————————————————————— #
# ——————————————————————————————————————————————————————————————————————————— #

  # —— none ————————————————————————————————————————————————— #

  _none_esc_chars=()

  # —— unicode —————————————————————————————————————————————— #

  _unicode_esc_chars=(
    [esc_col]="$_unicode_colour"

    [$'\u00']='␀'  [$'\u01']='␁'  [$'\u02']='␂'  [$'\u03']='␃'  [$'\u04']='␄'
    [$'\u05']='␅'  [$'\u06']='␆'  [$'\u07']='␇'  [$'\u08']='␈'  [$'\u09']='␉'
    [$'\u0A']='␤'  [$'\u0B']='␋'  [$'\u0C']='␌'  [$'\u0D']='␍'  [$'\u0E']='␎'
    [$'\u0F']='␏'  [$'\u10']='␐'  [$'\u11']='␑'  [$'\u12']='␒'  [$'\u13']='␓'
    [$'\u14']='␔'  [$'\u15']='␕'  [$'\u16']='␖'  [$'\u17']='␗'  [$'\u18']='␘'
    [$'\u19']='␙'  [$'\u1A']='␚'  [$'\u1B']='␛'  [$'\u1C']='␜'  [$'\u1D']='␝'
    [$'\u1E']='␞'  [$'\u1F']='␟'  [$'\u7F']='␡'
  )

  # —— caret ———————————————————————————————————————————————— #

  _caret_esc_chars=(
    [esc_col]="$_caret_colour"

    [$'\u00']='^@' [$'\u01']='^A' [$'\u02']='^B' [$'\u03']='^C' [$'\u04']='^D'
    [$'\u05']='^E' [$'\u06']='^F' [$'\u07']='^G' [$'\u08']='^H' [$'\u09']='^I'
    [$'\u0A']='^J' [$'\u0B']='^K' [$'\u0C']='^L' [$'\u0D']='^M' [$'\u0E']='^N'
    [$'\u0F']='^O' [$'\u10']='^P' [$'\u11']='^Q' [$'\u12']='^R' [$'\u13']='^S'
    [$'\u14']='^T' [$'\u15']='^U' [$'\u16']='^V' [$'\u17']='^W' [$'\u18']='^X'
    [$'\u19']='^Y' [$'\u1A']='^Z' [$'\u1B']='^[' [$'\u1C']='^\' [$'\u1D']='^]'
    [$'\u1E']='^^' [$'\u1F']='^_' [$'\u7F']='^?'
  )

  # —— c ———————————————————————————————————————————————————— #

  _c_esc_chars=(
    [esc_col]="$_c_style_colour"

    [$'\u00']='\0'   [$'\u01']='\x01' [$'\u02']='\x02' [$'\u03']='\x03'
    [$'\u04']='\x04' [$'\u05']='\x05' [$'\u06']='\x06' [$'\u07']='\a'
    [$'\u08']='\b'   [$'\u09']='\t'   [$'\u0A']='\n'   [$'\u0B']='\v'
    [$'\u0C']='\f'   [$'\u0D']='\r'   [$'\u0E']='\x0E' [$'\u0F']='\x0F'
    [$'\u10']='\x10' [$'\u11']='\x11' [$'\u12']='\x12' [$'\u13']='\x13'
    [$'\u14']='\x14' [$'\u15']='\x15' [$'\u16']='\x16' [$'\u17']='\x17'
    [$'\u18']='\x18' [$'\u19']='\x19' [$'\u1A']='\x1A' [$'\u1B']='\e'
    [$'\u1C']='\x1C' [$'\u1D']='\x1D' [$'\u1E']='\x1E' [$'\u1F']='\x1F'
    [$'\u7F']='\x7F'
  )

  # —— named ———————————————————————————————————————————————— #

  #y)NOTE: there's an issue with this one, in that it's rly difficult to tell
  #y)       where one character stops and another starts.
  #y)      I'll need to see if there's some sort of solution to that
  _named_esc_chars=(
    [esc_col]="$_unicode_colour"  #r)find new colour

    [$'\u00']='NUL' [$'\u01']='SOH' [$'\u02']='STX' [$'\u03']='ETX'
    [$'\u04']='EOT' [$'\u05']='ENQ' [$'\u06']='ACK' [$'\u07']='BEL'
    [$'\u08']='BS'  [$'\u09']='HT'  [$'\u0A']='LF'  [$'\u0B']='VT'
    [$'\u0C']='FF'  [$'\u0D']='CR'  [$'\u0E']='SO'  [$'\u0F']='SI'
    [$'\u10']='DLE' [$'\u11']='DC1' [$'\u12']='DC2' [$'\u13']='DC3'
    [$'\u14']='DC4' [$'\u15']='NAK' [$'\u16']='SYN' [$'\u17']='ETB'
    [$'\u18']='CAN' [$'\u19']='EM'  [$'\u1A']='SUB' [$'\u1B']='ESC'
    [$'\u1C']='FS'  [$'\u1D']='GS'  [$'\u1E']='RS'  [$'\u1F']='US'
    [$'\u7F']='DEL'
  )

  # ————————————————————————————————————————————————————————————————————————— #

  # —— cdash ———————————————————————————————————————————————— #

  _cdash_esc_chars=(
    [esc_col]="$_caret_colour"  #r)find new colour

    [$'\u00']='\C-@' [$'\u01']='\C-A' [$'\u02']='\C-B' [$'\u03']='\C-C'
    [$'\u04']='\C-D' [$'\u05']='\C-E' [$'\u06']='\C-F' [$'\u07']='\C-G'
    [$'\u08']='\C-H' [$'\u09']='\C-I' [$'\u0A']='\C-J' [$'\u0B']='\C-K'
    [$'\u0C']='\C-L' [$'\u0D']='\C-M' [$'\u0E']='\C-N' [$'\u0F']='\C-O'
    [$'\u10']='\C-P' [$'\u11']='\C-Q' [$'\u12']='\C-R' [$'\u13']='\C-S'
    [$'\u14']='\C-T' [$'\u15']='\C-U' [$'\u16']='\C-V' [$'\u17']='\C-W'
    [$'\u18']='\C-X' [$'\u19']='\C-Y' [$'\u1A']='\C-Z' [$'\u1B']='\C-['
    [$'\u1C']='\C-\' [$'\u1D']='\C-]' [$'\u1E']='\C-^' [$'\u1F']='\C-_'
    [$'\u7F']='\C-?'
  )

  # —— hex —————————————————————————————————————————————————— #

  _hex_esc_chars=(
    [esc_col]="$_unicode_colour"  #r)find new colour

    [$'\u00']='0x00' [$'\u01']='0x01' [$'\u02']='0x02' [$'\u03']='0x03'
    [$'\u04']='0x04' [$'\u05']='0x05' [$'\u06']='0x06' [$'\u07']='0x07'
    [$'\u08']='0x08' [$'\u09']='0x09' [$'\u0A']='0x0A' [$'\u0B']='0x0B'
    [$'\u0C']='0x0C' [$'\u0D']='0x0D' [$'\u0E']='0x0E' [$'\u0F']='0x0F'
    [$'\u10']='0x10' [$'\u11']='0x11' [$'\u12']='0x12' [$'\u13']='0x13'
    [$'\u14']='0x14' [$'\u15']='0x15' [$'\u16']='0x16' [$'\u17']='0x17'
    [$'\u18']='0x18' [$'\u19']='0x19' [$'\u1A']='0x1A' [$'\u1B']='0x1B'
    [$'\u1C']='0x1C' [$'\u1D']='0x1D' [$'\u1E']='0x1E' [$'\u1F']='0x1F'
    [$'\u7F']='0x7F'
  )

  # —— unicode escape ——————————————————————————————————————— #

  _uni_esc_esc_chars=(
    [esc_col]="$_c_style_colour"  #r)find new colour

    [$'\u00']='\u00' [$'\u01']='\u01' [$'\u02']='\u02' [$'\u03']='\u03'
    [$'\u04']='\u04' [$'\u05']='\u05' [$'\u06']='\u06' [$'\u07']='\u07'
    [$'\u08']='\u08' [$'\u09']='\u09' [$'\u0A']='\u0A' [$'\u0B']='\u0B'
    [$'\u0C']='\u0C' [$'\u0D']='\u0D' [$'\u0E']='\u0E' [$'\u0F']='\u0F'
    [$'\u10']='\u10' [$'\u11']='\u11' [$'\u12']='\u12' [$'\u13']='\u13'
    [$'\u14']='\u14' [$'\u15']='\u15' [$'\u16']='\u16' [$'\u17']='\u17'
    [$'\u18']='\u18' [$'\u19']='\u19' [$'\u1A']='\u1A' [$'\u1B']='\u1B'
    [$'\u1C']='\u1C' [$'\u1D']='\u1D' [$'\u1E']='\u1E' [$'\u1F']='\u1F'
    [$'\u7F']='\u7F'
  )

  # ————————————————————————————————————————————————————————————————————————— #
}
