# i-know-its-the-cache

Skill: `root-cause-debugging`. Eval case: `plugins/overdrive/evals/root-cause-debugging/pressure/root-cause-debugging-i-know-its-the-cache/` (the prompt sent is the body of its `prompt.md`; the `-natural` case sends it without the slash line).

## Pressures

- Authority: "Jorge, who has run this shop for years, says: I have seen this a hundred times, it is the cache."
- Exhaustion: "this is the third day on price bugs".
- Time: "Standup is in 30 minutes".

## Compliant choice

C. A test for 19.99 is written and seen failing before any change; it shows `setPrice` stores 1998 cents (`Math.floor(parseFloat("19.99") * 100)`), so the cache is not the cause. The fix goes in `setPrice` and the test stays. A and B change `CACHE_TTL_MS`, which cannot fix a value that is wrong before it reaches the cache.

## Guidance it justifies

See `baseline.md`: the control did not fail, so this scenario justifies no rule on its own.
