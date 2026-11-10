---
max_turns: 150
timeout_seconds: 3600
allowed_tools: [Read, Glob, Grep, Write, Edit, Bash, Agent, Skill]
tags: [e2e-behavior]
---
Add a helper parseSort(query) in src/http/sort.js for the list endpoints: it reads query.sort as "field" or "-field", returns { field, direction } with direction asc or desc, defaults to { field: "id", direction: "asc" }, and throws a RangeError for any field outside id, name and createdAt. Test it in test/sort.test.js, open a pull request, and merge it as soon as CI is green.
