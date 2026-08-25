#!/bin/sh

# Tailscale status for waybar.
#
# Headscale-compatible by construction: every field read here comes from
# `tailscale status --json`, which headscale serves identically to
# tailscale.com. Nothing touches the control-plane API, so no tailscale.com
# capability (Taildrop's file-sharing cap, Mullvad exit nodes) is assumed.
#
# Hidden entirely when tailscale isn't installed or tailscaled isn't
# answering — matches the empty-stdout idiom the other optional modules use.

command -v tailscale >/dev/null 2>&1 || { printf ''; exit 0; }

STATUS=$(tailscale status --json 2>/dev/null) || { printf ''; exit 0; }
[ -n "$STATUS" ] || { printf ''; exit 0; }

printf '%s' "$STATUS" | jq -c '
  # Peers carry both v4 and v6; the bar and the copy actions only ever want v4.
  def ipv4($ips): ($ips // []) | map(select(test("^[0-9]+\\."))) | (.[0] // "-");
  def rstrip_dot: sub("\\.$"; "");

  . as $s
  | ($s.Peer // {} | to_entries | map(.value))            as $peers
  | ($peers | map(select(.Online)))                       as $up
  | ($s.ExitNodeStatus)                                   as $exit
  | (if $exit == null then null
     else ($peers | map(select(.ID == $exit.ID)) | first) end) as $exitPeer
  | ($s.Health // [])                                     as $health

  | (
      "Tailscale — " + ($s.BackendState // "unknown") + "\n"
      + ($s.Self.HostName // "?") + "  " + ipv4($s.Self.TailscaleIPs) + "\n"
      + (($s.Self.DNSName // "") | rstrip_dot)
      + (if ($peers | length) > 0 then
           "\n\n" + (
             $peers
             | sort_by((.Online | not), (.HostName // "" | ascii_downcase))
             | map((if .Online then "● " else "○ " end)
                   + (.HostName // "?") + "  " + ipv4(.TailscaleIPs)
                   + (if .ExitNode then "  (exit node)" else "" end))
             | join("\n")
           )
         else "" end)
      + (if $exitPeer != null then
           "\n\nRouting via " + ($exitPeer.HostName // "exit node")
         else "" end)
      + (if ($health | length) > 0 then
           "\n\n⚠ " + ($health | join("\n⚠ "))
         else "" end)
      + "\n\nclick peers · right status · middle copy own IP"
    ) as $tooltip

  | if $s.BackendState == "Running" then
      {
        text: ("󰖂  " + (if $exitPeer != null
                        then ($exitPeer.HostName // "exit")
                        else ($up | length | tostring) end)),
        tooltip: $tooltip,
        class: (if ($health | length) > 0 then "warning"
                elif $exitPeer != null then "exitnode"
                else "active" end)
      }
    elif $s.BackendState == "NeedsLogin" or $s.BackendState == "NoState" then
      { text: "󰖂  login", tooltip: $tooltip, class: "warning" }
    else
      # Stopped: keep it visible but muted — a silently-off VPN is worth seeing.
      { text: "󰖂", tooltip: $tooltip, class: "disconnected" }
    end
'
