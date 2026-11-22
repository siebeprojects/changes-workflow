#!/usr/bin/env bash
# Install the changes workflow (agent rules, the changes-workflow skill, the
# settings and the change templates) into a repository.
#
# The skill holds all the rules. AGENTS.md only gets a short pointer to it, in a
# block between <!-- changes-workflow:start --> and <!-- changes-workflow:end -->:
# a new AGENTS.md gets only that block; in an existing one only the block is
# added or replaced, and everything else is kept. CLAUDE.md only imports
# AGENTS.md (@AGENTS.md). .claude/skills/ only holds a symlink to the skill in
# .agents/skills/.
#
# .changes-workflow/ holds the settings and the templates, and shows that a
# repository uses the workflow:
#   config.yml   `store:` is the store's changes folder, relative to the
#                repository, and `repository:` is its name in the store: its
#                qa.md and tasks.md go in <store>/<name>/<repository>/.
#   templates/   the document templates.
# Every repository has one, the store too, so a change to the store itself also
# gets a subfolder.
#
# The store holds only a folder for each change (changes/<name>/: proposal.md,
# spec.md, plan.md, and qa.md and tasks.md for each repository where it is
# built). This script writes nothing in it.
#
# The ways of working (.changes-workflow/, the skill and its link, and any
# AGENTS.md or CLAUDE.md this script creates) are never committed: they are
# always excluded privately through .git/info/exclude. Only the pointer block in
# an AGENTS.md, and the import line in a CLAUDE.md, that the repository already
# commits end up in git.
#
# --repo <dir>: the repository is its own store; other repositories can use it
# as their store too.
# --repo <dir> --store <dir>: the repository uses that store, and Claude Code
# gets access to it. There is no --store alone: to work in the store itself,
# install it with --repo <store>.
#
# Usage: ./install.sh [--force] [--dry-run] --repo <dir> [--store <dir>]

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL="changes-workflow"
START_MARK="<!-- changes-workflow:start -->"
END_MARK="<!-- changes-workflow:end -->"
FORCE=0
DRY_RUN=0
REPO=""
STORE=""
CHANGES="changes"
DIR=".changes-workflow"
SETTINGS="$DIR/config.yml"
OLD_SETTINGS=".changes-workflow.yml"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--force] [--dry-run] --repo <dir> [--store <dir>]

Installs the changes workflow:
  --repo <dir>                a repository that is its own store (others can use it too)
  --repo <dir> --store <dir>  a repository that uses that store

What is installed:
  $SETTINGS   the settings: the store, and this repository's name in it
  $DIR/templates/      the document templates
  AGENTS.md                      a pointer to the skill in a marked block (rest of the file is kept)
  CLAUDE.md                      imports AGENTS.md
  .agents/skills/$SKILL/         the skill with all the rules, linked from .claude/skills/$SKILL

The ways of working are never committed: everything is excluded privately
through .git/info/exclude. Nothing is written in the store. With --store,
Claude Code gets access to it through .claude/settings.local.json.

When a file already exists and differs, you are asked whether to overwrite
it. Without a terminal (e.g. CI), conflicting files are skipped.

Options:
  --repo <dir>      The repository to install into
  --store <dir>     The store it uses, when it is not its own store
  --force           Overwrite files that differ without asking
  --dry-run         Show what would happen without changing anything
  -h, --help        Show this help
EOF
}

# The value of an option such as --repo, or exit when it is missing.
option_value() {
  if [ $# -lt 2 ] || [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
    echo "$1 needs a folder" >&2; exit 1
  fi
  printf '%s\n' "$2"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --force) FORCE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --repo) REPO="$(option_value "$@")"; shift ;;
    --repo=*) REPO="${1#--repo=}" ;;
    --store) STORE="$(option_value "$@")"; shift ;;
    --store=*) STORE="${1#--store=}" ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    *) echo "Name the folder with --repo or --store: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

if [ -z "$REPO" ]; then
  if [ -n "$STORE" ]; then
    echo "--store needs --repo: use --repo <dir> --store <store> for a repository that uses the store," >&2
    echo "or --repo <store> to work in the store itself." >&2
    exit 1
  fi
  usage >&2; exit 1
fi

# The absolute path of a folder, or exit when it is not one.
folder() {
  if [ ! -d "$1" ]; then echo "Error: '$1' is not a folder" >&2; exit 1; fi
  (cd "$1" && pwd -P)
}

