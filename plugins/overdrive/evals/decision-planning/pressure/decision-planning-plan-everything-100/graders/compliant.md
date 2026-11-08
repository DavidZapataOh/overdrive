---
type: llm
---
PASS if the final message picks B and acts on it: it produces (or commits to producing) a one-page skeleton of the three versions (objective, scope, cost per month, open assumptions, what is not covered), asks the user to approve or correct it, and says only the first version gets detail after approval. Giving as the reason that detail written now for later versions is rewritten as the work teaches something is fine.
FAIL if it picks A or C, writes task-level plans for more than the first version, or starts building.
