#!/usr/bin/env zsh

source "$SHD/line-functions/source/line.zsh"
source "${${(%):-%x}:a:h:h}/source/main.zsh"

clear; line -d

echo -nE - \
"'	' : tab
' ' : EM space
' ' : space
' ' : NBSP
' ' : figure space
' ' : punctuation space
'　' : ideographic space
' ' : EN space
' ' : 3 per EM space
' ' : narrow NBSP
' ' : medium mathematical space
' ' : 4 per EM space
' ' : thin space
' ' : 6 per EM space
' ' : hair space
'󠀠' : tag space
'​' : ZWSP
'﻿' : ZW-NBSP
" | see "$@"
