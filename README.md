# Errtags

## Idea
The normal way to do error reporting is redefining your build-system to vim.
Thats disguasting.

The right way should be to hook into the actual build system.

## Process
Make is our friend, because its hackable.

    token := genrate-session-token()
    foreach t in $tools do
        $t($token)
    done

The session token is a number used to differentiate between compiles.

Every tool is wrapped, so that it emits its output to both normally and piped into errtags.

Errtags is responsible for grepping error messages and storing them in a csv-like file.

The csv is passed to vim so it can display the errors.

## Dependencies
+ Tcl