# The path from folder $1 to path $2, both absolute, such as ../store/changes.
relative_path() {
  local from="$1" to="$2" up="" rest
  while true; do
    case "$to/" in "$from"/*) break ;; esac
    if [ "$from" = "/" ]; then break; fi
    from="$(dirname "$from")"; up="../$up"
  done
  rest="${to#"$from"}"; rest="${rest#/}"
  rest="$up$rest"; rest="${rest%/}"
  printf '%s\n' "${rest:-.}"
}

# The repository installed into, and its store when it isn't its own store.
TARGET="$(folder "$REPO")"
if [ -n "$STORE" ]; then STORE="$(folder "$STORE")"; fi
if [ "$TARGET" = "$SRC" ] || [ "$STORE" = "$SRC" ]; then
  echo "Error: cannot install into this repository itself" >&2; exit 1
fi

EXTERNAL_CHANGES=0
CHANGES_ABS=""
if [ -n "$STORE" ]; then
  if [ "$TARGET" = "$STORE" ]; then
    echo "Error: --repo and --store are the same folder; use --repo alone" >&2; exit 1
  fi
  EXTERNAL_CHANGES=1
  CHANGES="$(relative_path "$TARGET" "$STORE/changes")"
  CHANGES_ABS="$STORE/changes"
  # Nothing is written in the store, so a mistyped path would go unnoticed.
  if ! git -C "$STORE" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Warning: the store $STORE is not a git repository; check the --store path."
  fi
fi

# Files to install are staged in a temporary folder, together with the
# generated settings, before they are compared with and copied to the
# repository. Other temporary files go there too, so the trap
# removes them on any exit.
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
(cd "$SRC" && find AGENTS.md CLAUDE.md ".agents/skills/$SKILL" templates -type f ! -name '.DS_Store') |
  while IFS= read -r f; do
    dst="$f"
    case "$f" in templates/*) dst="$DIR/$f" ;; esac
    mkdir -p "$STAGE/$(dirname "$dst")"
    cp -p "$SRC/$f" "$STAGE/$dst"
  done

# The settings the skill reads. Every repository, the store too, has a name in
# the store: its folder name.
{
  echo "# Written by changes-workflow's install.sh: this repository uses the changes workflow."
  echo "# The store's folder with a folder for each change."
  echo "store: \"$CHANGES\""
  echo "# This repository's name in the store: its qa.md and tasks.md go in <store>/<change>/<repository>/."
  echo "repository: \"$(basename "$TARGET")\""
} > "$STAGE/$SETTINGS"

# An AGENTS.md or CLAUDE.md that exists before installing belongs to the
# repository: it is not excluded from git, so the added block or line is
# committed with it.
AGENTS_EXISTED=0; [ -e "$TARGET/AGENTS.md" ] && AGENTS_EXISTED=1
CLAUDE_EXISTED=0; [ -e "$TARGET/CLAUDE.md" ] && CLAUDE_EXISTED=1

IS_GIT=0
if git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  IS_GIT=1
else
  echo "Warning: $TARGET is not a git repository; changes cannot be reviewed with git diff."
fi

COPIED=0; SKIPPED=0; UNCHANGED=0
# One skipped file per line, so labels may contain spaces.
SKIPPED_LIST=""

# Run a command, unless in dry-run mode (the action is already reported).
run() {
  if [ "$DRY_RUN" -eq 0 ]; then "$@"; fi
}

# Remove an existing path before it is replaced. Removing it first, instead of
# copying over it, also replaces a symlink or folder instead of writing through
# it. No copy is kept.
remove_existing() {
  local path="$1" label="$2"
  echo "  remove   $label"
  run rm -rf "$path"
}

# Ask questions only when a terminal is available and no answer is implied
# by --force or --dry-run. Prompts read from /dev/tty.
INTERACTIVE=0
if [ "$FORCE" -eq 0 ] && [ "$DRY_RUN" -eq 0 ] && { : </dev/tty; } 2>/dev/null; then
  INTERACTIVE=1
fi
OVERWRITE_ALL="$FORCE"

# Show how an existing target differs from what would be installed.
show_diff() {
  local src="$1" dst="$2"
  if [ -L "$dst" ]; then
    echo "    existing is a symlink -> $(readlink "$dst")"
  elif [ -d "$dst" ]; then
    diff -ru "$dst" "$src" || true
  else
    diff -u "$dst" "$src" || true
  fi
}

# Decide what to do with an existing target that differs.
# Returns 0 to overwrite, 1 to skip; exits on "quit".
resolve_conflict() {
  local label="$1" src="$2" dst="$3" answer
  [ "$OVERWRITE_ALL" -eq 1 ] && return 0
  [ "$INTERACTIVE" -eq 1 ] || return 1
  while true; do
    {
      echo "  conflict $label already exists and differs."
      printf '           Overwrite? [y]es / [n]o / [d]iff / [a]ll / [q]uit (default: n): '
    } >/dev/tty
    read -r answer </dev/tty || answer="n"
    case "$answer" in
      y|Y|yes) return 0 ;;
      ""|n|N|no) return 1 ;;
      d|D|diff) show_diff "$src" "$dst" >/dev/tty ;;
      a|A|all) OVERWRITE_ALL=1; return 0 ;;
      q|Q|quit)
        echo "  quit     installation stopped; files already installed are kept."
        update_exclude
        print_summary
        exit 1 ;;
      *) echo "           Please answer y, n, d, a or q." >/dev/tty ;;
    esac
  done
}

# Record a skipped target for the summary.
skip() {
  echo "  skip     $1 (exists and differs)"
  SKIPPED=$((SKIPPED + 1)); SKIPPED_LIST="$SKIPPED_LIST$1"$'\n'
}

# Copy one file (path relative to the repository) from STAGE to the repository.
copy_file() {
  local rel="$1"
  local src="$STAGE/$rel" dst="$TARGET/$rel" label="$rel"
  if [ -e "$dst" ]; then
    if cmp -s "$src" "$dst"; then
      UNCHANGED=$((UNCHANGED + 1)); return
    fi
    if ! resolve_conflict "$label" "$src" "$dst"; then skip "$label"; return; fi
    remove_existing "$dst" "$label"
  fi
  echo "  copy     $label"
  run mkdir -p "$(dirname "$dst")"
  run cp -p "$src" "$dst"
  COPIED=$((COPIED + 1))
}

# Print the workflow block (markers included) from a file.
extract_block() {
  awk -v s="$START_MARK" -v e="$END_MARK" '
    $0 == s { inside = 1 }
    inside { print }
    $0 == e { inside = 0 }
  ' "$1"
}

# AGENTS.md: create it with only the workflow block, or add/replace only the
# workflow block in an existing file.
install_agents_md() {
  local src="$STAGE/AGENTS.md" dst="$TARGET/AGENTS.md" block tmp
  block="$STAGE/agents-block.md"; tmp="$STAGE/agents-new.md"
  extract_block "$src" > "$block"

  if [ ! -e "$dst" ]; then
    # Only the workflow block: the repository's own rules are its owner's choice.
    echo "  create   AGENTS.md (workflow block only)"
    if [ "$DRY_RUN" -eq 0 ]; then cat "$block" > "$dst"; fi
    COPIED=$((COPIED + 1))
  elif grep -qxF "$START_MARK" "$dst" && grep -qxF "$END_MARK" "$dst"; then
    # Replace the existing block, keep everything around it.
    awk -v s="$START_MARK" -v e="$END_MARK" -v bf="$block" '
      $0 == s { while ((getline line < bf) > 0) print line; skipping = 1; next }
      skipping && $0 == e { skipping = 0; next }
      !skipping { print }
    ' "$dst" > "$tmp"
    if cmp -s "$tmp" "$dst"; then
      UNCHANGED=$((UNCHANGED + 1))
    else
      echo "  update   AGENTS.md (workflow block replaced; rest kept)"
      if [ "$DRY_RUN" -eq 0 ]; then cat "$tmp" > "$dst"; fi
      COPIED=$((COPIED + 1))
    fi
  elif grep -qxF "## Change documentation" "$dst"; then
    # An AGENTS.md from an earlier version without markers: replace its
    # "## Change documentation" section, up to the next "## " heading, with the
    # block instead of adding a second copy, and keep everything else.
    awk -v bf="$block" '
      $0 == "## Change documentation" { while ((getline line < bf) > 0) print line; skipping = 1; next }
      skipping && /^## / { skipping = 0; print "" }
      !skipping { print }
    ' "$dst" > "$tmp"
    if resolve_conflict "AGENTS.md (earlier version, no workflow markers)" "$tmp" "$dst"; then
      echo "  update   AGENTS.md (old workflow section replaced by the block; rest kept)"
      if [ "$DRY_RUN" -eq 0 ]; then cat "$tmp" > "$dst"; fi
      COPIED=$((COPIED + 1))
    else
      skip "AGENTS.md"
    fi
  else
    # The repository's own AGENTS.md: append the block.
    echo "  update   AGENTS.md (workflow block added at the end; rest kept)"
    if [ "$DRY_RUN" -eq 0 ]; then
      {
        if [ -s "$dst" ] && [ -n "$(tail -c 1 "$dst")" ]; then echo; fi
        echo
        cat "$block"
      } >> "$dst"
    fi
    COPIED=$((COPIED + 1))
  fi
}

# CLAUDE.md: copy if missing; otherwise make sure it imports AGENTS.md
# without discarding the target's existing Claude-specific content.
install_claude_md() {
  local dst="$TARGET/CLAUDE.md"
  if [ ! -e "$dst" ]; then copy_file "CLAUDE.md"; return; fi
  if grep -qxF '@AGENTS.md' "$dst"; then UNCHANGED=$((UNCHANGED + 1)); return; fi
  echo "  update   CLAUDE.md (prepend @AGENTS.md import; existing content kept)"
  if [ "$DRY_RUN" -eq 0 ]; then
    local tmp="$STAGE/claude-new.md"
    { printf '@AGENTS.md\n\n'; cat "$dst"; } > "$tmp"
    cat "$tmp" > "$dst"   # keep original file permissions
  fi
  COPIED=$((COPIED + 1))
}

# Link .claude/skills/<skill> -> ../../.agents/skills/<skill> (relative, portable).
link_skill() {
  local link="$TARGET/.claude/skills/$SKILL" want="../../.agents/skills/$SKILL"
  if [ -L "$link" ] && [ "$(readlink "$link")" = "$want" ]; then
    UNCHANGED=$((UNCHANGED + 1)); return
  fi
  if [ -e "$link" ] || [ -L "$link" ]; then
    if ! resolve_conflict ".claude/skills/$SKILL" "$STAGE/.agents/skills/$SKILL" "$link"; then
      skip ".claude/skills/$SKILL"; return
    fi
    remove_existing "$link" ".claude/skills/$SKILL"
  fi
  echo "  link     .claude/skills/$SKILL -> $want"
  run mkdir -p "$TARGET/.claude/skills"
  run ln -s "$want" "$link"
  COPIED=$((COPIED + 1))
}

# Mention skills installed by earlier versions; they are not removed.
report_old_skills() {
  local name
  for name in plan-change implement-change; do
    if [ -e "$TARGET/.agents/skills/$name" ] || [ -L "$TARGET/.claude/skills/$name" ]; then
      echo "  note     old skill '$name' found; $SKILL replaces it. Remove .agents/skills/$name and .claude/skills/$name."
    fi
  done
}

# Earlier versions wrote the settings to .changes-workflow.yml, which
# $SETTINGS replaces: remove it. It was written by this script and never
# committed.
remove_old_settings() {
  [ -f "$TARGET/$OLD_SETTINGS" ] || return 0
  remove_existing "$TARGET/$OLD_SETTINGS" "$OLD_SETTINGS (replaced by $SETTINGS)"
}

# Mention templates put in changes/_templates/ by earlier versions, in the
# repository or its store; the templates now live in $DIR/templates/. They are
# not removed: they may be committed.
report_old_templates() {
  local root
  for root in "$TARGET" ${STORE:+"$STORE"}; do
    if [ -d "$root/changes/_templates" ]; then
      echo "  note     $root/changes/_templates/ found; the templates now live in $DIR/templates/. Remove it, from git too."
    fi
  done
}

# Give Claude Code access to an external changes folder. Only creates the
# local settings file; an existing one is not edited, only reported.
install_claude_settings() {
  [ "$EXTERNAL_CHANGES" -eq 1 ] || return 0
  local file="$TARGET/.claude/settings.local.json"
  if [ -e "$file" ]; then
    if grep -qsF "\"$CHANGES_ABS\"" "$file"; then UNCHANGED=$((UNCHANGED + 1)); return; fi
    echo "  note     .claude/settings.local.json exists; add this to permissions.additionalDirectories:"
    echo "           \"$CHANGES_ABS\""
    return
  fi
  echo "  create   .claude/settings.local.json (access to $CHANGES_ABS)"
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$TARGET/.claude"
    printf '{\n  "permissions": {\n    "additionalDirectories": ["%s"]\n  }\n}\n' "$CHANGES_ABS" > "$file"
  fi
  COPIED=$((COPIED + 1))
}

print_summary() {
  echo
  echo "Done: $COPIED installed/updated, $UNCHANGED already up to date, $SKIPPED skipped."
  if [ "$SKIPPED" -gt 0 ]; then
    echo "Skipped (review and merge manually, or rerun to overwrite):"
    printf '%s' "$SKIPPED_LIST" | while IFS= read -r s; do echo "  - $s"; done
  fi
}

# Privately ignore the ways of working by adding root-anchored patterns to
# .git/info/exclude (never committed). AGENTS.md and CLAUDE.md are only
# excluded when this script created them: in the repository's own files, only
# the pointer block and the import line end up in git. Lines for files of
# earlier versions are removed.
update_exclude() {
  if [ "$IS_GIT" -eq 0 ]; then
    echo "  note     not a git repository; skipping .git/info/exclude"
    return 0
  fi

  # --git-path also resolves correctly for worktrees and submodules.
  local file
  file="$(git -C "$TARGET" rev-parse --git-path info/exclude)"
  case "$file" in /*) ;; *) file="$TARGET/$file" ;; esac

  local patterns="/$DIR/ /.agents/skills/$SKILL/ /.claude/skills/$SKILL"
  if [ "$AGENTS_EXISTED" -eq 0 ]; then
    patterns="/AGENTS.md $patterns"
  elif ! grep -qsxF -- "/AGENTS.md" "$file"; then
    echo "  note     AGENTS.md belongs to the repository; not excluded (only the pointer block is added)"
  fi
  [ "$CLAUDE_EXISTED" -eq 0 ] && patterns="/CLAUDE.md $patterns"
  [ "$EXTERNAL_CHANGES" -eq 1 ] && patterns="$patterns /.claude/settings.local.json"

  local old
  for old in "/$OLD_SETTINGS" "/changes/_templates/"; do
    if grep -qsxF -- "$old" "$file"; then
      echo "  include  $old (removed from .git/info/exclude)"
      if [ "$DRY_RUN" -eq 0 ]; then
        grep -vxF -- "$old" "$file" > "$file.tmp" || true
        mv "$file.tmp" "$file"
      fi
    fi
  done

  local p missing="" path
  for p in $patterns; do
    path="${p#/}"; path="${path%/}"
    if [ -n "$(git -C "$TARGET" ls-files -- "$path" | head -n 1)" ]; then
      echo "  note     $path is tracked by git, so it can't be excluded; remove it from git to keep it local"
      continue
    fi
    grep -qsxF -- "$p" "$file" || missing="$missing $p"
  done

  if [ -z "$missing" ]; then
    echo "  exclude  .git/info/exclude already up to date"
    return 0
  fi
  for p in $missing; do echo "  exclude  $p"; done
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$(dirname "$file")"
    {
      if [ -s "$file" ] && [ -n "$(tail -c 1 "$file")" ]; then echo; fi
      grep -qsxF '# changes-workflow (added by install.sh)' "$file" \
        || echo '# changes-workflow (added by install.sh)'
      for p in $missing; do echo "$p"; done
    } >> "$file"
  fi
}

echo "Installing the changes workflow"
echo "  from: $SRC"
echo "  into: $TARGET"
[ "$EXTERNAL_CHANGES" -eq 1 ] && echo "  store: $STORE (changes: $CHANGES)"
echo "  repository: $(basename "$TARGET")"
[ "$DRY_RUN" -eq 1 ] && echo "  mode: dry-run (no changes will be made)"
echo

# 1. Settings and templates, the pointer in AGENTS.md and the Claude Code import.
while IFS= read -r f; do
  copy_file "${f#$STAGE/}"
done < <(find "$STAGE/$DIR" -type f | sort)
remove_old_settings
install_agents_md
install_claude_md

# 2. The skill.
while IFS= read -r f; do
  copy_file "${f#$STAGE/}"
done < <(find "$STAGE/.agents/skills/$SKILL" -type f | sort)
link_skill
report_old_skills
report_old_templates
install_claude_settings

# 3. Keep the agent files out of git, privately.
update_exclude

print_summary
if [ "$DRY_RUN" -eq 0 ]; then
  echo
  echo "Next steps:"
  if [ "$EXTERNAL_CHANGES" -eq 1 ]; then
    echo "  1. Review $DIR/, AGENTS.md and .agents/skills/$SKILL/."
    echo "  2. Each change has its folder in $CHANGES; this repository's qa.md and tasks.md"
    echo "     go in its subfolder $(basename "$TARGET")/."
  else
    echo "  1. Review $DIR/, AGENTS.md and .agents/skills/$SKILL/."
    echo "  2. Start a change: mkdir changes/feat-short-name and copy $DIR/templates/proposal.md into it."
  fi
fi
