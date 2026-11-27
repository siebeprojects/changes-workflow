# Testing a change

Write tests that prove the change works. The tests keep proving it when the code changes later.

## What to test

- Test what a user or other code sees. Run the program or call the exported functions, and check the result.
- Don't test private functions, or how the code works inside.
- Write a test for each acceptance criterion in `spec.md`.
- For a fix, write a test that shows the bug.
- A test for a change fails without that change. Check this: run the test on the code without the change, and see it fail.

## Writing a test

- A test checks one behavior, and its name says which: "a site with errors stops the build and lists every problem once", not "errors test".
- Write a test in three parts, from top to bottom: set up, do one thing, check the result.
- Put test data, such as a test site, in its own folder. The folder name says what the data shows.
- Share test data between tests. Don't copy it.
- Each test runs on its own, in any order, and removes what it created.

## Waiting

- A test waits for a sign that something happened, such as a printed line, a written file or an answer from a server. It fails after a timeout.
- A test never waits a fixed time. A fixed wait fails on a slow machine, and wastes time on a fast one.
- Don't retry a test that fails sometimes. Find the cause, and fix it.

| Not | But |
|---|---|
| `await sleep(500)`, then read the output | wait until the output has the line `Server is up` |
| poll the file every 100 ms | wait for the event that says the file is written |

## Running

Run the new tests and all existing tests. Report a test as passed only if it ran.
