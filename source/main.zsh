#!/usr/bin/env zsh

# — TODO ———————————————————————————————————————————————————————————————————— #

# Features
# ‾‾‾‾‾‾‾‾
# - add a way to group escape sequences together
#   - i.e. show the user that, eg:
#     - `\e[31m` is all part of one "group" (if ykwim)
#   - and if they're colour escapes, maybe colour them as well...?
#     - tho tbh I'm unsure about this one, cos it might visually interfere
#        with all the other colours we've got going on

# Semantics / Syntax
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
# - maybe find a better way to store the escape character sets
#    cos they're a bit all over the place atm
#
# - rework the options loop to be able to use long arguments
#   - and so I can more specifically customise their behaviour

# To Finish
# ‾‾‾‾‾‾‾‾‾
# - implement the proper usage of the `-l` flag
# - create a proper verbose `-v` mode

# New Modes / Flags
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
# - add a flag to customise the character colours, or to just turn them off
#
# - make a multi-column mode, kinda like `xxd`'s
#   - or just turn the current column mode into that mode
#      and hide the current one away behind an obscure flag
#   - id have to find a way to properly and nicely
#      mark multibye characters in this mode tho
#
# - add a flag to change how the space char ␣ is displayed
#   - i.e. which one is used, if any at all

# ——————————————————————————————————————————————————————————————————————————— #

