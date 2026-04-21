#!/usr/bin/env bash
# Shared helper — ensures the hook dispatcher is installed for all network locations.
# Source this file and call setup_dispatcher before installing any addon hooks.

_INSTALL_DIR="$HOME/.wifi-loc-control"

setup_dispatcher() {
    local changed=false

    # Read current macOS network locations
    local locations=()
    while IFS= read -r line; do
        local loc
        loc=$(echo "$line" | sed 's/.*(\(.*\))/\1/')
        [[ -n "$loc" ]] && locations+=("$loc")
    done < <(scselect 2>/dev/null | grep -E '^\s+\*?\s+[A-F0-9-]+')

    if [[ ${#locations[@]} -eq 0 ]]; then
        echo "Error: no macOS network locations found." >&2
        return 1
    fi

    mkdir -p "$_INSTALL_DIR"

    for loc in "${locations[@]}"; do
        local script="$_INSTALL_DIR/$loc"

        # Install dispatcher if missing or not yet a dispatcher
        if [[ ! -f "$script" ]] || ! grep -q "hooks" "$script" 2>/dev/null; then
            cat > "$script" << 'DISPATCHER'
#!/usr/bin/env bash
exec 2>&1
LOCATION="$(basename "$0")"
HOOKS_DIR="$(dirname "$0")/hooks/$LOCATION"
[[ -d "$HOOKS_DIR" ]] || exit 0
for hook in "$HOOKS_DIR"/[0-9][0-9]-*; do
    [[ -x "$hook" ]] || continue
    "$hook" "$LOCATION"
done
DISPATCHER
            chmod +x "$script"
            changed=true
        fi

        mkdir -p "$_INSTALL_DIR/hooks/$loc"
    done

    $changed && echo "Hook dispatcher installed for: ${locations[*]}"
    return 0
}
