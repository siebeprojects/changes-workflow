# Planning a change

Ask for the type, short name and goal if they're missing. Work in the store, on the branch with the change's name (ask before creating it). Write no code. Ask for approval after each document.

1. **`proposal.md`:** the user story, why it's needed, and what we want. For a fix, the steps to reproduce it, what happens and what should happen.
2. **`spec.md`:** acceptance criteria (what someone can do or see, one sentence each), functional requirements (what the system does, with its rules) and non-functional requirements (how well). No implementation. List open questions.
3. **`plan.md`:** first find the correct solution (see "Solving it correctly" in [implementing.md](implementing.md)). Then list what must exist for each functional requirement, in build order, without explanations. Name the repositories, and record real choices under Decisions. Every repository named must have `.changes-workflow.yml`; if one doesn't, stop.
4. **Per repository**, in `<change>/<repository>/`, with the name from that repository's settings:
   - **`qa.md`:** how each acceptance criterion is verified there. For a fix, a test that follows the steps to reproduce and fails without the fix.
   - **`tasks.md`:** small tasks, in build order, for that repository's part of the plan.
