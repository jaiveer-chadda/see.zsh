#!/usr/bin/env zsh

# — TODO ———————————————————————————————————————————————————————————————————— #

# Features
# ‾‾‾‾‾‾‾‾
# - implement a different highlight for different kinds of characters:
#   - e.g. they could be:
#     - ASCII Chars            -¬ white (i.e. no colour)
#     - 4 digit unicode values -¬ green
#     - 5 digit unicode values -¬ purple or smth idk
#     - control chars          -¬ as they currently are?
#
# - add a way to group escape sequences together
#   - i.e. show the user that, eg:
#     - `\e[31m` is all part of one "group" (if ykwim)
#   - and if they're colour escapes, maybe colour them as well...?
#     - tho tbh I'm unsure about this one, cos it might visually interfere
#        with all the other colours we've got going on

# Semantics / Syntax
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
# - check if/when we need to strip the final newline from the input
#   - cos it's honestly rly confused me, so I think I'm gonna need to do
#      some proper testing
#
# - maybe standardise the colour names, like with the esc chars
#
# - either finish making see::parse_opts or delete it
#   - cos looking back, yeah, it's a bit over-done
#
# - maybe find a better way to store the escape character sets
#    cos they're a bit all over the place atm
#   - also, the `C` esc chars don't include all invisible chars,
#      so I'll need a backup
#
# - move see::line into just being a constant
#   - I don't think there's any need for it to be its own function
#
# - add a few more comments to everything
#   - especially the new stuff

# To Finish
# ‾‾‾‾‾‾‾‾‾
# - implement the usage of the `-c` flag
# - create a proper verbose `-v` mode
# - make an actual usage/`-h` message

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
  local -r r=$'\e[0m' off=$'\e[39m' b=$'\e[1m' b0=$'\e[22m' \
    red=$'\e[31m' yel=$'\e[33m' lgr=$'\e[92m' grn=$'\e[32m' lbl=$'\e[94m' \
    blu=$'\e[34m' mag=$'\e[35m'

  local -r __="$yel  -$r"
  local -r opt="$r <$grn"
  local -r pad="${(r:8:)}"
  local -r comma="$r, $red"
  local -r arrow="$r $blu-->$r "
  local -r pipe="$grn... $yel|$r"
  local -r opt_format="${opt}format$r>"
  local -r charset="$comma--charset${opt}charset$r>"
  local -r not_imp=$'\e[91m '"$b< X >$r"
  local -r eg1=$'\e[32m' eg2=$'\e[1;31m' eg3=$'\e[44;30m'
  local -r coloour="--${b}c${b0}olo${r}[${red}u$r]${red}r"
  local -r file="( $red-f$r | $red--file$r )${opt}file$r>"

  local -r _cs="$r"$'\e[1;38;5;033;48;5;236m'
  local -r _uc="$r"$'\e[1;38;5;231;48;5;088m'
  local -r _cr="$r"$'\e[1;38;5;226;48;5;018m'

  local -r    __file="$red-f$comma--${b}f${b0}ile${opt}file$r>"
  local -r    __text="$red-t$comma--${b}t${b0}ext$r"
  local -r    __list="$red-l$comma--${b}l${b0}ist$r"
  local -r    __mode="$red-m$comma--${b}m${b0}ode${opt}mode$r>"
  local -r  __colour="$red-c$comma$coloour${opt}when$r>"
  local -r __colours="$red-C$comma${coloour}s$opt_format"
  local -r  __escape="$red-e$comma--${b}e${b0}scapes$charset"
  local -r   __width="$red-w$comma--${b}w${b0}idth${opt}num$r>"
  local -r  __zeroes="$red-0$comma--zeroes${opt}num$r>"
  local -r  __edebug="$red-D$comma$r"
  local -r   __debug="$red-d$comma--${b}d${b0}ebug$r"
  local -r __verbose="$red-v$comma--${b}v${b0}erbose$r"
  local -r    __help="$red-h$comma--${b}h${b0}elp$r"

  cat << EOF >&2
${r}Usage:
$pipe$red see$r [$grn OPTIONS $r]
     $red see$r [$grn OPTIONS $r] [$grn FILE ... $r]
     $red see$r [$grn OPTIONS $r] $file $not_imp
     $red see$r $file [$grn OPTIONS $r] $not_imp

