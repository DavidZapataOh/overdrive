# Findings

## Contents

- Line format
- Confidence anchors
- What not to write
- Merging
- After the merge

## Line format

```
F<n> | P0..P3 | 0|25|50|75|100 | path:line | title | "verbatim quote" | failure mode | fix | plan-mandated:yes|no
```

Example:

```
F1 | P1 | 75 | src/invoices/report.js:1 | Missing tenant filter | "WHERE year = ?" | every customer's invoices are returned | add AND tenant_id = ? | plan-mandated:no
```

Severity: P0 breaks money, data, security or tenant isolation; P1 is wrong behavior users will hit; P2 is weak tests or maintainability risk; P3 is polish. One value per finding; a range is not a severity.

## Confidence anchors

| Anchor | Meaning |
|---|---|
| 0 | no evidence |
| 25 | a suspicion |
| 50 | plausible, unconfirmed |
| 75 | confirmed by reading the code |
| 100 | reproduced |

- At 75 or 100 give `path:line` and a quote copied verbatim from within 3 lines of it in the head tree. If you cannot quote it, lower the confidence. `OD findings check --head HEAD_SHA FILE` verifies this.
- Merge drops 25 and below, and 50 unless P0. Do not write findings you would not defend; do not pad with 25s.

## What not to write

- "Consider X" or "you might want to" with no failure mode. If nothing breaks, it is not a finding.
- A style opinion with no rule behind it. A rule is in the project's CLAUDE.md, its lint configuration or its decisions file; cite it in the title.
- A claim from the author's report that the diff does not show.

## Merging

`OD findings merge a.findings b.findings > review.findings` drops what is below the bar, dedupes by path, line and title, sorts P0 to P3 then by confidence, and renumbers. Findings that match semantically but not mechanically (two lenses describing one defect with different titles) are yours to remove from the merged file, keeping the higher severity and the better quote.

## After the merge

- P0 and P1 decide the verdict. P2 and P3 are notes unless a fix is cheap.
- The merged file goes where the user asked, else beside the package. Reviewer files stay untouched.
- With no findings, the file exists and is empty.
