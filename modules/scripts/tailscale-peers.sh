#!/usr/bin/env bash
set -euo pipefail

# Tailscale peer picker — copies a peer's tailnet IP to the clipboard.
#
# Resolves the selection by index (`-format i`) rather than by parsing rofi's
# echoed row, for the same reason theme-rofi.sh does: hostnames are arbitrary
# user strings (ours contain a U+2019 apostrophe and spaces) and round-tripping
# them through rofi's output is fragile. The index into a stable array is not.

command -v tailscale >/dev/null 2>&1 || exit 0

STATUS=$(tailscale status --json 2>/dev/null) || exit 0

# Two parallel arrays: display rows for rofi, bare IPs for the clipboard.
mapfile -t ROWS < <(printf '%s' "$STATUS" | jq -r '
  def ipv4($ips): ($ips // []) | map(select(test("^[0-9]+\\."))) | (.[0] // "-");
  def rstrip_dot: sub("\\.$"; "");
  [ (.Self  // empty | {h: .HostName, i: ipv4(.TailscaleIPs), d: (.DNSName // "" | rstrip_dot), o: true,       s: true}) ]
  + [ (.Peer // {} | to_entries[] | .value
      | {h: .HostName, i: ipv4(.TailscaleIPs), d: (.DNSName // "" | rstrip_dot), o: (.Online // false), s: false}) ]
  | sort_by((.s | not), (.o | not), (.h // "" | ascii_downcase))
  | .[]
  | (if .o then "●" else "○" end) + " " + (.h // "?")
    + (if .s then " (this machine)" else "" end)
    + "\t" + .i + "\t" + .d
')

mapfile -t IPS < <(printf '%s' "$STATUS" | jq -r '
  def ipv4($ips): ($ips // []) | map(select(test("^[0-9]+\\."))) | (.[0] // "-");
  [ (.Self  // empty | {h: .HostName, i: ipv4(.TailscaleIPs), o: true,       s: true}) ]
  + [ (.Peer // {} | to_entries[] | .value
      | {h: .HostName, i: ipv4(.TailscaleIPs), o: (.Online // false), s: false}) ]
  | sort_by((.s | not), (.o | not), (.h // "" | ascii_downcase))
  | .[].i
')

((${#ROWS[@]})) || exit 0

# Same stale-pidfile guard every rofi keybind uses (see rofiKill in hyprland.nix).
rm -f "/run/user/$(id -u)/rofi.pid"

INDEX=$(printf '%s\n' "${ROWS[@]}" \
  | rofi -dmenu -i -format i -p "Tailscale" \
         -theme "$HOME/.config/rofi/clipboard.rasi" 2>/dev/null) || exit 0
[[ -n "$INDEX" ]] || exit 0

IP="${IPS[$INDEX]}"
[[ -n "$IP" && "$IP" != "-" ]] || exit 0

printf '%s' "$IP" | wl-copy
notify-send -a tailscale "Copied" "$IP" -i network-vpn
