#!/usr/bin/env zsh

function see::read_input () {
  local -r  utf8_pager='cat'
  local -r ascii_pager='iconv -f ISO-8859-1 -t UTF-8'

  local pager
  if (( u_multibyte )) { pager="$utf8_pager"; } else { pager="$ascii_pager"; }

  # fork out to `cat` to read the files
  # `${u_file:-${@:--}}` is saying: first check if `$u_file` has some value.
  #  if it doesn't, check the rest of the arguments `$@`.
  #  if there's nothing in that, then read from stdin: `-`
  input="$(
    "${(@z)pager}"  "${(@)u_files:-${@:--}}" || return $?
    echo -n 'END'
  )" || return $?  # if `cat` fails, exit immediately

  # also, append an arbitrary string `END` to the end of the input, since the
  #  `$(...)` construct removes all trailing newlines, so this allows us to
  #  keep the trailing newline, after we remove the `END` string we added
  input="${input%END}"
}
