# herdr plugin hook: give every git workspace one "review" tab running hunk.
#
# herdr runs this for workspace.created, worktree.created and worktree.opened.
# It exits 0 and does nothing unless the workspace's directory is a git work
# tree that has no tab labelled "review" yet.
#
# The hook's own PWD is the plugin root, not the workspace, so the directory to
# inspect comes from HERDR_PLUGIN_CONTEXT_JSON.workspace_cwd (verified against
# herdr 0.9.1). git and jq are on PATH via the wrapper in ../shared/herdr.nix;
# herdr is at HERDR_BIN_PATH; hunk is resolved by the new tab's own shell.

# Tab icon, matching the sessionizer's Nerd Font labels (see the ICON_* block
# in modules/scripts/herdr-sessionizer). Built from its UTF-8 bytes so the glyph
# survives editing and old shells; override with HERDR_ICON_REVIEW if you prefer
# a different one -- the lookup below does not depend on it.
ICON_REVIEW="${HERDR_ICON_REVIEW:-$(printf '\357\221\200')}"   # nf-oct-diff (U+F440)
LABEL="$ICON_REVIEW Review"
herdr_bin="${HERDR_BIN_PATH:-herdr}"

ctx="${HERDR_PLUGIN_CONTEXT_JSON:-}"
[ -n "$ctx" ] || exit 0

workspace="${HERDR_WORKSPACE_ID:-}"
[ -n "$workspace" ] || workspace=$(jq -r '.workspace_id // empty' <<<"$ctx")
cwd=$(jq -r '.workspace_cwd // .focused_pane_cwd // empty' <<<"$ctx")

[ -n "$workspace" ] || exit 0
[ -n "$cwd" ] || exit 0
[ -d "$cwd" ] || exit 0

cd "$cwd" || exit 0

# Not a git work tree -> no review tab. --is-inside-work-tree prints "false"
# rather than failing when we are inside a bare repo or a .git directory.
[ "$(git rev-parse --is-inside-work-tree 2>/dev/null || true)" = "true" ] || exit 0

# `herdr worktree create` fires worktree.created and workspace.created, so two
# hooks can race for the same workspace. Serialise per workspace: the loser
# exits and lets the winner's tab stand.
lock_root="${HERDR_PLUGIN_STATE_DIR:-${TMPDIR:-/tmp}}"
lockdir="$lock_root/review-lock-$workspace"
mkdir -p "$lock_root"
# Clear a lock orphaned by a killed hook rather than blocking forever.
if [ -d "$lockdir" ] && [ -z "$(find "$lockdir" -maxdepth 0 -mmin -1 2>/dev/null)" ]; then
    rmdir "$lockdir" 2>/dev/null || true
fi
mkdir "$lockdir" 2>/dev/null || exit 0
trap 'rmdir "$lockdir" 2>/dev/null || true' EXIT

# Identify the tab by label, never by position -- and by the word rather than
# the exact string, so a re-iconed LABEL (or a tab created before the label had
# an icon) still counts as "already reviewed" instead of earning a second tab.
if "$herdr_bin" tab list --workspace "$workspace" |
    jq -e '[.result.tabs[]? | select(.label | ascii_downcase | contains("review"))] | length > 0' >/dev/null; then
    exit 0
fi

# A linked worktree's git-dir sits under <common>/worktrees/<name>; in a main
# checkout the two resolve to the same directory. git-common-dir comes back
# relative there (".git"), so resolve both before comparing.
git_dir=$(git rev-parse --absolute-git-dir)
common_dir=$(cd "$(git rev-parse --git-common-dir)" && pwd)

target=""
if [ "$git_dir" != "$common_dir" ]; then
    # Linked worktree: diff against the repo's default branch so committed work
    # on the branch stays visible, not just uncommitted edits. Detected, never
    # hardcoded -- origin/HEAD first, then whichever conventional name exists.
    base=""
    if ref=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null); then
        base="${ref#origin/}"
    else
        for candidate in main master trunk; do
            if git show-ref --verify --quiet "refs/heads/$candidate"; then
                base="$candidate"
                break
            fi
        done
    fi
    # Nothing to compare against when the worktree is on the default branch.
    if [ -n "$base" ] && [ "$base" != "$(git branch --show-current)" ]; then
        target="$base"
    fi
fi

if [ -n "$target" ]; then
    hunk_cmd="hunk diff $target --watch"
else
    hunk_cmd="hunk diff --watch"
fi

# `tab create` only makes the tab and its shell -- it has no flag to run a
# command -- so the command is a second call against the returned root pane.
pane=$("$herdr_bin" tab create \
    --workspace "$workspace" --cwd "$cwd" --label "$LABEL" --no-focus |
    jq -r '.result.root_pane.pane_id // empty')
[ -n "$pane" ] || exit 1

"$herdr_bin" pane run "$pane" "$hunk_cmd"