see::usage() {
  local -r \
    off=$'\e[39m' \
     b0=$'\e[22m' \
      b=$'\e[1m'  \
      r=$'\e[m'   \
    lrd=$'\e[91m' \
    red=$'\e[31m' \
    yel=$'\e[33m' \
    lgr=$'\e[92m' \
    grn=$'\e[32m' \
    cyn=$'\e[36m' \
    lbl=$'\e[94m' \
    blu=$'\e[34m' \
    mag=$'\e[35m'

  local -r opt="$r <$grn"
  local -r pad="${(r:8:)}"
  local -r dash="$yel  -$r"
  local -r comma="$r, $red"
  local -r arrow="$r $blu-->$r "
  local -r pipe="$grn... $yel|$r"
  local -r opt_format="${opt}format$r>"
  local -r not_imp="$lrd$b [ X ]$r"
  local -r redirection="$cyn< $mag/dev/stdin $r"
  local -r charset="$comma--charset${opt}charset$r>"
  local -r eg1="$mag" eg2=$'\e[1;31m' eg3=$'\e[44;30m'
  local -r colo_u_r="--${b}c${b0}olo${r}[${red}u$r]${red}r"
  local -r file="( $red-f$r | $red--file$r )${opt}file$r>"

  local -r \
    _cs="$r"$'\e[1;38;5;033;48;5;236m' \
    _uc="$r"$'\e[1;38;5;231;48;5;088m' \
    _cr="$r"$'\e[1;38;5;226;48;5;018m'

  local -r \
     __file="$red-f$comma--${b}f${b0}ile${opt}file$r>" \
     __text="$red-t$comma--${b}t${b0}ext$r"            \
     __list="$red-l$comma--${b}l${b0}ist$r"            \
     __mode="$red-m$comma--${b}m${b0}ode${opt}mode$r>" \
   __colour="$red-c$comma$colo_u_r${opt}when$r>"       \
  __colours="$red-C$comma${colo_u_r}s$opt_format"      \
   __escape="$red-e$comma--${b}e${b0}scapes$charset"   \
    __width="$red-w$comma--${b}w${b0}idth${opt}num$r>" \
   __zeroes="$red-0$comma--zeroes${opt}num$r>"         \
   __edebug="$red-D$comma$r"                           \
    __debug="$red-d$comma--${b}d${b0}ebug$r"           \
  __verbose="$red-v$comma--${b}v${b0}erbose$r"         \
     __help="$red-h$comma--${b}h${b0}elp$r"

  cat <<- EOF
	${r}Usage:
	  $red see$r [$grn OPTIONS $r] $redirection
	  $red see$r [$grn OPTIONS $r] [$grn FILE ... $r] $not_imp
	  $red see$r [$grn OPTIONS $r] $file $not_imp
	  $red see$r $file [$grn OPTIONS $r] $not_imp

	Print a file or stdin to stdout, highlighting all non-printable characters.

	  $__file $not_imp
	  $pad  The file to be read in and $lbl'seen'$r

	  $__mode $not_imp
	  $pad  Set the output mode
	  $pad      Possible values:
	  $pad      $dash text $b(default$off)$r
	  $pad      $dash list

	  $__text    Set output to text mode (shorthand for $red--mode$grn text$r)
	  $__list    Set output to list mode (shorthand for $red--mode$grn list$r)

	  $__colour
	  $pad  When to display colours in the output
	  $pad      Possible values:
	  $pad      $dash always
	  $pad      $dash $mag*${r}auto$mag*$r $b(default$off)$r
	  $pad      $dash never

	  $__colours $not_imp
	  $pad  Which colours to use for specific characters
	  $pad      Example: $lgr'1B 32  0A 33;45  0 44;1'$r
	  $pad      $dash $lgr'1B 35'   $arrow\U1B : magenta fg       $arrow$eg1␛$r
	  $pad      $dash $lgr'0A 1;31' $arrow\U0A : bold, red bg     $arrow$eg2␊$r
	  $pad      $dash $lgr'0  44;30'$arrow\U00 : black fg, blue bg$arrow$eg3␀$r
	  $pad      Note: consecutive spaces in$opt_format are ignored

	  $__escape
	  $pad  Which charset to display non-printable characters with
	  $pad      Possible values:
	  $pad      $dash none
	  $pad      $dash unicode     $_uc␀$r    $_uc␊$r    $_uc␛$r $b(default)$r
	  $pad      $dash c          $_cs\0$r   $_cs\n$r   $_cs\e$r
	  $pad      $dash caret      $_cr^@$r   $_cr^J$r   $_cr^[$r
	  $pad      $dash named     NUL   LF  ESC $not_imp
	  $pad      $dash cdash    \C-@ \C-J \C-[ $not_imp
	  $pad      $dash hex      0x00 0x0A 0x1B $not_imp
	  $pad      $dash uni_esc  \u00 \u0A \u1B $not_imp

	  $__width
	  $pad  Width of the columns in list mode $b(default:$yel 32$off)$r
	  $__zeroes
	  $pad  Number of zeroes to pad hex codes with $b(default:$yel 2$off)$r

	  $__edebug $pad Set early  debug mode (implies $red-v$r and $red-d$r)
	  $__debug   Set normal debug mode (implies $red-v$r)
	  $__verbose Set verbose mode

	  $__help    Show this help message

	EOF
  return 0
}

# ——————————————————————————————————————————————————————————————————————————— #

see() {

  # — Debugging Options ———————————————————————————————————————————————————— #

  setopt local_options
  setopt warn_create_global
  setopt warn_nested_var

  # — Early Debug Mode ————————————————————————————————————————————————————— #

  # this is here as a less checked, but earlier activated debug flag
  #  so I can debug the input parsing
  local -r _custom_ps4=$'%F{red}+ %N:%I%F{blue}\t>%f '

  # Note that `-D` will act as `-d` if it isn't the sole first argument
  if [[ "$1" == '-D' ]] {
    echo "${(%)_custom_ps4}changing \$PS4 locally to '$_custom_ps4'" >&2
    local PS4="$_custom_ps4"
    set -x
  }

  # — Constants ———————————————————————————————————————————————————————————— #

  local -r _reset=$'\e[m'

  # Generic Escape Character Colours
  local -r _unicode_colour=$'\e[0;1;38;5;231;48;5;088m'
  local -r _c_style_colour=$'\e[0;1;38;5;033;48;5;236m'
  local -r   _caret_colour=$'\e[0;1;38;5;226;48;5;018m'

  # Multibyte Colours
  local _3B_colour=$'\e[49;1;32m'
  local _4B_colour=$'\e[49;1;31m'
  local _5B_colour=$'\e[49;1;35m'
  local _6B_colour=$'\e[39;1;45m'

  # Whitespace Colours
  local -r _CRLF_colour=$'\e[49;1;33m'  # $'\e[...;48;5;26m'
  local -r   _SP_colour=$'\e[49;1;38;5;33m'

  # Whitespace Characters
  local -r _SP_char='·'  # ␣ / · / ␠ / ' ' #y)TODO
  #local-r _NL_char='␤'  # ␤ / ␊ / ↩ / ⏎   #y)TODO

  # Hex Codes
  local -r _NL_hex_code='a'

  # Visual Aides
  local -r _line="${(r:$COLUMNS::─:)}"

  # All Escape Characters
  local -rA _none_esc_chars=(
  )
  local -rA _c_esc_chars=(
    [esc_col]="$_c_style_colour"
    [$'\u00']='\0'   [$'\u01']='\x01' [$'\u02']='\x02' [$'\u03']='\x02'
    [$'\u04']='\x04' [$'\u05']='\x05' [$'\u06']='\x06' [$'\u07']='\a'
    [$'\u08']='\b'   [$'\u09']='\t'   [$'\u0A']='\n'   [$'\u0B']='\v'
    [$'\u0C']='\f'   [$'\u0D']='\r'   [$'\u0E']='\x0E' [$'\u0F']='\x0E'
    [$'\u10']='\x10' [$'\u11']='\x11' [$'\u12']='\x12' [$'\u13']='\x12'
    [$'\u14']='\x14' [$'\u15']='\x15' [$'\u16']='\x16' [$'\u17']='\x16'
    [$'\u18']='\x18' [$'\u19']='\x19' [$'\u1A']='\x1A' [$'\u1B']='\e'
    [$'\u1C']='\x1C' [$'\u1D']='\x1D' [$'\u1E']='\x1E' [$'\u1F']='\x1E'
    [$'\u7F']='\x7F'
  )
  local -rA _unicode_esc_chars=(
    [esc_col]="$_unicode_colour"
    [$'\u00']='␀'  [$'\u01']='␁'  [$'\u02']='␂'  [$'\u03']='␃'  [$'\u04']='␄'
    [$'\u05']='␅'  [$'\u06']='␆'  [$'\u07']='␇'  [$'\u08']='␈'  [$'\u09']='␉'
    [$'\u0A']='␤'  [$'\u0B']='␋'  [$'\u0C']='␌'  [$'\u0D']='␍'  [$'\u0E']='␎'
    [$'\u0F']='␏'  [$'\u10']='␐'  [$'\u11']='␑'  [$'\u12']='␒'  [$'\u13']='␓'
    [$'\u14']='␔'  [$'\u15']='␕'  [$'\u16']='␖'  [$'\u17']='␗'  [$'\u18']='␘'
    [$'\u19']='␙'  [$'\u1A']='␚'  [$'\u1B']='␛'  [$'\u1C']='␜'  [$'\u1D']='␝'
    [$'\u1E']='␞'  [$'\u1F']='␟'  [$'\u7F']='␡'
  )
  local -rA _caret_esc_chars=(
    [esc_col]="$_caret_colour"
    [$'\u00']='^@' [$'\u01']='^A' [$'\u02']='^B' [$'\u03']='^C' [$'\u04']='^D'
    [$'\u05']='^E' [$'\u06']='^F' [$'\u07']='^G' [$'\u08']='^H' [$'\u09']='^I'
    [$'\u0A']='^J' [$'\u0B']='^K' [$'\u0C']='^L' [$'\u0D']='^M' [$'\u0E']='^N'
    [$'\u0F']='^O' [$'\u10']='^P' [$'\u11']='^Q' [$'\u12']='^R' [$'\u13']='^S'
    [$'\u14']='^T' [$'\u15']='^U' [$'\u16']='^V' [$'\u17']='^W' [$'\u18']='^X'
    [$'\u19']='^Y' [$'\u1A']='^Z' [$'\u1B']='^[' [$'\u1C']='^\' [$'\u1D']='^]'
    [$'\u1E']='^^' [$'\u1F']='^_' [$'\u7F']='^?'
  )

  # — Take User Input —————————————————————————————————————————————————————— #

  # Note: a 'u_' prefix indicates a user-inputted value
  local u_file=             #y)not implemented yet
  local u_mode='text'       #y)only kinda implemented

  local u_do_colours='auto' # when to show colours
  local u_colours=          #y)not implemented yet
  local u_esc_chars=''      # default is 'unicode', but that's handled below

  local -i 10 u_width=32    # width for column mode (≈ xxd -c)
  local -i 10 u_zero_pad=2  # how many 0s to add before a hex code

  local -i 2 u_debug=0      # [bool] debug mode (implies verbose)
  local -i 2 u_verbose=0    # [bool] verbose mode

  # the leading hyphen here turns on some debug info,
  #  which I capture and use below
  local opt OPTARG OPTIND
  while { getopts ':f:m:tlc:C:e:w:0:vDdh' opt; } {
    #
    if (( u_debug )) echo "${(r:40::─:)}\nopt == '$opt'\narg == '$OPTARG'" >&2
    #
    case "$opt" {
      #### File ####
      f ) u_file="$OPTARG"      ;; #r)NOT IMPLEMENTED
      #
      #### Modes ####
      m ) u_mode="$OPTARG"      ;; #y)not fully implemented
      t ) u_mode='text'         ;;
      l ) u_mode='list'         ;;
      #
      #### Graphics ####
      c ) u_do_colours="$OPTARG";;
      C ) u_colours="$OPTARG"   ;; #r)NOT IMPLEMENTED
      e ) u_esc_chars="$OPTARG" ;;
      #
      #### Hex Display ####
      w ) u_width="$OPTARG"     ;; #y)no effect yet
      0 ) u_zero_pad="$OPTARG"  ;;
      #
      #### Internal/Debug ####
      v ) u_verbose=1           ;; #y)not fully implemented
     D|d) u_debug=1 u_verbose=1 ;;
      #
      #### Usage ####
      h ) see::usage; return 0  ;;
      * )
        {
          echo -n "$0: bad option: -${(qq)OPTARG}"            # if opt == `?`
          if [[ "$opt" == ':' ]] echo -n ' needs an argument' # if opt == `:`
          if (( ! u_debug )) { echo $'\n'; see::usage; return 1; }
          echo $'\n\e[1;31m——————— Option Issue ———————'"$reset"
        } >&2
      ;;
    }
    #
    if (( u_debug )) {
      {
        echo -n $'\e[32m-'"$opt"
        if [[ -n "$OPTARG" ]] echo -n " ${(qq)OPTARG}"
        echo $' is a valid input'"$reset"
      } >&2
    }
  }
  shift $(( OPTIND - 1 ))

  # — Process User Input ———————————————————————————————————————————————————— #

  if (( u_debug )) {
    u_verbose=1
    # if $PS4 is at its default value, then change it to a custom version.
    #  - the reasoning behind this is that if $PS4's been changed by the user,
    #    then they probably like it that way.
    #  - but if it hasn't, then we're free to use whichever version we like
    if [[ "$PS4" == '+%N:%i> ' || "$PS4" == '++' ]] local PS4="$_custom_ps4"
    set -x
  }

  # —— Set Colours & Special Chars (SP/NL/CR) —— #

  local -i 2 do_colours=0
  case "$u_do_colours" {
    always ) do_colours=1 ;;
    never  ) do_colours=0 ;;
    # if stdout (`1`) is writing to a tty (`-t`)...
    # i.e. if the output isn't being being piped somewhere
    # then turn colours on
    * ) if [[ -t 1 ]] do_colours=1 ;;
  }

  # —— Create Charset —————————————————————————— #

  # recreate the esc charset variable name from input
  local -r _charset_name="_${(L)u_esc_chars:-unicode}_esc_chars"
  # then pass that input by name (P) into the
  #  assoc array that's gonna be used for displaying chars
  local -A esc_chars=( "${(@Pkv)_charset_name}" )

  # ———————————————————————————————————————————— #

  local -r _NL=$'\n' _CR=$'\r' _SP=' '
  local esc_col= reset=

  esc_chars[$_SP]="$_SP_char"

  if (( do_colours )) {
    esc_col="${esc_chars[esc_col]}"
    reset="$_reset"
    # You have to pass the space and newline in as variables, otherwise
    #  zsh can't process the keys
    esc_chars[$_SP]="$_SP_colour$_SP_char$_reset"
    esc_chars[$_NL]="$_CRLF_colour${esc_chars[$_NL]}$_reset"
    esc_chars[$_CR]="$_CRLF_colour${esc_chars[$_CR]}$_reset"
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

  local -r input="${$( cat; echo '.' )%.}"

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
  local -a hexes=( "${(@f)"$( printf '%x\n' \'${^chars} )"}" )
  # zip $chars and $hexes together
  local -ra result=( "${(@)chars:^hexes}" )

  # ———————————————————————————————————————————————————————————————————————— #
  # — Outputting Results ——————————————————————————————————————————————————— #

  # Even though this looks like associative array syntax, it's not.
  #  I'm iterating through the zipped chars and hexes arrays, so zsh splits
  #  them for me, hence the separate char and hex variables
  local char hex colour_name
  for char hex in "${(@)result}"; {

    # —— Replace Chars & Print ————————————————— #
    # replace all chars with their special representations, if applicable
    #y)TODO: check if this if statement is actually doing anything
    if [[ "${esc_chars[(Ie)$char]}" ]] \
      char="$esc_col${esc_chars[$char]}$reset"

    # if the length of the hex code is more than 2 bits, and colours are on,
    #  highlight the character its a special colour.
    if (( $#hex > 2 && do_colours )) {
      # recreate the name of the variable which stores the colour of the char
      #  i.e. $_4B_colour for a 4-bit hex code
      colour_name="_${#hex}B_colour"
      # then echo pass that colour into the out
      # note: this syntax seems like the only thing that works with both when
      #  `$char` is a hyphen (`-`), and when its a percent sign (`%`)
      printf -- '%s' "${(P)colour_name}$char$reset"
    } else {
      # as much as I would love to compress this line down with the one above,
      #  I feel like this makes a little more sense logically
      # and means that I only have to use one if statement, rather than 2
      printf -- '%s' "$char"
    }

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
    echo "  :  ${(Ul:5:: :)hex}"
  }

  # —— Final Cleanup ——————————————————————————— #
  # print a final newline if we're in text mode, and if the last char of the
  #  text wasn't already a newline.
  # (this is since we're using printf, which doesn't use trailing newlines)
  if [[ "$u_mode" == 'text' && "${(L)hex/#0#}" != "$_NL_hex_code" ]] echo

  if (( u_debug   )) set +x
  if (( u_verbose )) echo $_line
}

# ——————————————————————————————————————————————————————————————————————————— #

# if the script's being run directly (i.e. not being sourced), then run tests
# (this line is equivalent to `if __name__ == "__main__"`)
if [[ $ZSH_EVAL_CONTEXT == 'toplevel' ]] {
  local -r _line="\e[2m${(r:$COLUMNS::─:)}\e[m"   ; clear   ; echo $_line
  echo -n "this is a normal•str"                  | see "$@"; echo "$_line"
  echo -n $'this?→\x00, its %s\nlong•"str"-\a␤\\' | see "$@"; echo "$_line"
  echo -n $'str w \x0 a\nnewline Δ'               | see "$@"; echo "$_line"
  echo -n $'\a\b\e\f\r\n\t\v\'\\'                 | see "$@"; echo "$_line"
  echo $'this isn\'t a \u0014 normal•str'         | see "$@"; echo "$_line"
  echo $'this?→\x00, its %s\nlong•"str"-\a␤\\'    | see "$@"; echo "$_line"
  echo $'str w \x0 a\nnew 󰟀 󰘵 󱄖  line'            | see "$@"; echo "$_line"
  echo $'\a\b\e \u0019\f\r\n\t\v\'\\'             | see "$@"; echo "$_line"
  echo $'test \e[31mstr\e[m'                      | see "$@"; echo "$_line"
  echo $'test ----   str\e[m'                    | see "$@"; echo "$_line"

  # cat ../resources/control_chars.txt              | see "$@"; echo $_line
  # cat $0 | head -n 301 | tail -n $(( LINES - 3 )) | see "$@"; echo $_line
  # cat $0                                          | see "$@"; echo $_line
}

# ——————————————————————————————————————————————————————————————————————————— #


# # These 3 can be generated rather than hardcoded - this is just temporary.
# # Honestly I'll have to look into it, but the caret and unicode esc chars
# #  might be able to be hardcoded as well
# local -rA _cdash_esc_chars=(
#   [esc_col]="$_caret_colour"
#   [$'\u00']='\C-@' [$'\u01']='\C-A' [$'\u02']='\C-B' [$'\u03']='\C-C'
#   [$'\u04']='\C-D' [$'\u05']='\C-E' [$'\u06']='\C-F' [$'\u07']='\C-G'
#   [$'\u08']='\C-H' [$'\u09']='\C-I' [$'\u0A']='\C-J' [$'\u0B']='\C-K'
#   [$'\u0C']='\C-L' [$'\u0D']='\C-M' [$'\u0E']='\C-N' [$'\u0F']='\C-O'
#   [$'\u10']='\C-P' [$'\u11']='\C-Q' [$'\u12']='\C-R' [$'\u13']='\C-S'
#   [$'\u14']='\C-T' [$'\u15']='\C-U' [$'\u16']='\C-V' [$'\u17']='\C-W'
#   [$'\u18']='\C-X' [$'\u19']='\C-Y' [$'\u1A']='\C-Z' [$'\u1B']='\C-['
#   [$'\u1C']='\C-\' [$'\u1D']='\C-]' [$'\u1E']='\C-^' [$'\u1F']='\C-_'
#   [$'\u7F']='\C-?'
# )
# local -rA _hex_esc_chars=(
#   [esc_col]="$_unicode_colour"
#   [$'\u00']='0x00' [$'\u01']='0x01' [$'\u02']='0x02' [$'\u03']='0x02'
#   [$'\u04']='0x04' [$'\u05']='0x05' [$'\u06']='0x06' [$'\u07']='0x06'
#   [$'\u08']='0x08' [$'\u09']='0x09' [$'\u0A']='0x0A' [$'\u0B']='0x0A'
#   [$'\u0C']='0x0C' [$'\u0D']='0x0D' [$'\u0E']='0x0E' [$'\u0F']='0x0E'
#   [$'\u10']='0x10' [$'\u11']='0x11' [$'\u12']='0x12' [$'\u13']='0x12'
#   [$'\u14']='0x14' [$'\u15']='0x15' [$'\u16']='0x16' [$'\u17']='0x16'
#   [$'\u18']='0x18' [$'\u19']='0x19' [$'\u1A']='0x1A' [$'\u1B']='0x1A'
#   [$'\u1C']='0x1C' [$'\u1D']='0x1D' [$'\u1E']='0x1E' [$'\u1F']='0x1E'
#   [$'\u7F']='0x7F'
# )
# local -rA _uni_esc_esc_chars=(
#   [esc_col]="$_unicode_colour"
#   [$'\u00']=$'\\u00' [$'\u01']=$'\\u01' [$'\u02']=$'\\u02' [$'\u03']=$'\\u02'
#   [$'\u04']=$'\\u04' [$'\u05']=$'\\u05' [$'\u06']=$'\\u06' [$'\u07']=$'\\u06'
#   [$'\u08']=$'\\u08' [$'\u09']=$'\\u09' [$'\u0A']=$'\\u0A' [$'\u0B']=$'\\u0A'
#   [$'\u0C']=$'\\u0C' [$'\u0D']=$'\\u0D' [$'\u0E']=$'\\u0E' [$'\u0F']=$'\\u0E'
#   [$'\u10']=$'\\u10' [$'\u11']=$'\\u11' [$'\u12']=$'\\u12' [$'\u13']=$'\\u12'
#   [$'\u14']=$'\\u14' [$'\u15']=$'\\u15' [$'\u16']=$'\\u16' [$'\u17']=$'\\u16'
#   [$'\u18']=$'\\u18' [$'\u19']=$'\\u19' [$'\u1A']=$'\\u1A' [$'\u1B']=$'\\u1A'
#   [$'\u1C']=$'\\u1C' [$'\u1D']=$'\\u1D' [$'\u1E']=$'\\u1E' [$'\u1F']=$'\\u1E'
#   [$'\u7F']=$'\\u7F'
# )


# ——————————————————————————————————————————————————————————————————————————— #

# spell:ignore cdash reprs

# spell:ignoreRegexp /(?<=(^|\s)#.*\(.\)|\[.\])\w+/g
# spell:ignoreRegexp /(?<=getopts) '[^']+'/g
# spell:ignoreRegexp /(?<=\$\{b0\})\w+/g
# spell:ignoreRegexp /\\(e|033|x1b)\[[0-9;]+?m\B/g
