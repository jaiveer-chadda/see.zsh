# TODO

## Features

- add a way to group escape sequences together
  - i.e. show the user that, eg:
    - `\e[31m` is all part of one "group" (if ykwim)
  - and if they're colour escapes, maybe colour them as well...?
    - tho tbh I'm unsure about this one, cos it might visually interfere with all the other colours we've got going on

## Semantics / Syntax

- maybe find a better way to store the escape character sets cos they're a bit all over the place atm

- rework the options loop to be able to use long arguments
  - and so I can more specifically customise their behaviour

## To Finish

- implement the proper usage of the `-l` flag
- create a proper verbose `-v` mode

## New Modes / Flags

- add a flag to customise the character colours, or to just turn them off

- make a multi-column mode, kinda like `xxd`'s
  - or just turn the current column mode into that mode and hide the current one away behind an obscure flag
  - id have to find a way to properly and nicely mark multibye characters in this mode tho

- add a flag to change how the space char `␣` is displayed
  - i.e. which one is used, if any at all
