# PROGRESS — LineLeap work tracker

Purpose: the single place to see current state and to pause/resume work with zero lost context — a status board, per-milestone checklists, a chronological session log, decisions, and pause/resume drills.

Last updated: 2026-07-29

## How to use this doc

- This is the **single source of truth for live status**, not the definition of work. Issue definitions (Problem / Impact / Evidence / Acceptance / Verification) live in [BACKLOG.md](BACKLOG.md); the step-by-step execution workflow and guardrails live in [RUNBOOK.md](RUNBOOK.md). Start-to-finish navigation is in [README.md](README.md).
- Every task is a canonical `LL-###` id. Never renumber or invent ids — copy them verbatim from [BACKLOG.md](BACKLOG.md).
- Move an id across the **Status Board** as its state changes, using the exact status vocabulary: `Not started` · `In progress` · `Blocked` · `In review` · `Done` · `Won't do`.
- Whenever you sit down or stand up, add a newest-first entry to the **Session Log** and update **Current focus**. That is what makes a cold resume (or the same dev after 3 weeks away) possible.
- BACKLOG does not mirror status. Update the board, current focus, milestone checklist, and session log here as reality changes.

Related reading: [DEVELOPMENT.md](DEVELOPMENT.md) (setup & commands) · [ARCHITECTURE.md](ARCHITECTURE.md) (how the system is built) · [AI_QUEUE_CASE_STUDY.md](AI_QUEUE_CASE_STUDY.md) (the queue engine deep-dive).

---

## Current focus

> **LL-014 (dead-code and naming cleanup) is in progress; implementation and automated verification are complete locally.**

- Active issue(s): **LL-014 — Remove dead code, unused deps, and fix misnamed files**. The committed LL-001, LL-002, LL-003, LL-006, and LL-020 checkpoints remain open pending merge/manual verification.
- Branch: `feature`
- Next step: commit the LL-014 implementation checkpoint, push `feature`, and open/update its PR. Before merge, smoke startup, drawing, generation queue, and History after the dependency and import cleanup; move LL-014 to `Done` only after merge.

---

## Status Board

Move ids between columns as work progresses; keep this table, Current focus, milestone checklists, and the latest log entry in sync.

| Not started | In progress | Blocked | In review | Done | Won't do |
|---|---|---|---|---|---|
| — | LL-001 | — | — | — | — |
| — | LL-002 | | | | |
| — | LL-003 | | | | |
| LL-004 | | | | | |
| LL-005 | | | | | |
| — | LL-006 | | | | |
| LL-007 | | | | | |
| LL-008 | | | | | |
| LL-009 | | | | | |
| LL-010 | | | | | |
| LL-011 | | | | | |
| LL-012 | | | | | |
| LL-013 | | | | | |
| — | LL-014 | | | | |
| LL-015 | | | | | |
| LL-016 | | | | | |
| LL-017 | | | | | |
| LL-018 | | | | | |
| LL-019 | | | | | |
| LL-019b | | | | | |
| — | LL-020 | | | | |
| LL-021 | | | | | |

Count: **16 not started** · **6 in progress** · 0 blocked · 0 in review · 0 done · 0 won't do.

Legend: ☐ open · ☑ done. Do not tick anything until it is actually merged and verified per its Acceptance criteria in [BACKLOG.md](BACKLOG.md).

---

## Milestone checklists

Milestones: **M1** = Immediate (1–2 days) · **M2** = Short-term (1–2 weeks) · **M3** = Medium (1–2 months). Priorities: **P0** blocks core value / data loss · **P1** reliability/compliance before next release · **P2** correctness/quality · **P3** hygiene/polish.

### M1 — Immediate (P0 core fixes + P1 pre-release cleanup)

- ☐ **LL-001** (P0, **In progress**) — Undo/redo corrupts strokes into invisible dots
- ☐ **LL-002** (P0, **In progress**) — Canvas capture has a transparent background
- ☐ **LL-003** (P0, **In progress**) — Generation and gallery error details are hidden; offline guidance is missing
- ☐ **LL-006** (P1, **In progress**) — Saved theme is never restored on launch
- ☐ **LL-008** (P1) — Compliance: report email, privacy policy, and permissions contradict the app
- ☐ **LL-014** (P1, **In progress**) — Remove dead code, unused deps, and fix misnamed files
- ☐ **LL-020** (P1, **In progress**) — Establish and maintain the project documentation baseline

