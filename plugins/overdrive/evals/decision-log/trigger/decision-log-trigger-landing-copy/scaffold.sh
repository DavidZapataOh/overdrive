#!/usr/bin/env bash
# A pricing page draft with the plans filled in and the final call to action still open.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_file copy/pricing.md '# Pricing page

## Plans

- Basic: USD 19 per month. One site, weekly report.
- Advanced: USD 49 per month. Five sites, daily report, email alerts.
- Studio: USD 129 per month. Unlimited sites, daily report, alerts, priority queue.

Annual billing takes two months off every plan.

## Final call to action

TODO: final call to action, decide the wording and the button label.'
fx_commit "Draft the pricing copy"
