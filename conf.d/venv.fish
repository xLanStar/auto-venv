if status is-interactive
    function __auto_source_venv --on-variable PWD --description "Activate/Deactivate virtualenv on directory change"
        status --is-command-substitution; and return
        if git rev-parse --show-toplevel &>/dev/null
            set gitdir (realpath (git rev-parse --show-toplevel))
            set cwd (pwd -P)
            if [ -e "$cwd/.venv/bin/activate.fish" ]
                . "$cwd/.venv/bin/activate.fish" &>/dev/null
                return
            end
        end
        if [ -n "$VIRTUAL_ENV" ] && functions -q deactivate
            deactivate
        end
    end

    __auto_source_venv $(builtin pwd -P)
end