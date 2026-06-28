#!/usr/bin/env zsh

# load the `sysread` builtin - this is a frontend to the `read` syscall
#  we're using `sysread` instead of `read`, since `read` can't handle nullbytes
zmodload -F zsh/system b:sysread

function see::read_input () {
  # figure out whether the inputted filename actually points to stdin
  local -r _is_stdin='(-|/dev/stdin|/(proc/self|dev)/fd/0)'

  # combine the files passed via the `-f` option with
  #  anything left in the positional args
  local -a files_to_print=( "${(@)u_files}" "$@" )

  # if nothing was inputted, then read from stdin `-`
  if ! (( $#files_to_print )) files_to_print=( - )

  local -i 10 fd
  local file chunk

  for file in "${(@)files_to_print}"; {
    fd=-1  # an arbitrary, non-zero number

    # if we aren't reading from stdin, then open the file for reading as a
    #  new file descriptor, and store its number in `$fd`
    if [[ "$file" == ${~_is_stdin} ]] { fd=0; } else { exec {fd}<"$file"; }

    # read from `$fd` in 8kb chunks
    while { sysread -i $fd chunk; } input+="$chunk"

    # if we opened a custom fd, then, now that we're done, close `$fd`
    if (( fd != 0 )) exec {fd}<&-
  }
}
