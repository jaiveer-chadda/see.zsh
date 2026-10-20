#!/usr/bin/env zsh

# build.zsh
# ‾‾‾‾‾‾‾‾‾

# don't try and source this file - it should only be executed directly
if [[ "$ZSH_EVAL_CONTEXT" != 'toplevel' ]] return 1

function -- () {

  setopt local_options local_traps warn_create_global warn_nested_var

  # ————————————————————————————————————————————————————————————————————————— #
  # —— Process CLI Args ————————————————————————————————————————————————————— #

  local mode='debug'

  while [[ -n "$1" ]] { #
    case "$1" {
      ( --debug ) mode='debug' ;;
      ( --prod  ) mode='prod'  ;;
      ( -- ) shift ;&
      ( *  ) break ;;
    }
    shift
  }

  # ————————————————————————————————————————————————————————————————————————— #
  # —— Compilation Options —————————————————————————————————————————————————— #

  # equivalent to running `dirname` on this file's path (w/o resolving links)
  local -r _proj_root="${${(%):-%x}:a:h}"
  local -r _source="$_proj_root/source/C"

  local -r CC='clang'
  local -ri 10 STD=23

  local -a CFLAGS=( std="c$STD" )

  # —— Definitions/Undefinitions ——————————————————————— #

  local -a DEFINE=( TTYCOLUMNS="$COLUMNS" )
  local -a UNDEFINE=( )

  # —— Enable & Disable Warnings ——————————————————————— #

  # all `-W...` warnings to enable
  local -a WARNINGS=(
    all      # warn about basic/near-essential code quality & safety issues
    extra    # warn about deeper code issues, which aren't always necessary
    pedantic # warn about the most minute issues like standard compliance, etc.
    vla      # don't allow the use of variable-length arrays
  )

  # all `-W-no-...` warnings to disable
  local -ra NO_WARN=( )

  # —— Libraries & Inclusions —————————————————————————— #

  local -ra LDLIBS=( ) LIBPATHS=( )
  local -ra INCLUDES=( "$_source" )

  local -ra FRAMEWORKS=( )

  # —— Sanitisation ———————————————————————————————————— #

  local -a SANITISE=(
    address   # throw an error when any memory inconsistencies occur
    undefined # raise a warning during undefined behaviour (eg `bool x = 2;`)
  )

  local -a ASAN_OPTS=(
    print_legend=0
    stack_trace_format=$'"  %n\t%f   \t%S"'
  )

  # —— Source Files ———————————————————————————————————— #

  # an array of all the program's source files
  local -ra SOURCE_FILES=( "$_source/"**/*.c )

  # —— Execution Options ——————————————————————————————— #

  # location of the outputted binary
  local -r TARGET="$_proj_root/build/seestr"

  # the command that should be run after compilation
  local -a CMD=( "$TARGET" )

  # ————————————————————————————————————————————————————————————————————————— #
  # —— Option Processing ———————————————————————————————————————————————————— #

  local optimisation

  case "$mode" {
    ( debug ) optimisation=0; CFLAGS+=( g ) ;;
    ( prod  ) optimisation=3 ;;
  }

  CFLAGS+=( O$optimisation )

  # —— $CMD ———————————————————————————————————————————— #

  CMD+=( "$@" )

  # —— $WARNINGS ——————————————————————————————————————— #

  if (( $#NO_WARN )) WARNINGS+=( "no-${(@)^NO_WARN}" )

  # —— $DEFINE ———————————————————————————————————— #

  # note: `NDEBUG` disables the `assert` macro
  if   [[ "$mode" == 'debug' ]] { DEFINE+=(  DEBUG ) UNDEFINE+=( NDEBUG ) } \
  elif [[ "$mode" == 'prod'  ]] { DEFINE+=( NDEBUG ) UNDEFINE+=(  DEBUG ) }

  # —— $SANITISE ——————————————————————————————————————— #

  if [[ "$mode" == 'prod' ]] SANITISE=( )
  local -r ASAN="${(j.:.)ASAN_OPTS}"

  # ————————————————————————————————————————————————————————————————————————— #
  # —— Collate Build Arguments —————————————————————————————————————————————— #

  # pack the build args into an array, adding each of their relevant prefixes,
  #  and making sure not to add any empty arrays
  local -a BUILD_ARGS

  if (( $#CFLAGS     )) BUILD_ARGS+=(  "-${(@)^CFLAGS}"              )
  if (( $#LDLIBS     )) BUILD_ARGS+=( "-l${(@)^LDLIBS}"              )
  if (( $#DEFINE     )) BUILD_ARGS+=( "-D${(@)^DEFINE}"              )
  if (( $#UNDEFINE   )) BUILD_ARGS+=( "-U${(@)^UNDEFINE}"            )
  if (( $#WARNINGS   )) BUILD_ARGS+=( "-W${(@)^WARNINGS}"            )
  if (( $#INCLUDES   )) BUILD_ARGS+=( "-I${(@)^INCLUDES}"            )
  if (( $#LIBPATHS   )) BUILD_ARGS+=( "-L${(@)^LIBPATHS}"            )
  if (( $#SANITISE   )) BUILD_ARGS+=( "-fsanitize=${(j:,:)SANITISE}" )
  if (( $#FRAMEWORKS )) BUILD_ARGS+=( "-framework ${(@)^FRAMEWORKS}" )

  # always add the target file
  BUILD_ARGS+=( --output "$TARGET" )

  # ————————————————————————————————————————————————————————————————————————— #
  # —— Compilation —————————————————————————————————————————————————————————— #

  BUILD_ARGS=( "${(@z)BUILD_ARGS}" -- "${(@)SOURCE_FILES}" )

  # pass that array of arguments to the compiler
  "$CC" "${(@)BUILD_ARGS}" # compile the program
  local -i 10 retcode=$?

  if (( retcode )) return retcode # failed to compile `$CC`

  # —— Run Program ————————————————————————————————————— #

  # then, if successful, execute the program
  #  run the newly compiled binary (with sanitisation options set)
  ASAN_OPTIONS="$ASAN" exec -a "${TARGET:t}" "${(@)CMD}"
  retcode=$?

  # —— Cleanup & Return ———————————————————————————————— #

  return retcode

} "$@"

# ——————————————————————————————————————————————————————————————————————————— #
# ——————————————————————————————————————————————————————————————————————————— #

# spell:ignore CFLAGS LDLIBS ASAN
