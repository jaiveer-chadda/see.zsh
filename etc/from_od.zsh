#!/usr/bin/env zsh

# Note: not really a viable function; just a proof of concept
function from_od fod () {
  local -r orig_text="${$( cat; echo '.' )%.}"
  local -r od_out="$( echo -nE "$orig_text" | od -a )"

  local -ra chars=( ${(@s: :)${(@f)od_out%$'\n'*}#* } )

  local -r SPC=$'\e[34m·\e[m'
  local -r ESC=$'\e[38;5;231;48;5;88m␛\e[m'
  local -r NLN=$'\e[33m␤\n\e[m'
  local -r UNK=$'\e[38;5;231;48;5;88m'
  local -r rst=$'\e[m'

  local -a formatted=( "${(@)chars}" )
  formatted=( "${(@)formatted:/sp/$SPC}"   )
  formatted=( "${(@)formatted:/esc/$ESC}" )
  formatted=( "${(@)formatted:/nl/$NLN}"   )

  # if there are any other array elems of len >= 2, highlight them
  #  but not elems that start with `\e`, cos those are our formatted chars
  formatted=( "${(@*)formatted:/(#b)([^$'\e']?##)/$UNK$match[1]$rst}" )

  # echo "$orig_text"        ; line
  # echo "$chars"            ; line
  # echo "$formatted"        ; line
  echo -En "${(j::)formatted}" # ; line
}

if [[ $ZSH_EVAL_CONTEXT == 'toplevel' ]] {
  timeout --help | head | from_od
}
