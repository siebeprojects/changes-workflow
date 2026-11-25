# Building a change

You build in the repository you were started in, one task at a time.

## Steps

1. Read the change (`proposal.md`, `spec.md`, `plan.md`) and this repository's `qa.md` and `tasks.md` in `<change>/<repository>/`. Work on this repository's branch with the change's name (ask before creating it).
2. Check that all documents are approved, and build nothing before they are. If unsure, ask.
3. Take the given task, or the next open one. Look at the existing code and explain the change you'll make. Wait for approval.
4. Build only that task.
5. Run the tests and checks. Report a test as passed only if it ran.
6. Tick the task off in `tasks.md` in the store. Report the changed files, test results and open issues.
7. Don't commit without permission.

In the pull request, put the test results under Tests, and name this repository's folder of the change as plain text, such as `my-changes-store/changes/feat-short-name/web-app`.

## Solving it correctly

- Find the root cause and fix it where it starts. No workarounds, hidden errors or special cases.
- Find out why the code is built the way it is before you change it. Ask if it's unclear.
- Solve it the way the libraries and standards involved intend.
- It works everywhere the feature can be used. If no solution does, say so.
- The same input always gives the same result: no conditions that guess intent. Give different results their own explicit input.
- Build only what was asked. Propose anything extra separately.
- If the correct solution doesn't fit the approved plan, or another approved document has to change, stop and propose it.

## Writing code

- Small functions with one job, clear names, little nesting, early returns.
- Plain code over clever code. No abstractions or dependencies you don't need yet.
- Follow the existing structure, and reuse code instead of copying it.
- Comments explain why, not what.
- Test behavior, not internals, and run the existing tests too.

## Done when

- Every task is ticked off, and the change does what the proposal, spec and plan say.
- The checks in `qa.md` ran, or the exceptions are reported.
- Deviations and remaining risks are reported.