Display text from a file or stdin, and highlight all non-printable characters.

  $__file $not_imp
  $pad  The file to be read in and $lbl'seen'$r

  $__mode $not_imp
  $pad  Set the output mode
  $pad      Possible values:
  $pad      $__ text $b(default$off)$r
  $pad      $__ list

  $__text    Set output to text mode (shorthand for $red--mode$grn text$r)
  $__list    Set output to list mode (shorthand for $red--mode$grn list$r)

  $__colour
  $pad  When to display colours in the output
  $pad      Possible values:
  $pad      $__ always
  $pad      $__ $mag*${r}auto$mag*$r $b(default$off)$r
  $pad      $__ never

  $__colours $not_imp
  $pad  Which colours to use for specific characters
  $pad      Example: $lgr'1B 32  0A 33;45  0 44;1'$r
  $pad      $__ $lgr'1B 32'   $arrow\U1B : green fg         $arrow$eg1␛$r
  $pad      $__ $lgr'0A 1;31' $arrow\U0A : bold, red bg     $arrow$eg2␊$r
  $pad      $__ $lgr'0  44;30'$arrow\U00 : black fg, blue bg$arrow$eg3␀$r
  $pad      Note: consecutive spaces in$opt_format are ignored

  $__escape
  $pad  Which charset to display non-printable characters with
  $pad      Possible values:
  $pad      $__ none
  $pad      $__ unicode     $_uc␀$r    $_uc␊$r    $_uc␛$r $b(default)$r
  $pad      $__ c          $_cs\0$r   $_cs\n$r   $_cs\e$r
  $pad      $__ caret      $_cr^@$r   $_cr^J$r   $_cr^[$r
  $pad      $__ cdash    \C-@$r \C-J$r \C-[$r $not_imp
  $pad      $__ hex      0x00$r 0x0A$r 0x1B$r $not_imp
  $pad      $__ uni_esc  \u00$r \u0A$r \u1B$r $not_imp

  $__width
  $pad  Width of the columns in list mode $b(default:$yel 32$off)$r
  $__zeroes
  $pad  Number of zeroes to pad hex codes with $b(default:$yel 2$off)$r

  $__edebug $pad Set early  debug mode (implies $red-v$r and $red-d$r)
  $__debug   Set normal debug mode (implies $red-v$r)
  $__verbose Set verbose mode

  $__help    Show this help message
EOF
}

# ——————————————————————————————————————————————————————————————————————————— #

see() {

  # — Early Debug Mode ————————————————————————————————————————————————————— #

  # this is here as a less checked, but earlier activated debug flag
  #  so I can debug the input parsing
  local -r _CUSTOM_PS4=$'%F{red}+ %N:%I%F{blue}\t>%f '

  # Note that `-D` will act as `-d` if it isn't the sole first argument
  if [[ "$1" == '-D' ]] {
    echo "${(%)_CUSTOM_PS4}changing \$PS4 locally to '$_CUSTOM_PS4'" >&2
    local PS4="$_CUSTOM_PS4"
    set -x
  }

  # — Constants ———————————————————————————————————————————————————————————— #

  local -r _NL=$'\n'
  local -r _SP=' '
  local -r _NL_0x='a'
  local -r _SP_0x='20'

  local -r _reset=$'\e[0m'
  local -r       _c_blue="$_reset"$'\e[38;5;033;48;5;236m'
  local -r  _unicode_red="$_reset"$'\e[38;5;231;48;5;088m'
  local -r _caret_yellow="$_reset"$'\e[38;5;226;48;5;018m'

  local -r   _space_blue="$_reset"$'\e[38;5;033m'

  local -r _space_char='␣'  # '␣' / '␠' / ' '
  local -r _space_repr="$_space_blue␣$_reset"


  local -rA _none_esc_chars=(
  )

  local -rA _c_esc_chars=(
    [esc_col]="$_c_blue"
    [$'\u00']='\\0' [$'\u07']='\\a' [$'\u08']='\\b' [$'\u09']='\\t'
    [$'\u0A']='\\n' [$'\u0B']='\\v' [$'\u0C']='\\f' [$'\u0D']='\\r'
    [$'\u1B']='\\e'
  )

  local -rA _unicode_esc_chars=(
    [esc_col]="$_unicode_red"
    [$'\u00']='␀'  [$'\u01']='␁'  [$'\u02']='␂'  [$'\u03']='␃'  [$'\u04']='␄'
    [$'\u05']='␅'  [$'\u06']='␆'  [$'\u07']='␇'  [$'\u08']='␈'  [$'\u09']='␉'
    [$'\u0A']='␊'  [$'\u0B']='␋'  [$'\u0C']='␌'  [$'\u0D']='␍'  [$'\u0E']='␎'
    [$'\u0F']='␏'  [$'\u10']='␐'  [$'\u11']='␑'  [$'\u12']='␒'  [$'\u13']='␓'
    [$'\u14']='␔'  [$'\u15']='␕'  [$'\u16']='␖'  [$'\u17']='␗'  [$'\u18']='␘'
    [$'\u19']='␙'  [$'\u1A']='␚'  [$'\u1B']='␛'  [$'\u1C']='␜'  [$'\u1D']='␝'
    [$'\u1E']='␞'  [$'\u1F']='␟'  [$'\u7F']='␡'
  )

  local -rA _caret_esc_chars=(
    [esc_col]="$_caret_yellow"
    [$'\u00']='^@' [$'\u01']='^A' [$'\u02']='^B' [$'\u03']='^C' [$'\u04']='^D'
    [$'\u05']='^E' [$'\u06']='^F' [$'\u07']='^G' [$'\u08']='^H' [$'\u09']='^I'
    [$'\u0A']='^J' [$'\u0B']='^K' [$'\u0C']='^L' [$'\u0D']='^M' [$'\u0E']='^N'
    [$'\u0F']='^O' [$'\u10']='^P' [$'\u11']='^Q' [$'\u12']='^R' [$'\u13']='^S'
    [$'\u14']='^T' [$'\u15']='^U' [$'\u16']='^V' [$'\u17']='^W' [$'\u18']='^X'
    [$'\u19']='^Y' [$'\u1A']='^Z' [$'\u1B']='^[' [$'\u1C']='^\' [$'\u1D']='^]'
    [$'\u1E']='^^' [$'\u1F']='^_' [$'\u7F']='^?'
  )

  # — User Input ——————————————————————————————————————————————————————————— #

  # Note: a 'u_' prefix indicates a user-inputted value
  local -i 10 u_debug=0     # [bool] debug mode (implies verbose)
  local -i 10 u_verbose=0   # [bool] verbose mode
  local -i 10 u_text_mode=0 # [bool] show just text instead of columns
  local -i 10 u_width=32    # width for column mode (≈ xxd -c)
  local -i 10 u_zero_pad=2  # how many 0s to add before a hex code
  local u_esc_chars=''      # which set of esc chars to use. the options are:
  #                         #   unicode    c    caret    cdash    none

  while { getopts ':DdvtCw:0:e:' opt; } {

    if (( u_debug )) {  
      echo "${(r:40::─:)}"
      echo "opt  ==  '$opt'"
      echo "arg  ==  '$OPTARG'"
    }
  
    case "$opt" {
    [Dd]) u_debug=1 u_verbose=1 ;;
      v ) u_verbose=1           ;;
      t ) u_text_mode=1         ;;
      C ) u_text_mode=0         ;;
      w ) u_width="$OPTARG"     ;;
      0 ) u_zero_pad="$OPTARG"  ;;
      e ) u_esc_chars="$OPTARG" ;;
      h ) usage; return 0       ;;
      * )
        echo -n $'\e[31m'
        if [[ "$opt" == '?' ]] { echo "$0: bad option: -$OPTARG" >&2; } \
        else { echo "$0: -$OPTARG requires an argument" >&2; }  # $opt = ':'
        echo -n $'\e[0m'
        usage; return 1
        ;;
    }

    if (( u_debug )) {
      echo -n "\e[32m-$opt"
      if [[ -n "$OPTARG" ]] echo -n " ${(qq)OPTARG}"
      echo ' is a valid input\e[0m'
    }
  }

  shift $(( OPTIND - 1 ))

  if (( u_debug )) {
    u_verbose=1
    # if $PS4 is at its default value, then change it to a custom version.
    #  - the reasoning behind this is that if $PS4's been changed by the user,
    #    then they probably like it that way.
    #  - but if it hasn't, then we're free to use whichever version we like
    if [[ "$PS4" == '+%N:%i> ' ]] local PS4="$_CUSTOM_PS4"
    set -x
  }

  # recreate the esc charset variable name from input
  _charset_name="_${(L)u_esc_chars:-unicode}_esc_chars"
  # then pass that input by name (P) into the
  #  assoc array that's gonna be used for displaying chars
  local -rA esc_chars=( "${(@Pkv)_charset_name}" )
  local -r esc_col="${esc_chars[esc_col]}"
  # read input from stdin, and append a newline to each line
  # note: the `|| [[ -n ...` section allows the last line to be read
  #  if the input doesn't end with a newline
  # gonna change this later TBAT work with passing a filename/variable in
  local input line
  while read -r line || [[ -n "$line" ]] input+="$line$_NL" </dev/stdin

  # — Pre-Processing ——————————————————————————————————————————————————————— #

  # remove the trailing newline
  # I did this originally to remove the traling newline
  #  added by the `input+=...` line, but idk if/when it's actually needed
  # TODO: check if/when it's needed
  input="${input/%$'\n'}"

  # split input at every !!codepoint!!
  #  - i.e. it recognises multi-byte characters
  # also, replace all spaces with the space repr
  local -ra chars=(
    "${(@)${(s::)input}//$_SP/$_space_repr}"
  )
  # local k v
  # for k v in "${(@kv)esc_chars}"; {
  #   chars=( "${(@)chars//$k/$esc_col$v$_reset}" )
  # }

  # - take every char and prepend it with a quote: `'`
  # - then use printf to convert each char to hex,
  #   - adding a newline between each hex value
  # - then split the result by newlines (f), and assign it to an arr
  local -a hexes=(
    "${(@f)"$( printf '%x\n' \'${^chars} )"}"
  )
  
  # zip $chars and $hexes together
  local -ra result=( "${(@)chars:^hexes}" )

  # — Outputting Results ——————————————————————————————————————————————————— #

  local char hex
  for char hex in "${(@)result}"; {
    # if we're in text mode, and char is a newline (0x0a),
    #  print a newline (`echo`) for legibility
    if (( "$u_text_mode" )) && [[ "${(L)hex}" == "$_NL_0x" ]] echo

    # replace all chars with their special representations, if applicable
    if [[ "${esc_chars[(Ie)$char]}" ]] \
      char="${esc_chars[esc_col]}${esc_chars[$char]}$_reset"

    # add a left padding to the hex chars which need it
    if (( $#hex < u_zero_pad )) hex="${(l:$u_zero_pad::0:)hex}"

    # always print the char itself
    # note: this syntax seemed like the only thing that works with both when
    #  $char is a hyphen, and when its a percent sign
    printf -- '%s' "$char"
    # and then if we're in column mode,
    #  print the hex code, separator, and a newline
    # also, make the hex code uppercase, and left-pad it with 5 spaces
    if ! (( u_text_mode )) echo "  :  ${(Ul:5:: :)hex}"
    # Note: when printing, make  ↑ sure a non-escapable char
    #  comes after it, or it'll be mangled if $char is a backslash
  }
  # final newline, since text mode is using `printf [-n]`
  if (( u_text_mode )) echo
  if (( u_debug     )) set +x
  if (( u_verbose   )) see::line
}

# ——————————————————————————————————————————————————————————————————————————— #

# if the script's being run directly (i.e. not being sourced), then run tests
#  equivalent to `if __name__ == "__main__"`
if [[ $ZSH_EVAL_CONTEXT == 'toplevel' ]] {
  # clear

  # echo -n "this is a normal•str" | see "$@"
  see::line
  echo -n $'this?→\x00, it\'s %%a\nlong•"str"-🖮\a␤ \\ 𱌮' | see "$@"
  see::line
  echo -n $'str w \x0 a\nnl' | see "$@"
  see::line
  echo -n $'\\\a\b\e\f\n\r\t\v' | see "$@"
  see::line
  echo $'test \e[31mstr\e[0m' | see "$@"
  see::line
  echo $'test ---- str\e[0m' | see "$@"
  see::line
  # cat $0 | see "$@"

  # cat ../resources/control_chars.txt | see "$@"
}

# ——————————————————————————————————————————————————————————————————————————— #


see::parse_opts() {
  # local -rA _opts_AArr=( "$@" )
  #
  # echo "$_opts_AArr"
  #
  #
  # # Note: a 'u_' prefix indicates a user-inputted value
  # local -i 10 u_debug=0     # [bool] debug mode (implies verbose)
  # local -i 10 u_verbose=0   # [bool] verbose mode
  # local -i 10 u_text_mode=0 # [bool] show just text instead of columns
  # local -i 10 u_width=32    # width for column mode (≈ xxd -c)
  # local -i 10 u_zero_pad=2  # how many 0s to add before a hex code
  # local u_esc_chars=''      # which set of esc chars to use. the options are:
  # #                         #   unicode    c    caret    cdash    none
  #   
  # local -rA _options=(
  #   [D]='0;1;-;*;0;early [D]ebug mode'
  #   [d]='0;0;-;*;0;[d]ebug mode'
  #   [v]='0;1;-;*;0;[v]erbose output'
  #   [t]='0;1;-;C;0;[t]ext-only mode'
  #   [C]='0;1;-;t;1;[C]olumn mode'
  #   [w]='1;0;i;t;32;output [w]idth'
  #   [0]='1;0;i;t;2;hex [0]-padding length'
  #   [e]='1;0;l;t;unicode;[e]scape charset;unicode,c,caret,cdash,none'
  #   [h]='0;0;-;-;-;[h]elp'
  #   #0   1 2 3 4   5.&.6...............  7.....
  #   # 0 - option character
  #   # 1 - takes input?
  #   # 2 - accepts `+`?
  #   # 3 - arg type
  #   #     - 'i'=int, 's'=str, 'l'=literal, '-'=n/a
  #   # 4 - does not work with
  #   #     - '*'=works w everything, '-'=works w nothing
  #   # 5 - default value
  #   #     - '-'=n/a
  #   # 6 - descriptive name
  #   # 7 - legal values (literals only)
  #   #     - comma-delimited
  # )
  #
  # while { getopts ':DdvtCw:0:e:' opt; } {
  # 
  #   echo "${(r:40::─:)}"
  #   echo "opt  ==  '$opt'"
  #   echo "arg  ==  '$OPTARG'"
  # 
  #   case "$opt" {
  #   [Dd]) u_debug=1 u_verbose=1 ;;
  #     v ) u_verbose=1           ;;
  #     t ) u_text_mode=1         ;;
  #     C ) u_text_mode=0         ;;
  #     w ) u_width="$OPTARG"     ;;
  #     0 ) u_zero_pad="$OPTARG"  ;;
  #     e ) u_esc_chars="$OPTARG" ;;
  #     h ) usage; return 0       ;;
  #     * )
  #       echo -n $'\e[31m'
  #       if [[ "$opt" == '?' ]] { echo "$0: bad option: -$OPTARG" >&2; } \
  #       else { echo "$0: -$OPTARG requires an argument" >&2; }  # $opt = ':'
  #       echo -n $'\e[0m'
  # 
  #       continue
  #       # usage
  #       # return 1
  #       ;;
  #   }
  #   if (( u_debug )) {
  #     echo -n "\e[32m-$opt"
  #     if [[ -n "$OPTARG" ]] echo -n " ${(qq)OPTARG}"
  #     echo ' is a valid input\e[0m'
  #   }
  # }
  #
}


# ——————————————————————————————————————————————————————————————————————————— #

# spell:ignore cdash

# spell:ignoreRegexp /(?<=(^|\s)#.*\(.\)|\[.\])\w+/g
# spell:ignoreRegexp /(?<=getopts) '[^']+'/g
# spell:ignoreRegexp /\\(e|033|x1b)\[[0-9;]+?m\B/g
