#!/usr/bin/env bash
# Tests install.sh in throwaway repositories: a store, repositories that use it,
# and a repository that is its own store. Run: tests/install.sh
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
FAILED=0
newrepo() { mkdir -p "$T/$1"; git -C "$T/$1" init -q; }
ok() { if eval "$2" 2>/dev/null; then echo "ok:   $1"; else echo "FAIL: $1"; FAILED=$((FAILED + 1)); fi; }
for d in store web-app docs-site single; do newrepo $d; done

ok "syntax" 'bash -n "$SRC/install.sh"'
ok "removed option --no-exclude is unknown" '! "$SRC/install.sh" --no-exclude --repo "$T/web-app" --store "$T/store" </dev/null >/dev/null 2>&1'
ok "--store alone is refused" '! "$SRC/install.sh" --store "$T/store" </dev/null >/dev/null 2>&1'

echo "=== code repo, dry run"
"$SRC/install.sh" --dry-run --repo "$T/web-app" --store "$T/store" </dev/null > "$T/dry.txt"
ok "dry run shows the templates" 'grep -q "copy     .changes-workflow/templates/qa.md" "$T/dry.txt"'
ok "dry run writes nothing in the repo" '[ ! -e "$T/web-app/.changes-workflow" ] && [ ! -e "$T/web-app/AGENTS.md" ]'
ok "dry run shows the store setup" 'grep -q "^Setting up the store itself" "$T/dry.txt"'
ok "dry run writes nothing in the store" '[ -z "$(ls -A "$T/store" | grep -vx .git)" ]'

echo "=== code repo"
"$SRC/install.sh" --repo "$T/web-app" --store "$T/store" </dev/null >/dev/null
cat "$T/web-app/.changes-workflow/config.yml"
ok "settings: store path" 'grep -qxF "store: \"../store/changes\"" "$T/web-app/.changes-workflow/config.yml"'
ok "settings: repository name" 'grep -qxF "repository: \"web-app\"" "$T/web-app/.changes-workflow/config.yml"'
ok "templates identical to the source" 'diff -r "$SRC/templates" "$T/web-app/.changes-workflow/templates" >/dev/null'
ok "no changes folder in code repo" '[ ! -d "$T/web-app/changes" ]'
ok "the store is set up as its own store" '[ "$(grep -v "^#" "$T/store/.changes-workflow/config.yml" | tr "\n" " ")" = "store: \"changes\" repository: \"store\" " ]'
ok "the store has the skill and templates" '[ -f "$T/store/.agents/skills/changes-workflow/SKILL.md" ] && diff -r "$SRC/templates" "$T/store/.changes-workflow/templates" >/dev/null'
ok "git sees nothing in the store (all excluded)" '[ -z "$(git -C "$T/store" status --porcelain)" ]'
ok "the store gets no Claude settings" '[ ! -e "$T/store/.claude/settings.local.json" ]'

echo "=== working in the store itself"
"$SRC/install.sh" --repo "$T/store" </dev/null >/dev/null
ok "store settings: store: changes and repository: store" '[ "$(grep -v "^#" "$T/store/.changes-workflow/config.yml" | tr "\n" " ")" = "store: \"changes\" repository: \"store\" " ]'
ok "git sees nothing in the store (all excluded)" '[ -z "$(git -C "$T/store" status --porcelain)" ]'
ok "AGENTS.md is only the pointer block" '[ "$(head -1 "$T/web-app/AGENTS.md")" = "<!-- changes-workflow:start -->" ] && [ "$(wc -l < "$T/web-app/AGENTS.md" | tr -d " ")" = 4 ]'
ok "skill identical to the source" 'diff -r "$SRC/.agents/skills/changes-workflow" "$T/web-app/.agents/skills/changes-workflow" >/dev/null'
ok "git sees nothing (all excluded)" '[ -z "$(git -C "$T/web-app" status --porcelain)" ]'
ok "rerun is up to date, repo and store" '[ "$("$SRC/install.sh" --repo "$T/web-app" --store "$T/store" </dev/null | grep -c "^Done: 0 installed")" = 2 ]'
ok "next steps shown once" '[ "$("$SRC/install.sh" --repo "$T/web-app" --store "$T/store" </dev/null | grep -c "^Next steps:")" = 1 ]'

echo "=== code repo with committed AGENTS.md and CLAUDE.md"
printf '# Our rules\n- Be kind.\n' > "$T/docs-site/AGENTS.md"; printf '# Docs\n' > "$T/docs-site/CLAUDE.md"
git -C "$T/docs-site" add AGENTS.md CLAUDE.md; git -C "$T/docs-site" -c user.name=t -c user.email=t@t commit -qm init
"$SRC/install.sh" --repo "$T/docs-site" --store "$T/store" </dev/null >/dev/null
ok "own rules kept" 'head -1 "$T/docs-site/AGENTS.md" | grep -q "Our rules"'
ok "pointer block added" 'grep -qxF "<!-- changes-workflow:start -->" "$T/docs-site/AGENTS.md"'
ok "git shows only AGENTS.md and CLAUDE.md as changed" '[ "$(git -C "$T/docs-site" status --porcelain | sort | tr "\n" " ")" = " M AGENTS.md  M CLAUDE.md " ]'
ok "repository name is the folder name" 'grep -qxF "repository: \"docs-site\"" "$T/docs-site/.changes-workflow/config.yml"'

