# Based on https://gist.github.com/tommyip/cf9099fa6053e30247e5d0318de2fb9e


# Based on https://gist.github.com/bastibe/c0950e463ffdfdfada7adf149ae77c6f
# Changes:
# * Instead of overriding cd, we detect directory change. This allows the script to work
#   for other means of cd, such as z.
# * Update syntax to work with new versions of fish.
# * Prevent shell from exiting when deactivating virtualenv.
# * Only run auto_source_venv if we're not already handling venv.

# Global flag to track if we're in the middle of handling venv
set -g __VENV_HANDLING 0

function __handle_virtualenv_inheritance --on-event fish_prompt
    # Only run in new shells that have inherited VIRTUAL_ENV
    if test -n "$VIRTUAL_ENV" -a -z "$__VENV_INITIALIZED" -a "$__VENV_HANDLING" -eq 0
        # Mark this shell as initialized and prevent recursive handling
        set -g __VENV_INITIALIZED 1
        set -g __VENV_HANDLING 1

        # Clear inherited environment
        set -l old_path $PATH
        set -e VIRTUAL_ENV
        set -e _OLD_VIRTUAL_PATH
        set -e _OLD_VIRTUAL_PYTHONHOME
        set -e PYTHONHOME
        set -e VIRTUAL_ENV_PROMPT
        set -gx PATH $old_path

        # Let auto_source_venv handle activation if needed
        __auto_source_venv

        set -g __VENV_HANDLING 0
    end
end

function __auto_source_venv --on-variable PWD --description "Activate/Deactivate virtualenv on directory change"
    # Prevent running during command substitution or if we're already handling venv
    status --is-command-substitution; and return
    test "$__VENV_HANDLING" -eq 1; and return

    set -g __VENV_HANDLING 1

    # Check if we are inside a git repository
    if command git rev-parse --show-toplevel &>/dev/null
        set dir (realpath (command git rev-parse --show-toplevel))
    else
        set dir (pwd)
    end

    # Find a virtual environment in the directory
    set -l venv_dir ""
    for name in .venv venv .env env
        if test -e "$dir/$name/bin/activate.fish"
            set venv_dir "$dir/$name"
            break
        end
    end


    if test -n "$venv_dir" -a "$VIRTUAL_ENV" != "$venv_dir"
        # Activate venv if it was found and not activated before
        . "$venv_dir/bin/activate.fish"
    else if test -n "$VIRTUAL_ENV" -a -z "$venv_dir"
        # Deactivate venv if it is activated but we're no longer in a directory with a venv
        # Save PATH before deactivation
        set -l old_path $PATH

        # Try to deactivate safely
        if functions -q deactivate
            deactivate
            # Restore PATH if it was unset
            if test -z "$PATH"
                set -gx PATH $old_path
            end
        else
            # Manual cleanup if deactivate isn't available
            set -e VIRTUAL_ENV
            set -e _OLD_VIRTUAL_PATH
            set -e _OLD_VIRTUAL_PYTHONHOME
            set -e PYTHONHOME
            set -e VIRTUAL_ENV_PROMPT
            set -gx PATH $old_path
        end
    end

    set -g __VENV_HANDLING 0
end

# Only run initial check if we're not already handling venv
if test "$__VENV_HANDLING" -eq 0
    __auto_source_venv
end