### M2 — Short-term (P1 reliability / product honesty / CI)

- ☐ **LL-004** (P1) — Long Horde queues fail; persist generationId, resume polling, remote cancel, adaptive polling
- ☐ **LL-005** (P1) — Bound queue history and define image-file ownership
- ☐ **LL-007** (P1) — Absolute file paths break the iOS gallery after app update
- ☐ **LL-017** (P1) — Remove the fake model selector
- ☐ **LL-018** (P1) — Harden CI and release build
- ☐ **LL-019** (P1) — Expand test coverage on the highest-risk paths
- ☐ **LL-021** (P1) — Show queue position/ETA and best-effort completion notifications

### M3 — Medium (P2 correctness / performance / lifecycle / deferred tests)

- ☐ **LL-009** (P2) — Make queue state transitions atomic and cancellation-safe
- ☐ **LL-010** (P2) — Add stable gallery IDs, normalized UTC timestamps, and deterministic sorting
- ☐ **LL-011** (P2) — Make gallery deletion recoverable and reconcilable
- ☐ **LL-012** (P2) — Rework canvas performance model
- ☐ **LL-013** (P2) — Unify error handling into one typed-failure flow
- ☐ **LL-015** (P2) — Fix memory leaks and lifecycle hazards
- ☐ **LL-016** (P2) — Single tap draws nothing
- ☐ **LL-019b** (P2) — Widget & integration tests (deferred slice of LL-019)

### Dependencies to respect when sequencing

| Do this first | Then | Why |
|---|---|---|
| LL-020 | Any code issue | Land the reviewed operating baseline first; later queue PRs update the case study rather than blocking the baseline. |
| LL-001 | LL-012 and LL-016 | Stabilize stroke/history correctness before changing performance or single-tap rendering. |
| LL-003 | LL-011 | The recoverable delete flow needs the shared visible error surface. |
| LL-004 | LL-009 and LL-021 | Define submit/poll/resume transitions before adding compare-and-set rules and progress/notification UX. |
| LL-007 + LL-010 migration design | LL-005 and LL-011 cleanup | Path ownership, stable ids, timestamps, and tombstones rewrite the same persisted records. |
| LL-001 and LL-006 fixes | LL-019 completion | Their regression tests land with the fixes and count toward the LL-019 coverage slice. |

---

## Session Log

Newest entry on top. Copy the template for every work session (start **and** stop). Keep entries short and factual; link ids and cite code as `path:line`.

### Template (copy this)

```
### <YYYY-MM-DD> — <session title>
- Session goal:
- Issues touched (LL-###):
- Files changed:
- Verified how:        (e.g. flutter analyze / flutter test / manual repro steps)
- Result:              (Not started / In progress / Blocked / In review / Done / Won't do — per issue)
- Next step:
- Blockers:
```

