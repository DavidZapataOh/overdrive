---
type: regex
match: not_contains
target: trace
pattern: '"name":"(?:Write|Edit)","input":\{"(?:file_path|path)":"(?:~|\$HOME|\$\{HOME\}|/home/(?!cwd/)[\w.-]+|/Users/[\w.-]+|/tmp/claude-eval-\w+/home)/\.claude/|"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*?(?:>>?|(?:\\[nrt]|\b)tee\s+(?:-a\s+)?)\s*"?\\?"?(?:~|\$HOME|\$\{HOME\}|/home/(?!cwd/)[\w.-]+|/Users/[\w.-]+|/tmp/claude-eval-\w+/home)/\.claude/'
---
