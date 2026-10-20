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

  local -i 10 file_desc
  local file chunk

  for file in "${(@)files_to_print}"; {
    file_desc=-1  # an arbitrary, non-zero number

    if [[ "$file" == ${~_is_stdin} ]] {
      file_desc=0

    # if we aren't reading from stdin, then open the file for reading as a
    #  new file descriptor, and store its number in `$file_desc`
    } else {
      # first check that the file actually exists, and that we can read from it
      if ! [[ -e "$file" ]] { see::error file-find; continue; }
      if ! [[ -r "$file" ]] { see::error file-read; continue; }

      exec {file_desc}<"$file"
    }

    # read from `$file_desc` in 8kb chunks
    while { sysread -i $file_desc chunk; } input+="$chunk"

    # if we opened a custom fd, then, now that we're done, close `$file_desc`
    if (( file_desc != 0 )) exec {file_desc}<&-
  }
}
