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

Write code that is easy to read and easy to change. A reader understands what the code does from its names. The next feature can be added without a workaround.

### Functions

- A function does one thing. If you need "and" to say what it does, split it.
- Its name says what it does. A reader knows this without reading the code inside.
- Start the name with a verb when the function does something, such as `loadSiteConfig`. Start it with `is` or `has` when it answers yes or no, such as `isFallback`. Use a noun when it gives a value, such as `errorCount`.
- A function does only what its name says. For example, `formatProblem` returns text. It doesn't print the text, and it doesn't change anything.
- Keep a function short. When a function has several steps, put each step in its own function with a clear name. The main function then reads like a list of steps.
- Example: `loadSiteConfig` calls `readConfigFile`, `parseJson` and `validateSiteConfig`.
- Return early for the simple cases instead of nesting `if`s.
- Give a function at most three parameters. When it needs more, pass one object with named fields.
- Don't pass `true` or `false` to choose between two behaviors. Write two functions instead.

### Names

- Name things after what they are in the product. Use the same word for the same thing everywhere, in the code and in the documents.
- Don't use vague names, such as `data`, `info`, `handle`, `process`, `manager`, `util` or `helper`.
- Don't use abbreviations, except common ones such as `url` or `id`.

### Modules and abstractions

- A module or class has one job, and its name says which.
- Each job lives in one place. Other code uses it only through a few clear functions. Other code doesn't depend on how the job is done inside.
- Example: every check adds its problems to one report. Only the report prints them.
- Before you write code, look for code that already does the job. Use that code, or extend it.
- Never copy code. Move the code to one function, and call that function from both places.
- Add an abstraction when it gives a job its one place or removes copied code. Don't build one for a feature nobody asked for.
- Leave the code so that the next feature can be added to a module, without a workaround.

### Values, errors and comments

- Don't hardcode values. Give each value a name, once, in one place.
- Handle errors the way the repository does. Never hide an error. Report it, or pass it on.
- A comment says why the code is the way it is.
- When code needs a comment to explain what it does, give it a better name or split it instead.
- Give each exported function, class and module a short comment that says what it does.
- When you change the code, update its comments.
- Leave no unused code, commented-out code or debug output.

### Style

- Write plain code, not clever code.
- Follow the repository's structure and conventions.
- Don't add a dependency you don't need.

| Not | But |
|---|---|
| `process(page, true)` | `validatePage(page)` and `renderPage(page)` |
| `check()` prints a problem and returns `false` | `findBrokenLinks()` returns the broken links, and the caller adds them to the report |
| `if (path.includes(' '))` in two files | `isValidPagePath(path)`, in one module, used by both |

## Writing tests

Write and run the tests as [testing.md](testing.md) says.

## Done when

- Every task is ticked off, and the change does what the proposal, spec and plan say.
- The checks in `qa.md` ran, or the exceptions are reported.
- Deviations and remaining risks are reported.
