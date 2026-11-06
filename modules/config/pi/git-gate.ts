/**
 * Git Gate Extension
 *
 * Pi runs every tool call without asking. This carries over the git rules from
 * ~/.claude/settings.json `permissions`: pushing is refused outright, and
 * anything else that writes history or switches branches needs a yes first.
 * Matches anywhere in the command, so `cd x && git commit` and `git -C dir
 * commit` are caught too.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// `git`, then any global options (-C <dir>, -c <k=v>, --no-pager, ...), then the subcommand
const gitSubcommand = (names: string) =>
	new RegExp(String.raw`\bgit\b(?:\s+(?:-[Cc]\s+\S+|--?[\w-]+(?:=\S+)?))*\s+(${names})\b`);

const denied = gitSubcommand("push");
const ask = gitSubcommand(
	"commit|pull|merge|rebase|reset|revert|cherry-pick|stash|checkout|switch|branch|tag|clean",
);

export default function (pi: ExtensionAPI) {
	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "bash") return undefined;
		const command = event.input.command as string;

		if (denied.test(command)) {
			return { block: true, reason: "git push is not allowed from pi -- the user pushes" };
		}

		const match = command.match(ask);
		if (match) {
			if (!ctx.hasUI) {
				return { block: true, reason: `git ${match[1]} needs confirmation (no UI available)` };
			}
			const choice = await ctx.ui.select(`git ${match[1]}:\n\n  ${command}\n\nAllow?`, ["Yes", "No"]);
			if (choice !== "Yes") {
				return { block: true, reason: "Blocked by user" };
			}
		}

		return undefined;
	});
}
