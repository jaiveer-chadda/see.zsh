#!/usr/bin/env zsh

function see::read_input () {

  # fork out to `cat` to read the files
  # `${u_file:-${@:--}}` is saying:
  #  - first check if `$u_file` has some value.
  #  - then check the arguments `$@`.
  #  - finally, if there's nothing in any of those, then read from stdin: `-`
  input="$(
    cat "${(@)u_files:-${@:--}}" || return $?
    echo -n 'END'
  )" || return $?  # if `cat` fails, exit immediately

  # also, append an arbitrary string `END` to the end of the input, since the
  #  `$(...)` construct removes all trailing newlines, so this allows us to
  #  keep the trailing newline, after we remove the `END` string we added
  input="${input%END}"
}
