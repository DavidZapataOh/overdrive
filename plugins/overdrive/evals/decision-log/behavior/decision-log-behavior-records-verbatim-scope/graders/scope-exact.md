---
type: regex
target: {source: file, path: .overdrive/decisions.md}
pattern: '^- Scope: (?!.*(?:Sentry|Resend|\ball\b|paid hosting|\bany paid|\btodos?\b|cualquier))[^\n]*Vercel Pro'
flags: mi
---