echo "=== earlier install with the long block -> replaced by the pointer"
newrepo old
printf '# Rules\n\n<!-- changes-workflow:start -->\n## Change documentation\n- OLD RULE\n<!-- changes-workflow:end -->\n' > "$T/old/AGENTS.md"
"$SRC/install.sh" --repo "$T/old" --store "$T/store" </dev/null >/dev/null
ok "old block replaced" '! grep -q "OLD RULE" "$T/old/AGENTS.md" && grep -q "## Changes workflow" "$T/old/AGENTS.md"'

echo "=== changed skill file: skipped without a terminal, overwritten with --force"
echo "local edit" >> "$T/web-app/.agents/skills/changes-workflow/planning.md"
ok "skipped without a terminal" '"$SRC/install.sh" --repo "$T/web-app" --store "$T/store" </dev/null | grep -q "skip .*planning.md"'
"$SRC/install.sh" --force --repo "$T/web-app" --store "$T/store" </dev/null >/dev/null
ok "overwritten with --force" 'cmp -s "$SRC/.agents/skills/changes-workflow/planning.md" "$T/web-app/.agents/skills/changes-workflow/planning.md"'
ok "no backup folder" '[ ! -e "$T/web-app/.changes-workflow-backup" ]'

echo "=== self-contained repo"
"$SRC/install.sh" --repo "$T/single" </dev/null >/dev/null
ok "settings: store: changes and its repository" '[ "$(grep -v "^#" "$T/single/.changes-workflow/config.yml" | tr "\n" " ")" = "store: \"changes\" repository: \"single\" " ]'
ok "has the templates" '[ -f "$T/single/.changes-workflow/templates/tasks.md" ]'
ok "git sees nothing (all excluded)" '[ -z "$(git -C "$T/single" status --porcelain)" ]'

echo "=== a repo that uses a code repo as its store"
newrepo other
"$SRC/install.sh" --repo "$T/other" --store "$T/single" </dev/null >/dev/null
ok "settings point to the code repo's changes" 'grep -qxF "store: \"../single/changes\"" "$T/other/.changes-workflow/config.yml" && grep -qxF "repository: \"other\"" "$T/other/.changes-workflow/config.yml"'

echo "=== earlier install with .changes-workflow.yml and templates in the store"
newrepo legacy-store; newrepo legacy
mkdir -p "$T/legacy-store/changes/_templates"; cp "$SRC/templates/qa.md" "$T/legacy-store/changes/_templates/"
printf 'store: "../legacy-store/changes"\nrepository: "legacy"\n' > "$T/legacy/.changes-workflow.yml"
mkdir -p "$T/legacy/.git/info"; printf '/.changes-workflow.yml\n/changes/_templates/\n' >> "$T/legacy/.git/info/exclude"
"$SRC/install.sh" --repo "$T/legacy" --store "$T/legacy-store" </dev/null > "$T/legacy.txt"
ok "old settings file removed" '[ ! -e "$T/legacy/.changes-workflow.yml" ] && [ -f "$T/legacy/.changes-workflow/config.yml" ]'
ok "old exclude lines removed" '! grep -qxF "/.changes-workflow.yml" "$T/legacy/.git/info/exclude" && ! grep -qxF "/changes/_templates/" "$T/legacy/.git/info/exclude"'
ok "new folder excluded" 'grep -qxF "/.changes-workflow/" "$T/legacy/.git/info/exclude"'
ok "old templates in the store mentioned, not removed" 'grep -q "legacy-store/changes/_templates/ found" "$T/legacy.txt" && [ -f "$T/legacy-store/changes/_templates/qa.md" ]'

echo "=== review fixes"
echo "changed" >> "$T/web-app/.changes-workflow/templates/qa.md"
"$SRC/install.sh" --repo "$T/web-app" --store "$T/store" </dev/null > "$T/skip.txt"
ok "skipped template is one line in the summary" 'grep -qxF "  - .changes-workflow/templates/qa.md" "$T/skip.txt"'
mkdir -p "$T/not-a-repo"
ok "warns when the store is not a git repository" '"$SRC/install.sh" --dry-run --repo "$T/web-app" --store "$T/not-a-repo" </dev/null | grep -q "is not a git repository; check the --store path"'
before=$(ls "${TMPDIR:-/tmp}" | wc -l)
"$SRC/install.sh" --repo "$T/docs-site" --store "$T/store" </dev/null >/dev/null
after=$(ls "${TMPDIR:-/tmp}" | wc -l)
ok "no temporary files left behind" '[ "$before" = "$after" ]'

echo
if [ "$FAILED" -gt 0 ]; then echo "$FAILED check(s) failed."; exit 1; fi
echo "All checks passed."
