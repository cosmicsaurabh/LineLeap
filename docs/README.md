# LineLeap Documentation Index

**Purpose:** the entry point to LineLeap's project documentation — navigate here first, then jump to the doc that fits what you're doing.

**Last updated:** 2026-07-29

**How to use this doc:** skim the synopsis, pick your path (Start here vs. Resume work), then open the linked doc. This index only routes you; the details live in the sibling docs. If documents conflict, [BACKLOG.md](BACKLOG.md) is canonical for issue definitions and [PROGRESS.md](PROGRESS.md) is canonical for live status.

---

## Project synopsis

LineLeap (`pubspec` name `lineleap`, version `1.0.1+14`) is a **Flutter sketch-to-image app**. You draw on a canvas, add a prompt, and the app runs a **queued img2img generation** against the **Stable Horde** public anonymous API. A completed image remains in the generation queue until the user explicitly promotes it into the local Hive gallery. It is **local-first**: there is **no custom backend, no auth, and no accounts**. The verified toolchain is **Flutter 3.44.1 (stable)** with **Dart 3.12.1**; `pubspec.yaml` permits Dart SDK `^3.7.0`. Android and macOS use id `com.lineleapp`; the iOS project still uses the placeholder `com.example.flutterScribble` and needs a release-specific bundle id before iOS distribution. State is `provider` (ChangeNotifier), DI is `get_it`, and local storage is `hive` + `hive_flutter`. The codebase is ~7,415 lines under `lib/` (~1,232 lines of tests) organized into `core / data / domain / presentation` layers, and `flutter analyze` is clean (0 issues). Only Stable Horde is wired; abandoned Replicate and Google Vertex stubs are not part of the source tree.

---

## The core docs

The six core docs below live under `docs/` and include this index. Read the one that matches your task.

| Doc | Read this when... |
|-----|-------------------|
| [README.md](README.md) (this file) | You need to find the right doc or learn the doc-maintenance rules. |
| [DEVELOPMENT.md](DEVELOPMENT.md) | You're setting up the project or need the everyday commands (install, codegen, format, analyze, test, run, build). |
| [ARCHITECTURE.md](ARCHITECTURE.md) | You need to understand how the system is built: layers, the queue pipeline, the Hive data model, DI, navigation, and "what not to change." |
| [BACKLOG.md](BACKLOG.md) | You need **what to do** — the canonical, prioritized `LL-###` issue registry (the single source of truth for IDs). |
| [PROGRESS.md](PROGRESS.md) | You're resuming or pausing work: status board, current focus, session log, and decisions. |
| [RUNBOOK.md](RUNBOOK.md) | You're about to execute an issue and need the standard workflow, per-change verification recipes, guardrails, and the release/rollback checklist. |

Also cross-linked where relevant: [AI_QUEUE_CASE_STUDY.md](AI_QUEUE_CASE_STUDY.md) — background narrative on the generation-queue design.

---

## Start here (brand-new contributor)

Follow this order the first time you touch the repo:

1. ☐ [DEVELOPMENT.md](DEVELOPMENT.md) — get it running (`flutter pub get`, codegen, `flutter run`) and pass the quality gates locally.
2. ☐ [ARCHITECTURE.md](ARCHITECTURE.md) — learn the layers and the queue pipeline before changing anything.
3. ☐ [BACKLOG.md](BACKLOG.md) — pick an issue by priority (P0→P3) and milestone (M1→M3).
4. ☐ [RUNBOOK.md](RUNBOOK.md) — execute it with the standard workflow and verification recipe.

## Resume work (returning after a break)

You've done setup before; you just need to remember where you left off:

1. ☐ [PROGRESS.md](PROGRESS.md) — read Current focus + the latest session-log entry.
2. ☐ [BACKLOG.md](BACKLOG.md) — re-read the issue you're on (Problem / Acceptance criteria / Depends-on).
3. ☐ [RUNBOOK.md](RUNBOOK.md) — follow the verification recipe and Definition of Done, then update PROGRESS.

---

## Doc maintenance rules

Keep the doc set mutually consistent. Update the canonical owner of each kind of information.

| When you... | Update... |
|-------------|-----------|
| Start, pause, finish, or change the live status of work | [PROGRESS.md](PROGRESS.md) (current focus + status board + session log) — **every session**. |
| Add, re-scope, re-prioritize, or clarify an issue definition | [BACKLOG.md](BACKLOG.md) — the **canonical** owner of every `LL-###` definition. |
| Change how the system is built (layers, queue, data model, DI) | [ARCHITECTURE.md](ARCHITECTURE.md). |
| Change setup steps, commands, or quality gates | [DEVELOPMENT.md](DEVELOPMENT.md). |
| Change the change-workflow, verification recipes, or release/rollback steps | [RUNBOOK.md](RUNBOOK.md). |
| Add a doc, rename one, or change navigation | This file ([README.md](README.md)). |

Rules to hold the line:

- **[BACKLOG.md](BACKLOG.md) is the single source of truth for issue IDs, titles, scope, priority, and milestone.** Never renumber or invent `LL-###` IDs elsewhere. Reference issues by ID **and** title, e.g. "LL-001 (undo/redo corruption)".
- **[PROGRESS.md](PROGRESS.md) is the single source of truth for live status.** Use `Not started`, `In progress`, `Blocked`, `In review`, `Done`, or `Won't do` there; do not mirror status fields in BACKLOG.
- **Use the shared priorities/milestones:** P0/P1/P2/P3 and M1 (Immediate, 1–2 days) / M2 (Short-term, 1–2 weeks) / M3 (Medium, 1–2 months).
- **Mark work `Done` only in [PROGRESS.md](PROGRESS.md)** after it has been merged and verified per [RUNBOOK.md](RUNBOOK.md).
- **Cite code as `path:line`** (e.g. `lib/presentation/common/providers/scribble_notifier.dart:133`) and cross-link sibling docs by relative path.
- **Keep the docs non-overlapping:** DEVELOPMENT = set up & run; ARCHITECTURE = how it's built; BACKLOG = what to do; PROGRESS = current state & log; RUNBOOK = how to execute + guardrails + release/rollback; README = navigation.

---

## Why this file is `README.md` and not `INDEX.md`

`.gitignore` contains a **bare line `INDEX.md`** (`.gitignore:53`). A bare filename with no path segment matches **any file named `INDEX.md` at any depth**, so `docs/INDEX.md` would be **silently git-ignored** — it would never be tracked or pushed, and you'd lose the index without warning. Therefore the documentation index **must** be named `docs/README.md`. Do not create or rename it to `INDEX.md`.
