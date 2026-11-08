# Proportion

A plan longer than the code it describes has written the code. The plan's job is the decisions the code cannot show: what, where, which interface, which test proves it, what could go wrong.

## Check before handing a plan over

| Smell | Fix |
|---|---|
| A fenced block over 15 lines | Replace the body with the interface and "follow `<file>`". |
| A step that restates the previous step's code in prose | Delete it; the interface and test already say it. |
| More lines in the plan than the diff will have | Cut to files, interfaces, test assertions and risks. |
| A test named without its assertion | Add the input and the expected result. |
| A detailed later slice | Collapse it to its skeleton row. |
| An option list with no choice | Pick, and write a `Ruling:`. |

## What may be code

- A signature or type (up to ~10 lines).
- A command with its expected output.
- A schema or config fragment that is itself the decision.
- A table of cases for a test (inputs and expected outputs).

## What is never code

Function bodies, whole files, SQL migrations written out in full, boilerplate the project already has an example of.
