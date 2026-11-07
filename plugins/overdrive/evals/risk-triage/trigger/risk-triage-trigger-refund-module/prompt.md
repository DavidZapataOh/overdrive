---
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill, Bash, Edit, Write]
tags: [risk-triage-trigger, train]
---
add src/orders/refund.ts with a refundOrder(orderId, cents) that reverses part of an order total, support needs partial refunds
