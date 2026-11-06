/**
 * Triggers Extension
 *
 * pi shows tool calls in the transcript, but a skill load is just a `read` of
 * some SKILL.md and an MCP call made from a codemode script never appears
 * there at all. This calls out both as a notice in the transcript and a
 * running tally in the footer (the powerline footer's extension_statuses
 * segment). Subagents are left out: pi-subagents already names the agent in
 * its own transcript line.
 *
 * Nested calls (codemode -> ctx.executeTool) go through tool_call as well, so
 * MCP tools reached via codemode or tool_search are caught too.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// `.../skills/<name>/SKILL.md` -> <name>
const skillName = (path: string): string | undefined =>
	path.match(/([^/\\]+)[/\\]SKILL\.md$/i)?.[1];

export default function (pi: ExtensionAPI) {
	const skills = new Set<string>();
	const mcp = new Map<string, number>();

	const render = (ctx: { ui: { setStatus(key: string, text: string | undefined): void } }) => {
		const parts: string[] = [];
		if (skills.size) parts.push(`skills: ${[...skills].join(", ")}`);
		if (mcp.size) parts.push(`mcp: ${[...mcp].map(([s, n]) => (n > 1 ? `${s}×${n}` : s)).join(", ")}`);
		ctx.ui.setStatus("triggers", parts.length ? parts.join(" · ") : undefined);
	};

	pi.on("session_start", async (_event, ctx) => {
		skills.clear();
		mcp.clear();
		if (ctx.hasUI) render(ctx);
	});

	pi.on("tool_call", async (event, ctx) => {
		if (!ctx.hasUI) return undefined;
		const input = event.input as Record<string, unknown>;

		// Skills: the model loads one by reading its SKILL.md (or, rarely, cat-ing it).
		const path =
			event.toolName === "read"
				? (input.path as string | undefined)
				: event.toolName === "bash"
					? (input.command as string | undefined)?.match(/\S*SKILL\.md/i)?.[0]
					: undefined;
		const skill = path && skillName(path);
		if (skill) {
			ctx.ui.notify(`▸ skill: ${skill}`, "info");
			skills.add(skill);
			render(ctx);
			return undefined;
		}

		// MCP: tools are registered as mcp__<server>__<tool>.
		const m = event.toolName.match(/^mcp__(.+?)__(.+)$/);
		if (m) {
			const [, server, tool] = m;
			ctx.ui.notify(`▸ mcp: ${server} › ${tool}`, "info");
			mcp.set(server, (mcp.get(server) ?? 0) + 1);
			render(ctx);
		}

		return undefined;
	});
}
