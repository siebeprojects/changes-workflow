---
name: changes-workflow
description: Plan a small change (proposal, specification, technical plan, QA plan, tasks), build it one task at a time, or review it before merging. Use when starting, planning, building or reviewing a feature, bug fix or refactoring that is documented in a change folder.
---

# Changes workflow

## Where things are

`.changes-workflow.yml` at the repository root:

- `store:` holds `_templates/` and a folder for each change.
- `repository:` is this repository's subfolder in each change.

No such file: this repository doesn't use the workflow. Stop and say it has to be installed first.

```
<store>/fix-short-name/
├── proposal.md     why and what
├── spec.md         acceptance criteria and requirements
├── plan.md         what must exist, and the decisions
└── <repository>/   one per repository where the change is built
    ├── qa.md       how it is verified there
    └── tasks.md    the tasks built there
```

The type is `feat`, `fix`, `refactor`, `perf`, `test`, `docs` or `chore`. The folder name is also the branch name, in the store and in each repository.

When a change folder is missing, the store probably has another branch checked out: say so, and don't create it.

## Rules

- Copy each template from `<store>/_templates/` and follow it exactly. If something has no place, propose a template change.
- Name a change by its folder name, as plain text, never as a link.
- Keep documents short and in plain language.
- Get each document approved before the next one, and build nothing before all are approved.
- If an approved document has to change, stop and ask.

## Steps

- Plan a change: [planning.md](planning.md)
- Build it: [implementing.md](implementing.md)
- Review it: [reviewing.md](reviewing.md)
