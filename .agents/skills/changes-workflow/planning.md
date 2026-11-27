# Planning a change

Ask for the type, short name and goal if they're missing. Work in the store, on the branch with the change's name (ask before creating it). Write no code.

Write each document as [writing.md](writing.md) says, in this order. Get each one approved before the next. If an approved document has to change, stop and ask.

1. **`proposal.md`**
2. **`spec.md`**
3. **`plan.md`:** first find the correct solution (see "Solving it correctly" in [implementing.md](implementing.md)). Every repository it names must have `.changes-workflow/config.yml`; if one doesn't, stop.
4. **`qa.md` and `tasks.md`**, per repository, in `<change>/<repository>/`, with the name from that repository's settings. Plan the checks in `qa.md` so they can be built as [testing.md](testing.md) says.
