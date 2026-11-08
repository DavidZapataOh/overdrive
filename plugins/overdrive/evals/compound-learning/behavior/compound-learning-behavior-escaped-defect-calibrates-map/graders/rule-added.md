---
type: regex
target:
  source: file
  path: .overdrive/risk-map.conf
pattern: '^(?:path|pathtoken|keyword|symbol|content)[ \t]+"?\S*(?:renewal|retry|retries)\S*"?[ \t]+money(?:[ \t]+critical)?[ \t]*(?:#.*)?$'
flags: mi
---