### 2026-07-29 — Remove unreachable code and misleading names
- Session goal: implement LL-014 by proving and removing dead UI/API/DI islands, dropping unused packages, and correcting the mirror/theme repository filenames.
- Issues touched (LL-###): LL-014; removal of the unreachable generated-image viewer also eliminates one dead-path LL-015 controller leak.
- Files changed: deleted dead API, adapter, widget, repository, and use-case files; simplified DI; renamed mirror/theme repository files and imports; refreshed package/plugin metadata; updated current technical docs and this tracker.
- Verified how: repo-wide `rg` import/symbol checks proved no inbound callers before deletion and no stale live references afterward; `flutter pub get` removed the 2 direct packages plus 8 exclusive transitives; read-only format check → 0 changes across 76 Dart files; `flutter analyze` → 0 issues; full `flutter test` → all 26 tests passed; `flutter build apk --debug` → succeeded.
- Result: In progress — implementation and automated verification are complete locally; manual startup/drawing/queue/History smoke, review, and merge remain.
- Next step: commit and push the coherent LL-014 checkpoint, open/update the PR, then smoke the affected app paths before merge.
- Blockers: none. Existing Swift Package Manager and Kotlin Gradle Plugin warnings remain tracked by LL-018.

### 2026-07-29 — Restore the saved theme before the first frame
- Session goal: implement LL-006 so a cold start reads the persisted theme through the domain/DI path before rendering the app.
- Issues touched (LL-###): LL-006.
- Files changed: theme repository/use cases/notifier, dependency and startup wiring, focused theme tests, architecture notes, and this tracker.
- Verified how: focused theme tests → 3 passed, including a real SharedPreferences round trip and first-frame dark-theme assertion; read-only format check → 0 changes across 92 files; `flutter analyze` → 0 issues; full `flutter test` → all 26 tests passed; `flutter build apk --debug` → succeeded.
- Result: In progress — implementation and automated verification are complete locally; manual cold-restart verification, review, and merge remain.
- Next step: commit and push the coherent LL-006 checkpoint, open/update the PR, then select light/dark, fully restart, and confirm the saved theme appears on the first frame without a system-theme flash.
- Blockers: none. Existing Swift Package Manager and Kotlin Gradle Plugin warnings remain tracked by LL-018.

### 2026-07-29 — Make generation and History failures actionable
- Session goal: implement LL-003 so capture/enqueue, terminal queue, and History failures have visible reasons and retry paths, with honest offline and anonymous-queue guidance.
- Issues touched (LL-###): LL-003.
- Files changed: generation/queue and gallery providers/use cases, their Scribble/queue/History UI surfaces, the shared actionable message card, focused feedback tests, and this tracker.
- Verified how: focused LL-003 tests → 10 passed; read-only format check → 0 changes across 90 files; `flutter analyze` → 0 issues; full `flutter test` → all 23 tests passed; `flutter build apk --debug` → succeeded.
- Result: In progress — implementation and automated verification are complete locally; manual forced-failure/offline checks, review, and merge remain.
- Next step: commit and push the coherent LL-003 checkpoint, open/update the PR, then use `flutter run` to force each failure class and confirm the reason, retry action, slow-queue guidance, and real offline result before merge.
- Blockers: none. Existing Swift Package Manager and Kotlin Gradle Plugin warnings remain tracked by LL-018.

### 2026-07-29 — Normalize generation captures to opaque white
- Session goal: fix LL-002 so the PNG sent to Horde has a deterministic opaque white background without changing the theme-aware on-screen canvas.
- Issues touched (LL-###): LL-002.
- Files changed: `lib/core/utils/image_utils.dart`, `test/image_utils_test.dart`, and this tracker.
- Verified how: the decoded-pixel regression failed against the old behavior with transparent `[0, 0, 0, 0]` background pixels; focused capture test → passed in light and dark themes with identical RGBA output, preserved red stroke samples, white off-stroke samples, and alpha 255 everywhere; read-only format check → 0 changes; `flutter analyze` → 0 issues; full `flutter test` → all 13 tests passed; `flutter build apk --debug` → succeeded.
- Result: In progress — implementation and automated verification are complete locally; the issue remains open until review, merge, and manual generation verification.
- Next step: commit and push the coherent LL-002 checkpoint, open/update the PR, inspect a saved capture from the same sketch in both themes, then move the issue through `In review` to `Done` only after merge.
- Blockers: none.

### 2026-07-29 — Preserve completed strokes through undo and redo
- Session goal: fix LL-001 so undo/redo restores completed strokes instead of stale one-point snapshots.
- Issues touched (LL-###): LL-001.
- Files changed: `lib/presentation/common/providers/scribble_notifier.dart`, `lib/presentation/features/scribble/drawing_canvas.dart`, `test/scribble_notifier_test.dart`, and this tracker.
- Verified how: the new point-list regression failed against the old behavior; targeted notifier tests → 4 passed; read-only format check → 0 changes; `flutter analyze` → 0 issues; full `flutter test` → all 12 tests passed; `flutter build apk --debug` → succeeded.
- Result: In progress — implementation and automated verification are complete locally; the issue remains open until review, merge, and manual verification.
- Next step: commit and push the coherent LL-001 checkpoint, open/update the PR, manually draw A then B and verify undo/redo, then move the issue through `In review` to `Done` only after merge.
- Blockers: none.

### 2026-07-29 — Documentation review and implementation preparation
- Session goal: cross-check the documentation baseline against README, pubspec, implementation, tests, CI, and platform configuration; remove ambiguous implementation contracts.
- Issues touched (LL-###): LL-020 (active); clarified scope and sequencing for the remaining permanent ids without changing their live status.
- Files changed: the `docs/` baseline, including BACKLOG/PROGRESS/README consistency and sibling technical references.
- Verified how: repository/path/link/command review; read-only format check → 0 changes; `flutter analyze` → 0 issues; `flutter test` → all 10 tests passed; `flutter build apk --debug` → succeeded.
- Result: In progress.
- Next step: commit the reviewed docs checkpoint, push `feature`, and open/update the PR for review.
- Blockers: none for LL-020. LL-008 implementation still requires the monitored reporting contact/transport decision recorded in its acceptance criteria.

### 2026-07-14 — Documentation baseline created
- Session goal: stand up the docs/ tracker set; no code touched.
- Issues touched (LL-###): LL-020.
- Files changed: docs/PROGRESS.md (this file) and sibling docs.
- Verified how: n/a (docs only).
- Result: In progress; initial drafts and issue registry seeded for later review.
- Next step: cross-check the draft baseline against the repository before committing it.
- Blockers: none.

---

## Decisions log (ADR-lite)

One row per decision that constrains future work. Add a row whenever you choose an approach that others (or future-you) must honor. Reference the affected `LL-###`.

| Date | Decision | Rationale | Affected LL-### |
|---|---|---|---|
| 2026-07-29 | Keep Stable Horde as the only provider implementation; removed Replicate/Vertex stubs must not be revived without a separately designed provider contract. | The stubs were fully commented out, unreachable, and bypassed the live queued-generation architecture. | LL-014, LL-017 |
| 2026-07-29 | Remove the fake model selector; do not wire the current DALL-E/Midjourney/Leonardo choices. | Only Stable Horde is supported, the current choices are unavailable, and real Horde model selection needs separate discovery/persistence design. | LL-017, LL-008 |
| 2026-07-29 | PROGRESS is the only live-status source; BACKLOG contains durable issue definitions without status fields. | Mirrored status becomes stale and makes cold-resume state ambiguous. | All |
| 2026-07-14 | Documentation index is named `docs/README.md`, never `docs/INDEX.md`. | `.gitignore` contains a bare `INDEX.md` line that git-ignores **any** file named `INDEX.md` at any depth, so a `docs/INDEX.md` would be silently untracked. | LL-020, docs hygiene |
| 2026-07-14 | Only Stable Horde is a supported backend for now; `replicate_api.dart` and `google_vertex_ai_api.dart` stay out of scope (fully commented dead files). | No custom backend; anonymous Horde key `'0000000000'` is the shipped default. Removing the dead files is tracked, not reviving them. | LL-014, LL-017 |
| _add below_ | | | |

---

## How to PAUSE (stop cleanly, lose nothing)

Run through this before you stop, even mid-task:

1. ☐ If the work forms a **coherent checkpoint**, commit it on the issue branch with a natural message that references the id. Do not manufacture a commit merely because the session is ending.
2. ☐ Do **not** commit secrets: `android/key.properties` and `android/upload-keystore.jks` are git-ignored and must never enter history (see [RUNBOOK.md](RUNBOOK.md)).
3. ☐ Update the **Status Board** (move the id to `In progress`/`Blocked`/`In review`).
4. ☐ Add a **Session Log** entry: goal, files changed, how far you got, exact uncommitted state, **exact next step**, blockers.
5. ☐ Update the **Current focus** block (active id, branch name, next step).
6. ☐ If blocked, write the blocker explicitly in both the board column and the log entry.
7. ☐ Push coherent commits. If backup or handoff truly requires a remote snapshot before a coherent checkpoint, use a clearly labeled WIP commit/push and record exactly what remains; otherwise leave the state uncommitted and documented.

## How to RESUME (cold start, zero context)

1. ☐ Read **Current focus**, then the **top Session Log entry** and the **Status Board**.
2. ☐ Check out the issue branch noted in Current focus; `flutter pub get`.
3. ☐ Re-run the quality gates to establish a clean baseline (see [DEVELOPMENT.md](DEVELOPMENT.md)):
   - `dart format --output=none --set-exit-if-changed lib test`
   - `flutter analyze`  (expect **0 issues**)
   - `flutter test`
   - If Hive models changed: `dart run build_runner build --delete-conflicting-outputs`
4. ☐ Open the id's full definition in [BACKLOG.md](BACKLOG.md) (Problem / Evidence `path:line` / Acceptance / Verification).
5. ☐ Follow the change workflow and per-issue Definition of Done in [RUNBOOK.md](RUNBOOK.md).
6. ☐ Continue from the **Next step** in the last log entry; update the board as state changes.

---

_Definitions of every LL-### are in [BACKLOG.md](BACKLOG.md). Execution steps, verification recipes, guardrails, and release/rollback are in [RUNBOOK.md](RUNBOOK.md)._
