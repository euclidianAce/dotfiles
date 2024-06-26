$env.PROMPT_COMMAND = {||
    let prompt = ($env.DOTFILE_DIR | path join prompt)
    let exit_code = if $env.LAST_EXIT_CODE == 0 {
        ""
    } else {
        "罰 " + ($env.LAST_EXIT_CODE | into string)
    }

    mut current_git_head = (run-external "git" "branch" "--show-current" e> /dev/null)
    if $current_git_head == "" {
        $current_git_head = (run-external "git" "rev-parse" "--short" "HEAD" e> /dev/null)
    }
    if $current_git_head != "" {
        $current_git_head = "* " + $current_git_head
    }

    let working_directory = $env.PWD | str replace -r ("^" + $env.HOME) "~"

    (
        run-external
        $prompt
        attr=red $exit_code
        attr=gray (run-external date '+%I:%M:%S %p')
        attr=red ($env.USER + "@" + (run-external hostname))
        attr=blue pad=10 $working_directory
        attr=bright_green $current_git_head
    )
}
$env.PROMPT_COMMAND_RIGHT = ""

$env.PROMPT_INDICATOR = ""
$env.PROMPT_INDICATOR_VI_INSERT = "(i) "
$env.PROMPT_INDICATOR_VI_NORMAL = "(n) "
$env.PROMPT_MULTILINE_INDICATOR = " │ "

let path_conversion = {
    from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
    to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
}

$env.ENV_CONVERSIONS = {
    "PATH": path_conversion
    "Path": path_conversion
}

$env.NU_LIB_DIRS = [
    ($nu.default-config-dir | path join 'scripts')
    $nu.default-config-dir
]

$env.NU_PLUGIN_DIRS = [
    ($nu.default-config-dir | path join 'plugins')
]

$env.EDITOR = "nvim"
$env.MANPAGER = "nvim +Man!"
$env.DOTFILE_DIR = ($env.HOME | path join "dotfiles")
