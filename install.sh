#!/bin/sh
set -x
[ -d ~/.vim/plugin/ ] && cp errtags.vim ~/.vim/plugin/
[ -d ~/.emacs.d/    ] && cp errtags.el  ~/.emacs.d/
[ -d ~/bin/         ] && cp wrappers/*  ~/bin/
