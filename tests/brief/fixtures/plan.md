# Demo plan

**Goal:** a small plan used by the tests.

## Global Constraints

- Lanes are exactly `direct`, `standard`, `critical`.
- Keep the invoices module fast.

## File structure

Text that is not a task.

### Task 1: Decisions tool

**Files:**
- Create: `plugins/x/libexec/a`, `docs/a.md`
- Test: `tests/a/test-a.sh`

**Interfaces:**
- Log format:

```
# Decisions
## D-0001 — <title>
### Task 9: not a real task
- Create: `fenced/ignored.md`
```

- [ ] **Step 1:** Write the tests.

### Task 2: Brief
- Modify: `plugins/x/lib/common.sh:10-40`, `docs/a.md`
- Test: `tests/b/test-b.sh`

### Task 3: Directory work
- Create: `src/(marketing)/page.tsx` (route `group`)
- Modify: `src/app/` (whole `dir`)

### Task 4: Range only
- Modify: `plugins/x/lib/common.sh:5`

### Task 5: Inside a directory
- Modify: `src/app/page.tsx`

### Task 6: No files here

Nothing to touch.

## Self-review

### Task 7: after a level two heading
- Create: `late.md`
