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

    $ make && make install

3. Update your config files

    // .vimrc
    let g:errtags_events = ["BufEnter", "BufWrite"]
    // .bashrc
    alias make='make.sh CC=cc.sh'

4. Enjoy
