# Writing the documents

How to write `proposal.md`, `spec.md`, `plan.md`, `qa.md` and `tasks.md`.

## Template

The template says what goes where, and why.

1. Copy the template of the document from `.changes-workflow/templates/`.
2. Follow the instructions between `<` and `>` exactly, and replace each one with your text. The first one says what the document is for: read it, and remove it.
3. Keep the sections and their order, and add nothing. If something has no place, propose a template change.

Name a change by its folder name, as plain text, never as a link.

## Style and language

- Write plain English, the way you would explain it to a colleague. A person or an agent who reads an item knows at once what must happen.
- Use short, complete sentences that say who or what does something: "The build stops", not "Stopping of the build".
- Be exact: say what happens, when and where, and name what it happens to, such as the page, the button or the error. Don't write "the rules", "the changes" or "correctly" without saying which or how.
- Put one thing in each item. An item may refer to another one by its number, but still says what must happen.
- Give an example when that is clearer than more words.
- Use the same word for the same thing in all documents.
- Be practical: no introductions, repetition, filler or big words. When short isn't clear, choose clear.

| Not | But |
|---|---|
| Errors are shown. | The author sees an error when a link leads to no page. |
| Paths are handled correctly. | A link finds its page in any letter case: `/Guide` leads to `/guide`. |
| The build is fast. | A site of 500 pages builds within 10 seconds on the CI server. |
| Apply the rules in the preview after a page is saved. | When the author saves a page in the preview, print an error, with the file and line, for each link that leads to no page. |
