#!/usr/bin/env zsh

() {
  local -r source_dir="${${(%):-%x}:a:h}"
  source "$source_dir/usage.zsh"
  source "$source_dir/charsets.zsh"
  source "$source_dir/read-input.zsh"
}

function see () {

  # — Set Options —————————————————————————————————————————————————————————— #

  setopt local_options warn_create_global multi_byte

  # — Constants ———————————————————————————————————————————————————————————— #

  # ~~ General ~~
  local -r _hard_reset=$'\e[!p\e[m'  # see ../notes/hard-reset.note
  local -r _NL_hex_code='a'

  # ~~ Multibyte Colours ~~
  local -r _3B_colour=$'\e[0;1;32m'  # ␛32m
  local -r _4B_colour=$'\e[0;1;31m'  # ␛31m
  local -r _5B_colour=$'\e[0;1;35m'  # ␛35m
  local -r _6B_colour=$'\e[0;1;45m'  # ␛45m

  # — Take User Input —————————————————————————————————————————————————————— #

  # Note: a 'u_' prefix indicates a user-inputted value
  local -a u_files          # explicitly pass a file as input
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
      ( f ) u_files+=( "$OPTARG" );;
      #
      #### Modes ####
      ( m ) u_mode="$OPTARG"      ;; #y)not fully implemented
      ( t ) u_mode='text'         ;;
      ( l ) u_mode='list'         ;;
      #
      #### Graphics ####
      ( c ) u_do_colours="$OPTARG";;
      ( C ) u_colours="$OPTARG"   ;; #r)not implemented
      ( e ) u_esc_chars="$OPTARG" ;;
      #
      #### Hex Display ####
      ( w ) u_width="$OPTARG"     ;; #y)no effect yet
      ( 0 ) u_zero_pad="$OPTARG"  ;;
      #
      #### Usage ####
      ( h ) see::usage; return 0  ;;
      ( * ) >&2 {
        echo -nE "$0: bad option: -${(qq)OPTARG}"        # if `$opt` == `?`
        if [[ $opt == : ]] echo -n ' needs an argument'  # if `$opt` == `:`
        #
        echo $'\n'  # one NL to fix the `echo -n`, and one for padding
        see::usage
        return 1
      } ;;
    }
  }
  shift 'OPTIND - 1'

  # ———————————————————————————————————————————————————————————————————————— #
  # —— Create Charset —————————————————————————————————————————————————————— #

  local -i 2 do_colours=0
  local -A esc_chars
  local esc_col= reset=

  see::make_charset || return $?

  # ———————————————————————————————————————————————————————————————————————— #
  # — Read Input Files ————————————————————————————————————————————————————— #

  local input
  see::read_input "$@" || return $?

  # ———————————————————————————————————————————————————————————————————————— #
  # — Pre-Processing ——————————————————————————————————————————————————————— #

  # —— Split Input at Codepoints —————————————— #
  # split input at every !!codepoint!!
  #  - i.e. it recognises multi-byte characters
  local -ra chars=( "${(@s::)input}" )

  # —— Convert Chars to Hex ———————————————————— #
  # take every char and prepend it with a quote: `\'$^chars`, then use
  #  `printf` to convert each char to hex, adding a NL between hex codes
  local hex_str; printf -v hex_str $'%x\n' \'$^chars
  # then split the result by newlines (f), and assign it to an array (@)
  local -ra hexes=( "${(@f)hex_str}" )

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
    char="${esc_chars[$char]:-$char}"

    # if the length of the hex code is more than 2 bits, and colours are on,
    #  highlight the character its a special colour.
    if (( $#hex > 2 && do_colours )) {
      # recreate the name of the variable which stores the colour of the char
      #  i.e. "$_4B_colour" for a 4-bit hex code
      colour_name="_${#hex}B_colour"
      char="${(P)colour_name}$char$reset"
    }

    # Note: this syntax seems like the only thing that works with both when
    #  `$char` is a hyphen (`-`), and when its a percent sign (`%`)
    printf -- '%s' "$char"

    # —— Text Mode ————————————————————————————— #
    # there's no more processing to do for text mode
    if [[ "$u_mode" == 'text' ]] continue

    # —— List Mode ————————————————————————————— #
    # add a left padding to the hex chars which need it
    if (( $#hex < u_zero_pad )) hex="${(l:$u_zero_pad::0:)hex}"

    # print the hex code, separator, and a newline
    #  also, make the hex code uppercase, and left-pad it with 5 spaces
    echo "  :  ${(Ul:5:)hex}"
  }

  # —— Final Cleanup ——————————————————————————— #
  # print a final newline if we're in text mode, and if the last char of the
  #  text wasn't already a newline.
  # (this is since we're using printf, which doesn't use trailing newlines)
  if [[ "$u_mode" == 'text' && "${(L*)hex/#0#}" != "$_NL_hex_code" ]] echo
  if (( do_colours )) echo -n "$_hard_reset"
}

# —————————————————————————————————————————————————————————————————————————— #

# if we're not being sourced, run tests eqv. to `if __name__ == "__main__"`
if [[ "$ZSH_EVAL_CONTEXT" == toplevel ]] "${${(%):-%x}:a:h:h}/tests/test.zsh"
