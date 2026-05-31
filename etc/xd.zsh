#!/usr/bin/env zsh

xd() {
  local -r space=$'\e[34m20\e[32m'
  local -a args=( -R always )  # colour = always

  # the `%.*` is to strip off the decimal suffix
  local -i 10 cols=${$(( ( COLUMNS - 2 ) / 3.5 ))%.*}
  local -i 10 groupsize=2

  if [[ "$1" == '-s' ]] {
    cols=$(( ( COLUMNS - 2 ) / 3 ))
    groupsize=0
    shift
  }

  args+=( -cols $cols -groupsize $groupsize )

  local -r raw_xxd_out="${$( xxd "${(@)args}" "$@"; echo '.' )%.}"

  local line hex text
  for line in "${(@f)raw_xxd_out}"; {
    if [[ -z "$line" ]] continue

    line="${line#*: }"

    text="${line#*  }"
    hex="${line%%  *}"

    echo -E "${hex//20/$space}  $text"
  }
}

if [[ $ZSH_EVAL_CONTEXT == 'toplevel' ]] {
  cat ../resources/control_chars.txt | xd "$@"
  # cat ./from_od.zsh | xd "$@"
  # cat ../.gitignore | xd "$@"
}
