#!/usr/bin/env zsh

() {
  local -r source="${${(%):-%x}:a:h}"
  source "$source/usage.zsh"
  source "$source/charsets.zsh"
}

function see () {

  # — Set Options —————————————————————————————————————————————————————————— #

  setopt local_options warn_create_global

  # — Constants ———————————————————————————————————————————————————————————— #

  # ~~ Reset(s) ~~
  local -r _reset=$'\e[m'
  local -r _hard_reset=$'\e[!p\e[m'  # see ../notes/hard-reset.note

  # ~~ Escape Character Colours ~~
  local -r     _esc_prefix="$_hard_reset"$'\e[1;38;5;'
  local -r _unicode_colour="${_esc_prefix}231;48;5;088m"
  local -r _c_style_colour="${_esc_prefix}033;48;5;236m"
  local -r   _caret_colour="${_esc_prefix}226;48;5;018m"

  # ~~ Multibyte Colours ~~
  local -r _3B_colour=$'\e[0;1;32m'
  local -r _4B_colour=$'\e[0;1;31m'
  local -r _5B_colour=$'\e[0;1;35m'
  local -r _6B_colour=$'\e[0;1;45m'

  # ~~ Whitespace Colours ~~
  local -r _CRLF_colour=$'\e[0;1;33m'  # $'\e[...;48;5;26m'
  local -r   _SP_colour=$'\e[0;1;38;5;33m'

  # ~~ Whitespace Characters ~~
  local -r _SP_char='·'  # ␣ / · / ␠ / ' ' #y)TODO
  #local-r _NL_char='␤'  # ␤ / ␊ / ↩ / ⏎   #y)TODO

  # ~~ Hex Codes ~~
  local -r _NL_hex_code='a'

  # ~~ All Escape Charsets ~~

  local -ra charsets=( none c unicode caret cdash hex uni-esc )
  local -A "_${(@)^charsets//-/_}_esc_chars"

  see::create_charsets

  # — Take User Input —————————————————————————————————————————————————————— #

  # Note: a 'u_' prefix indicates a user-inputted value
  local u_file=             #y)not implemented yet
  local u_mode='text'       #y)only kinda implemented

  local u_do_colours='auto' # when to show colours
  local u_colours=          #y)not implemented yet
  local u_esc_chars=''      # default is 'unicode', but that's handled below

  local -i 10 u_width=32    # width for column mode (≈ xxd -c)
  local -i 10 u_zero_pad=2  # how many 0s to add before a hex code

  # the leading hyphen here turns on debug info, which I capture and use below
  local opt OPTARG OPTIND
  while { getopts ':f:m:tlc:C:e:w:0:h' opt; } { #
    case "$opt" {
      #### File ####
      ( f ) u_file="$OPTARG"      ;; #r)NOT IMPLEMENTED

      #### Modes ####
      ( m ) u_mode="$OPTARG"      ;; #y)not fully implemented
      ( t ) u_mode='text'         ;;
      ( l ) u_mode='list'         ;;

      #### Graphics ####
      ( c ) u_do_colours="$OPTARG";;
      ( C ) u_colours="$OPTARG"   ;; #r)NOT IMPLEMENTED
      ( e ) u_esc_chars="$OPTARG" ;;

      #### Hex Display ####
      ( w ) u_width="$OPTARG"     ;; #y)no effect yet
      ( 0 ) u_zero_pad="$OPTARG"  ;;

      #### Usage ####
      ( h ) see::usage; return 0  ;;
      ( * ) >&2 {
        echo -nE "$0: bad option: -${(qq)OPTARG}"        # if `$opt` == `?`
        if [[ $opt == : ]] echo -n ' needs an argument'  # if `$opt` == `:`

        echo $'\n'  # one NL to fix the `echo -n`, and one for padding
        see::usage
        return 1
      } ;;
    }
  }
  shift 'OPTIND - 1'

  # —— Decide if to do Colours ————————————————— #

  local -i 2 do_colours=0
  case "$u_do_colours" {
    ( always ) do_colours=1 ;;
    ( never  ) do_colours=0 ;;
    # if stdout (`1`) is writing to a tty (`-t`) and `$NO_COLOUR` is empty
    # i.e. if the output isn't being being piped, then turn colours on
    ( * ) if [[ -t 1 && -z "$NO_COLOR" ]] do_colours=1 ;;
  }

  # —— Create Charset —————————————————————————— #

  # recreate the esc charset variable name from input
  local -r _charset_name="_${(L)${u_esc_chars//-/_}:-unicode}_esc_chars"
  # then pass that input by name (P) into the
  #  assoc array that's gonna be used for displaying chars
  local -A esc_chars=( "${(@Pkv)_charset_name}" )

  # —— Set Colours & Special Chars (SP/NL/CR) —— #

  local -r _NL=$'\n' _CR=$'\r' _SP=' '
  local esc_col= reset=

  esc_chars[$_SP]="$_SP_char"

  if (( do_colours )) {
    esc_col="$esc_chars[esc_col]"
    reset="$_reset"
    # You have to pass the space and newline in as variables, otherwise
    #  zsh can't process the keys
    esc_chars[$_SP]="$_SP_colour$_SP_char$_reset"
    esc_chars[$_NL]="$_CRLF_colour$esc_chars[$_NL]$_reset"
    esc_chars[$_CR]="$_CRLF_colour$esc_chars[$_CR]$_reset"
  }

  # Text mode needs an newline for legibility
  #  Although, this newline won't be shown if it's the last char of the file
  if [[ "$u_mode" == 'text' ]] esc_chars[$_NL]+="$_NL"

  # ————————————————————————————————————————————————————————————————————————— #
  # — Reading from STDIN ———————————————————————————————————————————————————— #

  # read input from stdin, and append a newline to each line
  # note: the `|| [[ -n ...` section allows the last line to be read
  #  if the input doesn't end with a newline
  #y)TODO: change this later so it works when passing a filename in

  local -r input="${$( cat "${@:-/dev/stdin}"; echo 'END' )%END}"

  # ———————————————————————————————————————————————————————————————————————— #
  # — Pre-Processing ——————————————————————————————————————————————————————— #

  # I did this originally to remove the traling newline
  #  added by the `input+=...` line, but idk if/when it's actually needed
  #y)TODO: check if/when it's needed

  # —— Split Input at Codepoints —————————————— #
  # split input at every !!codepoint!!
  #  - i.e. it recognises multi-byte characters
  local -ra chars=( "${(@s::)input}" )

  # —— Convert Chars to Hex ———————————————————— #
  # - take every char and prepend it with a quote: `'`
  # - then use printf to convert each char to hex,
  #   - adding a newline between each hex value
  # - then split the result by newlines (f), and assign it to an array (@)
  local -a hexes=( "${(@f)"$( printf $'%x\n' \'${^chars} )"}" )
  # zip $chars and $hexes together
  local -ra result=( "${(@)chars:^hexes}" )

  # ———————————————————————————————————————————————————————————————————————— #
  # — Outputting Results ——————————————————————————————————————————————————— #

  if (( do_colours )) echo -n "$_hard_reset"  # see ../notes/hard-reset.note

  # Even though this looks like associative array syntax, it's not.
  #  I'm iterating through the zipped chars and hexes arrays, so zsh splits
  #  them for me, hence the separate char and hex variables
  local char hex colour_name
  for char hex in "${(@)result}"; {

    # —— Replace Chars & Print ————————————————— #
    # replace all chars with their special representations, if applicable
    #r)FIX  : the escape colour is always printed, regardless of whether the
    #r)        char being printed will use that colour or not - fix it
    if [[ "${esc_chars[(Ie)$char]}" ]] \
      char="$esc_col$esc_chars[$char]$reset"
    # Note: $esc_col and $reset will have been unset if do_colours is false

    # if the length of the hex code is more than 2 bits, and colours are on,
    #  highlight the character its a special colour.
    if (( $#hex > 2 && do_colours )) {
      # recreate the name of the variable which stores the colour of the char
      #  i.e. "$_4B_colour" for a 4-bit hex code
      colour_name="_${#hex}B_colour"
      echo -n "${(P)colour_name}"
    }

    # Note: this syntax seems like the only thing that works with both when
    #  `$char` is a hyphen (`-`), and when its a percent sign (`%`)
    printf -- '%s' "$char$reset"

    # —— Text Mode ————————————————————————————— #
    # there's no more processing to do for text mode
    if [[ "$u_mode" == 'text' ]] continue

    # —— List Mode ————————————————————————————— #
    # add a left padding to the hex chars which need it
    if (( $#hex < u_zero_pad )) hex="${(l:$u_zero_pad::0:)hex}"

    # print the hex code, separator, and a newline
    #  also, make the hex code uppercase, and left-pad it with 5 spaces
    #y)TODO: change this so that it checks what the longest hex code is,
    #y)       and pads it to that length instead
    echo "  :  ${(Ul:5:)hex}"
  }

  # —— Final Cleanup ——————————————————————————— #
  # print a final newline if we're in text mode, and if the last char of the
  #  text wasn't already a newline.
  # (this is since we're using printf, which doesn't use trailing newlines)
  if [[ "$u_mode" == 'text' && "${(L*)hex/#0#}" != "$_NL_hex_code" ]] echo
  if (( do_colours )) echo -n "$_hard_reset"
}

# ——————————————————————————————————————————————————————————————————————————— #

# if we're not being sourced, run tests eqv. to `if __name__ == "__main__"`
if [[ "$ZSH_EVAL_CONTEXT" == toplevel ]] "${${(%):-%x}:a:h:h}/tests/test.zsh"
