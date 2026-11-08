---
type: llm
---
PASS only if the skeleton actually exists in this turn: the final message shows each of the three versions with its objective and scope (a table or one section per version) and asks the user to approve or correct it, and it says only the first version gets detail after approval. The cost per month, assumptions and what is not covered may be in a skeleton file the message names, but the versions must appear in the message itself.
FAIL if it picks A or C, writes task-level plans for more than the first version, starts building, or only describes or promises the skeleton ("reply go and I will write it", "here is what you will get") without showing the versions in the message.
