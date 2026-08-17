#!/usr/bin/env bash
# Hyprland config-manager compatibility shim.
#
# Hyprland 0.55 deprecated hyprlang (hyprland.conf) in favour of a Lua config
# (hyprland.lua), and under the Lua config manager two hyprctl commands change
# behaviour in ways that silently break scripts:
#
#   hyprctl keyword ...   -> "keyword can't work with non-legacy parsers. Use eval."
#   hyprctl dispatch ...  -> the argument is now parsed as *Lua*, not as a legacy
#                            dispatcher string. `hyprctl dispatch dpms on` fails
#                            with "')' expected near 'on'".
#
# While `useLua` in modules/nixos/hyprland.nix can still be flipped back to the
# .conf, every caller has to work under both managers — hence this shim. Once the
# .conf fallback is deleted the legacy branches here can go too.
#
# Usage — source it:
#     . "$HOME/Scripts/hypr-compat.sh"
#     hypr_set general:col.active_border "rgba(6f8fb3ee)"
#     hypr_set_gaps "300 3200 300 3200" 20
#
# ...or call it as a command (for hypridle / swaync, which take a shell string):
#     hypr-compat.sh dpms on
#     hypr-compat.sh exit

# Detection is by output, not exit status: `hyprctl eval` returns 0 on both
# managers and only the message differs.
_HYPR_IS_LUA=""
hypr_is_lua() {
	if [ -z "$_HYPR_IS_LUA" ]; then
		if [ "$(hyprctl eval 'return 1' 2>&1)" = "ok" ]; then
			_HYPR_IS_LUA=1
		else
			_HYPR_IS_LUA=0
		fi
	fi
	[ "$_HYPR_IS_LUA" = 1 ]
}

# hypr_set <section:sub.key> <value>
# Mirrors `hyprctl keyword`. Under Lua the dotted/colon path is expanded into a
# nested table and handed to hl.config(). Values that look numeric are passed as
# numbers (0x… included, which is what misc:background_color wants); everything
# else stays a string, which covers rgba()/rgb() colours and gradients.
hypr_set() {
	local key="$1" val="$2"
	if hypr_is_lua; then
		hyprctl eval "
			local parts = {}
			for p in ([[${key}]]):gmatch('[^:.]+') do parts[#parts + 1] = p end
			local root = {}
			local node = root
			for i = 1, #parts - 1 do
				node[parts[i]] = {}
				node = node[parts[i]]
			end
			node[parts[#parts]] = tonumber([[${val}]]) or [[${val}]]
			hl.config(root)
		" >/dev/null
	else
		hyprctl keyword "$key" "$val" >/dev/null
	fi
}

# hypr_set_gaps "<gaps_out>" "<gaps_in>"
# gaps_out is either a single integer or the four-value "top right bottom left"
# form. The four-value form has no string spelling under Lua — it must be a
# css-gap table ("css_gap type requires an integer or a table with optional
# top/right/bottom/left fields"), so it gets its own helper.
hypr_set_gaps() {
	local out="$1" gin="$2"
	if hypr_is_lua; then
		local -a o
		read -r -a o <<<"$out"
		local spec
		if [ "${#o[@]}" -ge 4 ]; then
			spec="{ top = ${o[0]}, right = ${o[1]}, bottom = ${o[2]}, left = ${o[3]} }"
		else
			spec="${o[0]}"
		fi
		hyprctl eval "hl.config({ general = { gaps_out = ${spec}, gaps_in = ${gin} } })" >/dev/null
	else
		hyprctl --batch "keyword general:gaps_out $out ; keyword general:gaps_in $gin" >/dev/null
	fi
}

# hypr_dpms on|off
hypr_dpms() {
	if hypr_is_lua; then
		hyprctl dispatch "hl.dsp.dpms(\"$1\")" >/dev/null
	else
		hyprctl dispatch dpms "$1" >/dev/null
	fi
}

hypr_exit() {
	if hypr_is_lua; then
		hyprctl dispatch 'hl.dsp.exit()' >/dev/null
	else
		hyprctl dispatch exit >/dev/null
	fi
}

# hypr_place_window <address> <workspace> <W H> <X Y>
# Replaces the ao-launch.sh batch of
#   movetoworkspacesilent / resizewindowpixel exact / movewindowpixel exact
hypr_place_window() {
	local addr="$1" ws="$2" size="$3" pos="$4"
	if hypr_is_lua; then
		local -a s p
		read -r -a s <<<"$size"
		read -r -a p <<<"$pos"
		local w="${s[0]}" h="${s[1]}" x="${p[0]}" y="${p[1]}"
		hyprctl --batch "\
dispatch hl.dsp.window.move({ workspace = $ws, silent = true, window = [[address:$addr]] }) ; \
dispatch hl.dsp.window.resize({ x = $w, y = $h, window = [[address:$addr]] }) ; \
dispatch hl.dsp.window.move({ x = $x, y = $y, window = [[address:$addr]] })" >/dev/null
	else
		hyprctl --batch "\
dispatch movetoworkspacesilent $ws,address:$addr ; \
dispatch resizewindowpixel exact $size,address:$addr ; \
dispatch movewindowpixel exact $pos,address:$addr" >/dev/null
	fi
}

# CLI mode, for callers that can only run a single shell command.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
	case "$1" in
		dpms) hypr_dpms "$2" ;;
		exit) hypr_exit ;;
		set)  hypr_set "$2" "$3" ;;
		gaps) hypr_set_gaps "$2" "$3" ;;
		*)    echo "usage: $(basename "$0") {dpms on|off | exit | set KEY VALUE | gaps OUT IN}" >&2; exit 2 ;;
	esac
fi
