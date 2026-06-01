#!/usr/bin/env zsh

function see::usage () {
  local -r r=$'\e[m' off=$'\e[39m' b0=$'\e[22m' b=$'\e[1m' in=$'\e[7m' \
    red=$'\e[31m' lrd=$'\e[91m' \
    yel=$'\e[33m'               \
    grn=$'\e[32m' lgr=$'\e[92m' \
    cyn=$'\e[36m'               \
    blu=$'\e[34m' lbl=$'\e[94m' \
    mag=$'\e[35m'

  local -r opt="$r <$grn"
  local -r pad="${(r:8:)}"
  local -r dash="$yel  -$r"
  local -r comma="$r, $red"
  local -r arrow="$r $blu-->$r "
  local -r pipe="$grn... $yel|$r"
  local -r not_imp=" $in$lrd${b}[ X ]$r"
  local -r opt_format="${opt}format$r>"
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
     __help="$red-h$comma--${b}h${b0}elp$r"

  # ———————————————————————————————————————————————————————————————————————— #

  cat <<- EOF
	${r}Usage:
	  $red see$r [$grn OPTIONS $r] $redirection
	  $red see$r [$grn OPTIONS $r] [$grn FILE ... $r]
	  $red see$r [$grn OPTIONS $r] $file $grn...$r

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
	  $pad      $dash named     ${_uc}NUL$r   ${_uc}LF$r  ${_uc}ESC$r
	  $pad      $dash cdash    $_cr\C-@$r $_cr\C-J$r $_cr\C-[$r
	  $pad      $dash hex      ${_cs}0x00$r ${_cs}0x0A$r ${_cs}0x1B$r
	  $pad      $dash uni_esc  $_cr\u00$r $_cr\u0A$r $_cr\u1B$r

	  $__width
	  $pad  Width of the columns in list mode $b(default:$yel 32$off)$r
	  $__zeroes
	  $pad  Number of zeroes to pad hex codes with $b(default:$yel 2$off)$r

	  $__help    Show this help message

	EOF
  return 0
}

# ——————————————————————————————————————————————————————————————————————————— #

# spell:ignoreRegexp /(?<=\$\{b0\})\w+/g
