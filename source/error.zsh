#!/usr/bin/env zsh

function see::error () {
  local -r error=$'\e[31msee\e[m: '
  print -nu2 "$error"

  case "$1" {
    ( file-find ) echo -E "couldn't find '$file'" ;;
    ( file-read ) echo -E "'$file' isn't readable by the current process" ;;

    ( option )
      echo -nE "bad option: ${(qq)OPTARG/#/-}"  # if `$opt` == `?`
      if [[ $opt == : ]] echo -n ' takes an argument'

      echo  # print a NL to fix the lack of newline above
      see::usage
    ;;

    ( colour )
      echo -n£ "unsupported colour value '$u_do_colours' "
      echo '(must be always, *auto*, or never)'
    ;;

    ( charset )
      if [[ $funcstack == *see::test* ]] { echo 'invalid charset'; return; }

      echo -E "$(<<- EOF
				unsupported character set '$u_esc_chars'
				  valid charsets are:
				    - ␛     Unicode  [default when output is to a tty]
				    - ESC   Named
				    - \e    C        [default when being piped]
				    - ^[    Caret
				    - \C-[  C-dash
				    - 0x1B  Hex
				    - \u1B  Unicode Escape
				    - ?     None
				  note: all charset names are case-insensitive,
				   and all hyphens, spaces, and underscores in names are ignored
			EOF
      )"
    ;;

    ( * ) echo "$1" ;;

  } >&2
}

# spell:ignoreRegexp /\\([␛e]|0?33)\[[0-9;]*m\B/g
