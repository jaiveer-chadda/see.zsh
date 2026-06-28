#!/usr/bin/env zsh

zmodload -F zsh/system b:sysread

function see::read_input () {
  local -a files_to_print=( "${(@)u_files}" "$@" )
  if ! (( $#files_to_print )) files_to_print=( - )

  local -ri 10 chunk_size=$(( 1 << 13 ))  # 8 kb
  local  -i 10 fd
  local  -i 2  from_stdin

  local file temp_input
  input=

  for file in "${(@)files_to_print}"; {
    from_stdin=0

    if [[ "$file" == (-|/dev/stdin|/(proc/self|dev)/fd/0) ]] from_stdin=1
    if (( from_stdin )) { fd=0; } else { exec {fd}<"$file"; }

    # read from `$fd` chunk by chunk
    while { sysread -i $fd -s $chunk_size temp_input; } input+="$temp_input"

    # close `$fd`
    if ! (( from_stdin )) exec {fd}<&-
  }
}
