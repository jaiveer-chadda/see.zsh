#!/usr/bin/env zsh

line_() { echo "${(r:$COLUMNS::─:)}"; }

# Note: not really a viable function; just a proof of concept
from_od fod () {
  local -r orig_text="${$( cat; echo '.' )%.}"
  local -r od_out="$( echo -nE "$orig_text" | od -a )"

  local -ra chars=( ${(@s: :)${(@f)od_out%$'\n'*}#* } )

  local -r SPC=$'\e[34m·\e[0m'
  local -r ESC=$'\e[38;5;231;48;5;088m␛\e[0m'
  local -r NLN=$'\e[33m␤\n\e[0m'
  local -r UNK=$'\e[38;5;231;48;5;088m'
  local -r rst=$'\e[0m'

  local -a formatted=( "${(@)chars}" )
  formatted=( "${(@)formatted:/sp/$SPC}"   )
  formatted=( "${(@)formatted:/esc/$ESC}" )
  formatted=( "${(@)formatted:/nl/$NLN}"   )

  # if there are any other array elems of len >= 2, highlight them
  #  but not elems that start with `\e`, cos those are our formatted chars
  formatted=( "${(@*)formatted:/(#b)([^$'\e']?##)/$UNK$match[1]$rst}" )

  # echo "$orig_text"        ; line_
  # echo "$chars"            ; line_
  # echo "$formatted"        ; line_
  echo -En "${(j::)formatted}" # ; line_
}

if [[ $ZSH_EVAL_CONTEXT == 'toplevel' ]] {
  timeout --help | head | from_od
}
