# Engineering Agreement

## Communication and approval
- Before changing implementation code, explain the proposed changes and wait for explicit approval.
- Reading files, inspecting code, and discussing designs do not require approval.
- Ask focused questions when requirements are unclear. Keep communication concise.

## Implementation
- Work in small, independently verifiable increments.
- Follow existing architecture and code conventions; avoid unrelated changes and unnecessary dependencies.
- Add or update tests for behavioral changes; run relevant tests.
- Do not create branches, commit, or push without permission.

## Completion
- Summarize changed files, tests run and their results, and outstanding risks or questions.

<!-- changes-workflow:start -->
## Changes workflow
- When `.changes-workflow/config.yml` exists at the repository root, plan, build and review every change with the `changes-workflow` skill, and do not implement a change before its documents are approved.
<!-- changes-workflow:end -->
