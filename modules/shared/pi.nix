{ config, lib, pkgs, ... }:

# pi (pi.dev) set up to feel like Claude Code. The package itself is in
# home/default.nix; this wires the parts pi does not do on its own.
#
# pi reads ~/.pi/agent and never ~/.claude, so everything shared with Claude
# Code is linked across from the same source rather than copied.
#
# Not managed here, because they hold secrets or are written by pi itself:
# auth.json (/login), mcp.json, models.json, trust.json, sessions/.

let
  home = config.home.homeDirectory;
  agentDir = ".pi/agent";

  # The example extensions ship inside the package, so linking them from the
  # store keeps them in step with the installed pi on every update.
  examples = "${pkgs.pi-coding-agent}/lib/node_modules/pi-monorepo/examples/extensions";

  # ai-kit is a separate checkout, like ~/.config/nvim. pi skips skill and
  # prompt paths that do not exist (skills with a startup warning), so a host
  # without it still works -- it just has no shared instructions or skills.
  aiKit = "${home}/Dev/ai-kit";

  # settings.json is pi's to write (lastChangelogVersion, /settings, /model),
  # so it cannot be a store symlink. These keys are merged in on every switch;
  # every other key is left as pi wrote it.
  managedSettings = pkgs.writeText "pi-settings.json" (builtins.toJSON {
    defaultProvider = "anthropic";
    defaultModel = "claude-opus-5-5";
    defaultThinkingLevel = "high";
    enableInstallTelemetry = false;
    skills = [ "${aiKit}/plugins/core/skills" ];
    prompts = [ "${aiKit}/plugins/core/commands" ];

    # npm packages with dependencies of their own, which pi installs itself
    # (under its npm dir) rather than us packaging each with buildNpmPackage.
    # Exact versions, so both hosts run the same thing. jq's `*` replaces
    # arrays wholesale: this list is Nix's, a hand `pi install` is undone on
    # the next switch -- add it here instead.
    packages = [
      "npm:pi-web-access@0.38.0" # web_search, fetch, PDFs, GitHub clone; no key = Exa's public endpoint
      "npm:pi-subagents@0.76.1" # subagent tool, builtin scout/worker/reviewer/oracle/researcher, /council
    ];
  });

  # Third-party extensions, pinned to an npm tarball. Only ones with no runtime
  # dependencies fit here -- pi supplies its own packages (peerDependencies),
  # anything else would need buildNpmPackage. Bump: change version, set
  # hash = lib.fakeHash, build, paste the hash Nix reports.
  powerline = pkgs.fetchzip {
    url = "https://registry.npmjs.org/pi-powerline-footer/-/pi-powerline-footer-0.19.1.tgz";
    hash = "sha256-KUVHwDCU1dqDdl//ud9PlHerpbbxsrp+bRCVpmzykU8=";
  };

  link = path: { source = path; };
in
{
  home.file = {
    # Same global instructions as Claude Code (~/.claude/CLAUDE.md points here too).
    "${agentDir}/CLAUDE.md".source =
      config.lib.file.mkOutOfStoreSymlink "${aiKit}/instructions/claude-code-global/CLAUDE.md";

    # Claude Code's permissions.deny / .ask git rules -- pi asks for nothing by default.
    "${agentDir}/extensions/git-gate.ts" = link ../config/pi/git-gate.ts;

    # Calls out skill loads and MCP calls (including ones made from codemode).
    "${agentDir}/extensions/triggers.ts" = link ../config/pi/triggers.ts;

    "${agentDir}/extensions/plan-mode" = link "${examples}/plan-mode";   # /plan, Ctrl+Alt+P
    "${agentDir}/extensions/todo.ts" = link "${examples}/todo.ts";        # todo tool, /todos
    "${agentDir}/extensions/notify.ts" = link "${examples}/notify.ts";    # OSC 99 in kitty
    "${agentDir}/extensions/questionnaire.ts" = link "${examples}/questionnaire.ts"; # AskUserQuestion
    "${agentDir}/extensions/handoff.ts" = link "${examples}/handoff.ts";  # /handoff: fresh session, carried context

    # Rest of Claude Code's permission prompts: rm -rf, sudo and chmod 777 ask
    # first; edits under .env*, .git/ and node_modules/ are refused (substring
    # match, so .envrc is caught too).
    "${agentDir}/extensions/permission-gate.ts" = link "${examples}/permission-gate.ts";
    "${agentDir}/extensions/protected-paths.ts" = link "${examples}/protected-paths.ts";

    # Powerline footer (github:nicobailon/pi-powerline-footer). Its package.json
    # names index.ts as the entry. Two features call out, both off by default:
    # autoFollowUp (sends your prompts to api.typesafe.ai) and working vibes
    # (an LLM call per refresh). Cost display fetches currency rates daily.
    "${agentDir}/extensions/powerline-footer" = link powerline;

    # Subagents come from the pi-subagents package (managedSettings.packages),
    # not the example extension: both register a `subagent` tool.
  };

  # The powerline footer guesses Nerd Fonts from TERM_PROGRAM, which is "tmux"
  # inside tmux/herdr, so it falls back to ASCII there. Kitty's font is a Nerd
  # Font on both hosts (modules/shared/kitty.nix).
  home.sessionVariables.POWERLINE_NERD_FONTS = "1";

  home.activation.piSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings=${lib.escapeShellArg "${home}/${agentDir}/settings.json"}
    run mkdir -p "$(dirname "$settings")"
    [ -s "$settings" ] || run sh -c 'echo "{}" > "$1"' _ "$settings"
    tmp="$(mktemp)"
    if ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$settings" ${managedSettings} > "$tmp"; then
      run mv "$tmp" "$settings"
    else
      rm -f "$tmp"
      echo "piSettings: $settings is not valid JSON -- left untouched" >&2
    fi
  '';
}
