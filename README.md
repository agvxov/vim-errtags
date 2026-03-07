# Errtags

## Idea
The normal way to do error reporting is redefining your build-system to vim.
Thats disguasting.

The right way should be to hook into the actual build system.

For the details, see [documentation.md](documentation.md).

## Dependencies
+ Tcl

## Installation
1. Clone the source
2. Run:
```sh
$ make
# Does not require root, but creates ~/bin/, which must be in PATH.
# If you do not like that, install "errtags" and "wrappers/*" to wherever you see fit.
$ make install
```

3. Update your vim config
```sh
# .vimrc
let g:errtags_events = ["BufEnter", "BufWrite"]
```

4. Enjoy
