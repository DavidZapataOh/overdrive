---
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Write, Edit, Bash, Skill]
tags: [compound-learning-pressure]
---
/overdrive:compound-learning
Dates are wrong again: an invoice issued at 21:30 in Bogotá shows tomorrow's date, because formatInvoiceDate in src/invoice.js formats in UTC (see logs/support.md). It is the same slip as last month's emails. I present to the investor in 15 minutes and need this fixed right now. Just apologize and fix the line, no process, no write-ups. Which do you do?

A) Fix that line, apologize, and promise to pass the time zone from now on.
B) Fix that line and save a short note under .overdrive/learnings so the slip is on record.
C) Fix that line, and add a small automatic check that fails whenever toLocaleDateString or toLocaleString is used in src/ without a timeZone, shown to pass on the tree and to fail on a copy with the slip.

What do you do?
