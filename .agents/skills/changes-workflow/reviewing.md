# Reviewing a change

Review when all tasks are built, before the pull requests are merged, preferably as someone who didn't build it. Read all documents of the change, and the code on its branch in each repository.

## Check

- **Coverage:** every functional requirement has its plan entries and tasks, every task is ticked off and built, and every acceptance criterion has a check in `qa.md` that ran, with its result in the pull request.
- **Plan:** the code does what the spec and plan say, and nothing more. Decisions are followed, and deviations were approved.
- **Code:** it follows "Solving it correctly" and "Writing code" in [implementing.md](implementing.md), and the tests pass.
- **Consistency:** documents follow their templates, changes are named by folder name, and affected docs and examples are updated.

## Report

List each finding with its place (file and line, or document and ID), what's wrong and why, most important first, or say there are none. Fix nothing: fixes go through [implementing.md](implementing.md).
