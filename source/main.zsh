#!/usr/bin/env zsh

see() {

  # — Early Debug Mode ————————————————————————————————————————————————————— #

  # this is here as a far less checked, but earlier activated, debug flag
  #  so I can debug the input parsing
  local -r _CUSTOM_PS4=$'%F{red}+ %N:%I%F{blue}\t>%f '

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

  local -rA _none_esc_chars=()


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

  local -i 10 u_debug=0     # [bool] debug mode (implies verbose)
  local -i 10 u_verbose=0   # [bool] verbose mode
  local -i 10 u_text_mode=0 # [bool] show just text instead of columns
  local -i 10 u_columns=32  # width for column mode (≈ xxd -c)
  local -i 10 u_zero_pad=2  # how many 0s to add
  local u_esc_chars         # which set of esc chars to use
  #                         # - options are: (case-insensitive)
  #                         #   - c
  #                         #   - caret
  #                         #   - cdash  # \C-
  #                         #   - unicode (default)
  #                         #   - none

  while getopts 'DdvtCc:0:e:' opt; do
    case "$opt" in
     [Dd] ) u_debug=1 u_verbose=1 ;; # early-(D)ebug/(d)ebug [implies -v]
      v   ) u_verbose=1           ;; # (v)erbose
      t   ) u_text_mode=1         ;; # (t)ext mode [↓ opposites]
      C   ) u_text_mode=0         ;; # (C)olumn mode    [↑ opposites]
      c   ) u_columns="$OPTARG"   ;; # number of (c)olumns [column mode only]
      0   ) u_zero_pad="$OPTARG"  ;; # hex (0)-padding [column mode only]
      e   ) u_esc_chars="$OPTARG" ;; # (e)scape charset to use
    esac
  done
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
  u_esc_chars="_${(L)u_esc_chars:-unicode}_esc_chars"
  # then pass that input by name (P) into the
  #  assoc array that's gonna be used for displaying chars
  local -rA esc_chars=( "${(@Pkv)u_esc_chars}" )

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
  local -ra chars=( "${(@s::)input}" )

  # - take every char and prepend it with a quote: `'`
  # - then use printf to convert each char to hex,
  #   - adding a newline between each hex value
  # - then split the result by newlines (f), and assign it to an arr
  local -ra hexes=(
    ${(f)"$( printf '%x\n' \'${^chars} )"}
  )
  # zip $chars and $hexes together
  local -ra result=( "${(@)chars:^hexes}" )

  # — Outputting Results ——————————————————————————————————————————————————— #

  local char hex

  if (( u_debug )) { set +x; echo "${(r:4::\n:)}"; line; line; set -x; }

  for char hex in "${(@)result}"; {
    if (( u_debug )) {
      set +x
      echo "${(%)PS4}\e[35mchar \e[0m : >>${(qqqq)char}<<"
      echo "${(%)PS4}\e[35mhex  \e[0m : >>$hex<<"
      echo "${(%)PS4}\e[35mhex_i\e[0m : >>$(( (16#$hex) ))<<\n"
      set -x
    }

    # if we're in text mode, and char is a newline (0x0a),
    #  print a newline (`echo`), for legibility
    if [[ "$u_text_mode" && "${(L)hex}" == "$_NL_0x" ]] echo

    # replace all special chars with their special representations
    if [[ "$char" == "$_SP" ]] char="$_space_repr"
    if [[ "${esc_chars[(Ie)$char]}" ]] \
      char="${esc_chars[esc_col]}${esc_chars[$char]}$_reset"

    # add a left padding to the hex chars which need it
    if (( $#hex < u_zero_pad )) hex="${(l:$u_zero_pad::0:)hex}"

    # always print the char itself
    echo -n "$char"
    # and then if we're in column mode (non-textonly mode),
    #  print the hex code, separator, and newline
    # also, make the hex code uppercase, and left-pad it with 5 spaces
    if ! (( u_text_mode )) echo "  :  ${(Ul:5:: :)hex}"
    # Note: when printing, make  ↑ sure a non-escapable char
    #  comes after it, or a backslash will mangle it

    if (( u_debug )) { set +x; echo "${(r:4::\n:)}"; line; set -x; }
  }
  # final newline, since text mode is using `echo -n`
  if (( u_text_mode )) echo
  if (( u_debug )) { set +x; line; }
}

# ——————————————————————————————————————————————————————————————————————————— #

# if the script's being run directly (i.e. not being sourced), then run tests
#  equivalent to `if __name__ == "__main__"`
if [[ $ZSH_EVAL_CONTEXT == 'toplevel' ]] {
  # clear
  # echo -n "this is a normal•str" | see "$@"
  # echo -n "this is a normal•str" | see -d
  # echo -n $'this?→\x00, it\'s a\nlong•"str" 🖮\a␤ \\ 𱌮' | see 
  # echo -n $'this?→\x00, it\'s a
  # long•"str" 🖮\a␤ \\ 𱌮' | see "$@"
  echo -n $'str w \x0 a
  nl' | see "$@"
  # echo -n $'\\\a\b\e\f\n\r\t\v' | see

  # cat $0 | see
  # cat ./control_chars.txt | see
}
# ——————————————————————————————————————————————————————————————————————————— #

# spell-checker:ignore cdash
# spell-checker:ignoreRegExp /(?<=(^|\s)#.*\(.\))\w+/g
# spell-checker:ignoreRegExp /(?<=getopts) '[^']+'/g
# spell-checker:ignoreRegExp /\\(e|033|x1b)\[[0-9;]+?m\B/g

line() { echo ${(r:$COLUMNS::─:)}; }
