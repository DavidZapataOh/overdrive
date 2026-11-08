---
type: regex
target:
  source: file
  path: .overdrive/risk-map.conf
pattern: '^(?:path|pathtoken|keyword|symbol|content)[ \t]+"?\S*(?:renewal|renovaci|retry|retries|charge)\S*"?[ \t]+money(?:[ \t]+critical)?[ \t]*(?:#.*)?$'
flags: mi
---
