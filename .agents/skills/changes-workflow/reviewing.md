# Reviewing a change

Review when all tasks are built, before the pull requests are merged, preferably as someone who didn't build it. Read all documents of the change, and the code on its branch in each repository.

## Check

- **Coverage:** every functional requirement has its plan entries and tasks, every task is ticked off and built, and every acceptance criterion has a check in `qa.md` that ran, with its result in the pull request.
- **Plan:** the code does what the spec and plan say, and nothing more. Decisions are followed, and deviations were approved.
- **Solution:** it follows "Solving it correctly" in [implementing.md](implementing.md).
- **Code quality:** read the changed code again as a whole, not only the changed lines. Check it against "Writing code" in [implementing.md](implementing.md). Each function does one thing, and its name says what. Each job lives in one place. No code is copied. The next feature can be added without a workaround.
- **Tests:** they follow [testing.md](testing.md), and they pass.
- **Consistency:** documents follow [writing.md](writing.md), and affected docs and examples are updated.

## Report

List each finding with its place (file and line, or document and ID), what's wrong and why, most important first, or say there are none. Fix nothing: fixes go through [implementing.md](implementing.md).
