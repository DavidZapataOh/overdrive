# Calibrating the risk map after an escaped defect

## Contents

- When it applies
- Steps
- Regression case

## When it applies

A defect reached users or review after a change that the classifier put below critical (`Risk: standard` or `Risk: direct`), and the change touched something that belongs to a floor: money, auth, tenant isolation, secrets, irreversible data, delivery, public contracts or concurrency. The fix to the code is separate; this is the fix to the lane.

## Steps

1. **Reproduce the classification.** `OD risk --paths <the files of the escaped change>` (or `OD risk --diff <base>...HEAD` when the commit exists). Note the lane and items printed. If it already says critical, the map is not the gap: the process was, and the learning goes in another form.
2. **Pick the item.** The floor's own item name for what the code does: `money`, `auth`, `tenant-isolation`, `data-migration`, `secrets`, `delivery`, `public-contract`, `concurrency`. The Risk line then reads the same everywhere.
3. **Write the narrowest rule that catches this change and its neighbors**, critical by default:

   | What the project calls it | Rule |
   | --- | --- |
   | a directory | `path src/renewals/** money` |
   | a word in file names | `pathtoken renewal money` |
   | a word in the team's language | `keyword renovacion money` |
   | an identifier | `symbol retryRenewal money` |
   | a code pattern | `content gateway\.charge\( money` |

   Append it to `.overdrive/risk-map.conf` with a trailing comment saying what escaped. Do not widen an existing rule, and do not delete or lower one.
4. **Prove it fires and stays narrow.** `OD risk --paths <the escaped file>` now prints `lane critical` and the item; `OD risk --paths <an unrelated file in the same tree>` does not. Run both and read the output.
5. **Report the map edit as its own critical change** (`Risk: critical — risk-map`): the user's correction is the request for it, so there is nothing further to approve, and it is committed on its own.

## Regression case

If the project has a `.overdrive/risk-cases/` directory, add the escaped change as a case there, in the shape the classifier's own corpus uses: `<slug>/setup.sh` (the baseline), `<slug>/change.sh` (the change), `<slug>/expected` (`lane critical` and `items money`) and `<slug>/risk-map.conf` (the rules as committed). If it has none, do not create the directory: the rule plus a note (`references/forms.md`, Note) is the whole record.
