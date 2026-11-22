# changes-workflow

A small workflow for building software with AI agents: think first, build small. Each change gets a few short documents, and agents plan, build and review from them.

## How it works

All documents of a change live in one folder in the store, with a subfolder for each repository where it's built:

```
changes/feat-short-name/
├── proposal.md     why and what (for a fix: steps to reproduce)
├── spec.md         acceptance criteria and requirements
├── plan.md         what must exist, and the decisions
└── web-app/
    ├── qa.md       how it's verified in web-app
    └── tasks.md    the tasks for web-app, built one at a time
```

The store is a repository of its own, or a code repository that is its own store. Only the change folders are committed there. Code repositories hold only code.

Each repository, the store too, gets the ways of working locally, never committed:

```
.changes-workflow/
├── config.yml      where the store is, and this repository's name in it
└── templates/      the document templates
.agents/skills/changes-workflow/    the skill with all the rules, linked from .claude/skills/ for Claude Code
AGENTS.md                           a short block that points agents to the skill
```

```yaml
store: "../my-changes-store/changes"
repository: "web-app"
```

Start your agent in the repository you work on, and name the change. It reads the change from the store, and its own `qa.md` and `tasks.md` from the subfolder with its name. Check out the change's branch in the store first.

## Installing

```bash
./install.sh --repo /path/to/web-app --store /path/to/my-changes-store    # a repository that uses a store
./install.sh --repo /path/to/repo                                         # a repository that is its own store
```

With `--store`, the store is set up as its own store too, so an agent can also work in the store. That install is local and excluded as well: only the change folders are committed there.

Options: `--dry-run` shows what would happen, and `--force` overwrites changed files without asking. Run it again to update.

## What the script does

- Writes `.changes-workflow/config.yml`, with `repository:` set to the folder name, and copies the templates to `.changes-workflow/templates/`.
- Copies the skill, and links it from `.claude/skills/`.
- Adds the pointer block to `AGENTS.md`, or creates `AGENTS.md` with only that block, and makes `CLAUDE.md` import `AGENTS.md`. The rest of these files is kept.
- Gives Claude Code access to a separate store through `.claude/settings.local.json`, and sets up that store as its own store, the same as `--repo <store>`.
- Excludes everything it installs in `.git/info/exclude`. In an `AGENTS.md` or `CLAUDE.md` the repository already commits, only the pointer block and the import line end up in git.
- Asks before overwriting a file that differs; without a terminal it skips it. No backups are kept.
- Removes the `.changes-workflow.yml` of earlier versions, and mentions a `changes/_templates/` folder left in the repository or the store.

## Tests

```bash
tests/install.sh
```

Runs the installer in throwaway repositories and checks the result.
