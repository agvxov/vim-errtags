# Errtags

## Idea
The *"normal"* way to do error reporting is redefining your build-system to vim.
Thats disguasting.

The UNIX (righteous) way is to hook into the concrete build system.

Then, any (reasonable) editor can easily load the data.

## Screenshots
Vim and Emacs side by side.
[screenshot](errtags.png)

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

## Implementation details
We hook into the build system by executable-shadowing the build tools.
Otherwise put, we insert wrappers into the path.
For example suppose an invocation to `gcc`;
our `wrapper/gcc` will be found first which invokes the real compiler,
but with its output cloned and piped into `errtags`.

The `errtags` executable looks for known patterns of error messages
and saves it to a text file.

The text file's format is as follows:
```
#TOKEN
FILE:LINE:COL:MESSAGE
...
```
As you may notice, its a CSV with a header;
clearly inspired by `ctags`.

The TOKEN is a random integer used to differentiate between compiles.
It is set internally and when its found to be unchanged,
the file is appended instead of overwritten.
For example, the wrapper of `make` will set the token
and consequent `gcc` processes will know to preserve the file.

### Structure
| File | Description |
| :--- | :---------- |
| wrappers/   | Scripts wrapping tools, appending to our tags file |
| errtags.vim | Main vim source file; processes the tags file |
| errtags.el  | Main emacs source file; processes the tags file |
| errtags     | Responsible for grepping error messages and storing them in a csv-like file; written in tcl for speed and my sanity's sake |
