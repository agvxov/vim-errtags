## Process
Make is our friend, because its hackable.

    token := genrate-session-token()
    foreach t in $tools do
        $t($token)
    done

The session token is a number used to differentiate between compiles.

Every tool is wrapped, so that it emits its output both normally and piped into errtags.

A tags file is generated and processed by vim.

# Structure
| File | Description |
| wrappers/ | scripts wrapping tools, appending to our tags file |
| errtags.vim | main vim source file; processes the tags file |
| errtags | responsible for grepping error messages and storing them in a csv-like file; written in tcl for speed and my sanitys sake |
