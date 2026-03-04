# Todo — Rules & Conventions

This document defines how epics and tasks are structured in this project.
All todo files must follow these rules exactly.

---

## File Structure

- Each todo file covers one area of work (e.g. `todo/audio.md`, `todo/ui.md`)
- A file contains one or more **Epics**
- Each Epic contains multiple **Tasks**
- The **last task** of every Epic must always be a **Testing Task** that validates all work done in that Epic

---

## Epic Structure

```
## Epic: <Epic Title>

<Short description of what this epic covers and what it delivers>

### Tasks
- [ ] TASK-01 — <Task Title>
- [ ] TASK-02 — <Task Title>
- [ ] TASK-03 — <Task Title>
- [ ] TASK-04 — [TEST] <Epic Title> — Integration & Testing
```

---

## Task Structure

Each task is written as a second-level section under its Epic.

```
---

### TASK-XX — <Task Title>

**Epic**: <Epic Title>
**Status**: `pending` | `in progress` | `done`

#### Description
A short paragraph explaining the context and purpose of this task.

#### Work
A clear list of everything that needs to be implemented or done:
- Item 1
- Item 2
- Item 3

#### Definition of Done (DoD)
A checklist of conditions that must all be true before this task is considered complete:
- [ ] Condition 1
- [ ] Condition 2
- [ ] Condition 3

#### Test Checklist
Manual or automated checks to verify this task works correctly:
- [ ] Test case 1
- [ ] Test case 2
- [ ] Test case 3
```

---

## Testing Task (Last Task in Every Epic)

The final task in each Epic is always a dedicated testing task.
Its job is to verify the entire Epic end-to-end, not just individual pieces.

```
---

### TASK-XX — [TEST] <Epic Title> — Integration & Testing

**Epic**: <Epic Title>
**Status**: `pending` | `in progress` | `done`

#### Description
End-to-end testing task for the <Epic Title> epic. Validates that all tasks
in this epic work correctly together as a whole.

#### Work
- Review all tasks in the epic are marked done
- Run integration tests covering the full epic scope
- Manually verify the user-facing behavior described in the epic

#### Definition of Done (DoD)
- [ ] All prior tasks in this epic are marked `done`
- [ ] All test cases below pass
- [ ] No regressions introduced in related areas

#### Test Checklist
A comprehensive checklist covering every task in the epic:
- [ ] TASK-01: <brief description of what to verify>
- [ ] TASK-02: <brief description of what to verify>
- [ ] TASK-03: <brief description of what to verify>
- [ ] Full flow works end-to-end as described in the epic
```

---

## Status Values

| Status | Meaning |
|---|---|
| `pending` | Not started |
| `in progress` | Actively being worked on |
| `done` | All DoD conditions met |

---

## Rules Summary

1. Every epic must have at least 2 tasks + 1 testing task
2. Every task must have: Title, Epic, Status, Description, Work, DoD, Test Checklist
3. The last task in every epic is always a `[TEST]` task
4. The `[TEST]` task's checklist must reference every other task in the epic
5. A task is only `done` when every item in its DoD checklist is checked
6. The `[TEST]` task cannot be `done` until all other tasks in the epic are `done`
