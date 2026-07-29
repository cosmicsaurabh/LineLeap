# RUNBOOK

Purpose: the execution discipline for LineLeap — the exact steps to pick up an issue, change code without derailing, verify it for real, ship it, and roll it back if it breaks.

Last updated: 2026-07-29

## How to use this doc

- Read this **every time you start a change**. It is the process; [BACKLOG.md](BACKLOG.md) is the *what*, this is the *how*.
- Work one `LL-###` at a time. Open [BACKLOG.md](BACKLOG.md) for the issue's acceptance criteria and evidence, then follow the [Standard Change Workflow](#1-standard-change-workflow) top to bottom.
- Before merging, the [Definition of Done](#2-definition-of-done) must be fully checked. Before a store release, the [Release / Publish checklist](#6-release--publish-checklist) must be fully checked.
- Sibling docs: [README.md](README.md) (index) · [DEVELOPMENT.md](DEVELOPMENT.md) (setup & commands) · [ARCHITECTURE.md](ARCHITECTURE.md) (system reference & "what not to change") · [BACKLOG.md](BACKLOG.md) (canonical issues) · [PROGRESS.md](PROGRESS.md) (resume/pause tracker) · [AI_QUEUE_CASE_STUDY.md](AI_QUEUE_CASE_STUDY.md) (queue design narrative).
- Status vocabulary used here: Not started · In progress · Blocked · In review · Done · Won't do. Checkboxes: ☐ open, ☑ done.

---

## 1. Standard Change Workflow

Run these in order for every issue. Apply gates by change type as described in §2; record why a gate is not applicable instead of running irrelevant commands.

| # | Step | Command / action | Done when |
|---|------|------------------|-----------|
| 1 | **Review the starting state** | `git status --short --branch` | current work is accounted for; no unrelated staged or unstaged change will follow this issue |
| 2 | **Branch off `main`** | `git switch main` → `git pull --ff-only` → `git switch -c ll-###-<slug>` | fresh issue branch rooted at latest `main` |
| 3 | **Confirm the issue** | Open the `LL-###` section in [BACKLOG.md](BACKLOG.md) | you can restate Problem + Acceptance criteria + Evidence (`path:line`) |
| 4 | **Set PROGRESS** | Move the ID to *In progress* in [PROGRESS.md](PROGRESS.md); start a Session Log entry and set Current focus | tracker and branch name match reality |
| 5 | **Implement the smallest change** | Edit only files needed for this ID | diff is issue-scoped; no drive-by refactors (see [Guardrails](#5-guardrails--dont-derail)) |
| 6 | **Review scope** | `git status --short` → `git diff --check` → `git diff --stat` | every changed path belongs to the issue; no whitespace errors |
| 7 | **Gate: format** | For Dart changes: `dart format --output=none --set-exit-if-changed lib test` | exit 0; otherwise record N/A |
| 8 | **Gate: analyze** | For code/dependency/build changes: `flutter analyze` | **0 issues**; docs-only changes record N/A |
| 9 | **Gate: test** | For code changes: `flutter test` | all green; every behavioral fix has a regression test |
| 10 | **Gate: build** | For runtime/build changes: `flutter build apk --debug` | build succeeds; docs-only and test-only changes may record N/A |
| 11 | **Verify the change** | Run the matching [Verification Recipe](#3-verification-recipes-by-change-type) | acceptance criteria have evidence appropriate to the change type |
| 12 | **Prepare the handoff** | Update PROGRESS to *In review*; finish the Session Log; add a Decision only when a durable choice was made | tracker describes the reviewed diff and next action |
| 13 | **Stage and inspect** | `git add <issue-files>` → `git diff --cached --check` → `git diff --cached --stat` | only intended files are staged and the staged diff is clean |
| 14 | **Commit coherent progress** | Example: `git commit -m "Keep queued jobs alive across app restarts"` | one understandable checkpoint is committed |
| 15 | **Push the branch** | `git push -u origin HEAD` | remote branch contains the reviewed commit |
| 16 | **Open a PR** | `gh pr create --base main` (or use the GitHub UI) | PR references the `LL-###` ID and lists what changed + how verified |
| 17 | **Close after merge** | Sync `main`, verify the applicable smoke path, then move the ID to *Done* in the next tracker update | merged behavior—not merely an open PR—has been verified |

Commit when the work forms a meaningful, reviewable checkpoint. Do **not** create a WIP commit by default merely because a session is ending; update the tracker honestly and continue until the checkpoint is coherent.

> CI (`.github/workflows/flutter_ci.yml`) runs for direct pushes to `main` and pull requests **targeting** `main`; direct pushes to non-main branches do not run CI unless that branch has an open PR targeting `main`. CI is debug-only. Fixing these gaps is **LL-018 (Harden CI and release build)**.

---

## 2. Definition of Done

An issue is Done only when every universal box and every applicable change-type box is checked. Record `N/A — <reason>` for a conditional gate that does not fit the change.

Universal:

- ☐ The change implements exactly this ID with no unrelated edits
- ☐ All **Acceptance criteria** in the [BACKLOG.md](BACKLOG.md) entry are met
- ☐ Verification evidence from the matching recipe (§3) is recorded in the Session Log / PR
- ☐ **No dead code and no secrets added** — no new commented-out files, no `key.properties`/keystore/API keys committed (see §5)
- ☐ [PROGRESS.md](PROGRESS.md) board + Session Log updated; Decision logged if one was made
- ☐ Staged diff reviewed; coherent commit pushed
- ☐ PR merged into `main`; the merged state is verified and PROGRESS is moved to `Done` in the next tracker update

Conditional by change type:

- ☐ **Dart source or test change:** `dart format --output=none --set-exit-if-changed lib test` exits 0 and `flutter analyze` reports **0 issues**
- ☐ **Behavioral code change:** `flutter test` passes and a regression test covers the changed behavior
- ☐ **Runtime, dependency, Android, or build change:** `flutter build apk --debug` succeeds; release/build-system changes also run the relevant release smoke
- ☐ **UI/runtime behavior change:** behavior is verified live with `flutter run` using the matching recipe
- ☐ **Persistence/API change:** deterministic automated coverage uses a temp store or mock client; tests never use the live Horde endpoint
- ☐ **Docs-only change (LL-020):** links, commands, paths, headings, and cited facts are checked; Flutter runtime gates are N/A unless the doc changes or asserts a command
- ☐ **CI-only change (LL-018):** workflow syntax/config is reviewed and the intended push/PR trigger is observed in GitHub Actions; live in-app verification is N/A

---

## 3. Verification Recipes by change type

Pick the recipe(s) matching the behavior and files you changed. Runtime/UI recipes use `flutter run` on a device or emulator; tests, CI, and docs use the deterministic evidence named in their recipe.

### 3.1 Canvas / drawing — LL-001, LL-002, LL-012, LL-016

| ID | Manual verification |
|----|---------------------|
| **LL-001** (undo/redo corruption) | Draw stroke **A** (many points), then stroke **B**. Undo → **only B disappears; A stays fully intact** (every point renders, not a dot). Redo → B returns fully. Add/assert a test on **stroke point-count** after undo/redo, not stroke count. Evidence: `lib/presentation/common/providers/scribble_notifier.dart:133`. |
| **LL-002** (transparent capture) | Generate from the same sketch in **both light and dark theme**. Inspect the captured PNG (or a saved copy): background is **opaque**, no strokes-on-transparent remain, and both captures use the same agreed generation background. Compare alpha/pixels, not only appearance. Evidence: `lib/presentation/features/scribble/scribble_drawing_area.dart:22`. |
| **LL-012** (perf model) | Draw a long, complex multi-stroke sketch. No visible jank; profile confirms in-progress stroke isn't re-copied O(n²) and the toolbar doesn't rebuild per pointer sample. Evidence: `lib/presentation/features/scribble/scribble_painter.dart:64`. |
| **LL-016** (single tap) | A single **tap** places a visible dot/short mark, consistent across brush styles. Evidence: `lib/presentation/features/scribble/drawing_canvas.dart:37`. |

### 3.2 Queue / generation — LL-004, LL-005, LL-009, LL-021

Only Stable Horde is wired (`AI_HORDE_API_KEY` defaults to `'0000000000'`, the public anonymous key). Override with `flutter run --dart-define=AI_HORDE_API_KEY=<key>` for less-throttled testing.

| ID | Manual verification |
|----|---------------------|
| **LL-004** (long queues / resume / cancel / adaptive poll) | **Long job:** submit during a busy anonymous queue (or simulate via MockClient returning `queue_position`/`wait_time` for many polls) — job must **not** false-fail at the old ~6min / 20-attempt cap (`lib/data/remote/ai_horde_api.dart:77`). **Restart recovery:** enqueue → kill app mid-generation → relaunch → polling **resumes the persisted `generationId`**, does not resubmit a new job. **Cancel:** cancel a running job → app issues Horde `DELETE /api/v2/generate/status/{id}` (`ai_horde_api.dart:223`). Keep [AI_QUEUE_CASE_STUDY.md](AI_QUEUE_CASE_STUDY.md) accurate after this change. |
| **LL-005** (retention + ownership) | Create 21+ terminal jobs and restart: only the 20 most recent terminal records plus all active records remain. Cancelling retains the scribble while retry remains available; explicit removal/pruning deletes only queue-owned, unreferenced files. Promote a completed item, remove its queue record, and confirm both gallery images still load. |
| **LL-009** (cancel vs complete race) | Cancel a job **at the moment it finishes** (repeat to hit the window). Cancelled state must **survive** — a late `completed` write must not clobber it. Evidence: `lib/domain/usecases/process_generation_queue_usecase.dart:60`. |
| **LL-021** (position/ETA + notify) | Queue overlay shows **position + ETA** from the API. With permission granted, a best-effort local notification fires when the executing process observes completion; permission denial is handled and UI/docs do not promise completion after OS suspension or process death. Evidence: parsed but unused at `ai_horde_api.dart:100`. |

**Simulating long / failed / cancelled jobs:** use `MockClient` (see §3.4) to script the Horde status sequence — return `PENDING`/`queue_position` for N polls (long), a non-OK status (failed), or drive the local cancel path (cancelled) — so you don't depend on live queue timing.

### 3.3 Persistence / Hive — LL-005, LL-006, LL-007, LL-010

| ID | Manual verification |
|----|---------------------|
| **LL-006** (theme not restored) | Set a non-system theme → cold-restart the app → the **chosen theme is restored** (not hardcoded `ThemeMode.system`). Wire a `GetThemeMode` path through DI (`get_it`). Add a test. Evidence: `lib/presentation/common/providers/theme_notifier.dart`; `lib/data/repositories/theme_mode_repository_impl.dart`. |
| **LL-007** (absolute paths break iOS) | Seed records under one temporary documents root, then reopen them under a different root. Gallery, queue, share, delete, and Horde-input reads still work through relative paths and the centralized resolver; the legacy migration is idempotent. Evidence: `lib/core/service/image_device_interaction_service.dart:10`. |
| **LL-005** | See §3.2 (bounded records, explicit ownership transfer, and idempotent cleanup). |
| **LL-010** (identity/time/sort) | `createdAt` is set at enqueue; gallery/queue times use normalized UTC ISO-8601; legacy epoch/invalid values migrate deterministically; gallery sorts newest-first and deletes by stable `galleryId`, not path+timestamp. Evidence: `lib/presentation/features/scribble/queue_overlay_widget.dart:68`. |

**Enum-order safety (Hive):** Hive persists enums by **index**. Never reorder or remove existing enum values in a persisted type — only **append** new values at the end, or you silently remap old records. When touching persisted models, regenerate adapters: `dart run build_runner build --delete-conflicting-outputs`.

**Round-trip test recipe:** create an isolated directory with `Directory.systemTemp.createTemp(...)`, call `Hive.init(tempDir.path)`, register any required adapters, write queue/history records, close and reopen the boxes, and assert full-fidelity restore. Close Hive and delete the temp directory in teardown. This is the LL-019 M2 slice.

### 3.4 API — LL-004, LL-013

- Test Horde calls with **`MockClient`** from `package:http/testing.dart` — the existing pattern is `test/ai_horde_api_test.dart:13`. Inject the mock via the API's `client:` constructor param; script request→response per case (submit, poll PENDING×N, poll DONE, error status, DELETE cancel).
- **LL-013** (typed failures): assert `HordeApiException.kind`/`statusCode` propagate end-to-end (API → usecase → provider → widget) and are **not** flattened to `error.toString()` (regression at `process_generation_queue_usecase.dart`); no empty `catch` blocks; retryable vs non-retryable is distinguishable at the UI.
- Never point tests at the live Horde endpoint. Stable Horde is the only provider implementation; do not reintroduce the removed Replicate or Google Vertex stubs.

### 3.5 Compliance — LL-008

Release-blocking. Verify all before any store submission:

- ☐ Record the monitored report contact, service owner, retention policy, and direct in-app report transport/endpoint
- ☐ Direct submission shows success only after acknowledged receipt; `mailto:` is an explicitly labeled fallback and never counts as a submitted report
- ☐ Report contact, privacy-policy contact, and store listing reconciled to the same monitored contact
- ☐ `PRIVACY_POLICY.md` edited to match reality — **no** analytics / crash-reporting / cloud-backup / settings-toggle claims unless actually implemented (there is **no backend, no auth, no analytics**)
- ☐ `PLAYSTORE_APP_DESCRIPTION.md` matches real features (no overstated auto-retry / cloud backup) and declared permissions
- ☐ `android/app/src/main/AndroidManifest.xml:63` — drop `READ_MEDIA_VIDEO` (no video feature); drop `READ_MEDIA_IMAGES` if unused
- ☐ **LL-017** completed: fake selector/state removed and listing/screenshots do not imply DALL-E/Midjourney/Leonardo support

### 3.6 Error and gallery UX — LL-003, LL-011

| ID | Verification |
|----|--------------|
| **LL-003** (visible errors / offline) | With `flutter run`, force a Horde failure and a gallery load failure, then attempt generation offline. Each path shows an actionable message; slow queue copy is distinguishable from failure. Add provider/widget coverage for the shared error surface. |
| **LL-011** (recoverable delete) | Force failure before and after each delete step. A tombstone persists before the item is hidden, the error is visible, and reopen/reconciliation resumes idempotently. Repeated reconciliation converges with the row/tombstone and all owned files removed—without restoring a zombie. |

### 3.7 Product honesty, cleanup, and lifecycle — LL-014, LL-015, LL-017

| ID | Verification |
|----|--------------|
| **LL-014** (dead code / naming cleanup) | Use `rg` to prove every removed symbol/file has no live caller before deletion. Run format/analyze/test/build, then smoke startup, drawing, queue, and gallery paths affected by removals or renames. |
| **LL-015** (lifecycle hazards) | Repeatedly open/close the affected dialogs and pages under Flutter DevTools memory profiling. No controller/image growth, duplicate gallery load, `setState after dispose`, or lifecycle exception remains; add focused tests where the lifecycle can be driven deterministically. |
| **LL-017** (model selector) | Verify the fake selector entry point, sheet, and selection state are removed; no listing claim or screenshot implies runtime model selection; existing mocked Horde requests remain unchanged. |

### 3.8 Test coverage — LL-019, LL-019b

- **LL-019:** each new regression test must fail against the unfixed behavior and pass after the fix. Include LL-001 point counts, LL-006 theme restore, the temp-Hive round trip from §3.3, and history/queue repository cases.
- **LL-019b:** add widget coverage for scribble, gallery, and queue/generation pages plus an integration test for restart recovery. Run `flutter test`; run the configured integration-test target separately and record both results.

### 3.9 CI, build, and docs — LL-018, LL-020

| ID | Verification |
|----|--------------|
| **LL-018** (CI / release hardening) | Review workflow syntax and triggers; confirm a direct non-main push behaves as documented and a PR targeting `main` runs CI. Confirm the pinned Flutter version and intended debug/release jobs in the Actions log. Resolve or explicitly track Flutter 3.44.1 warnings that `image_gallery_saver_plus` lacks Swift Package Manager support and that the app/affected plugins still apply the Kotlin Gradle Plugin instead of Built-in Kotlin. Run the release smoke selected by the issue. |
| **LL-020** (documentation baseline) | Confirm `git ls-files docs/` includes the full doc set, all relative links resolve, cited paths/commands match the repository, `docs/README.md` remains the index, and `git status --short` shows no accidentally omitted doc. Flutter live-app gates are N/A. |

---

## 4. Secret & build-file handling

- **Never commit** `android/key.properties` or `android/upload-keystore.jks`. Both are git-ignored (`.gitignore:46-47`) and were **verified never in git history** — keep it that way.
- These files are required **only for release signing** (`android/app/build.gradle.kts:12,45`). **Debug builds, `flutter test`, and CI need NEITHER.**
- Never hard-code a Horde key. Override at runtime only: `flutter run --dart-define=AI_HORDE_API_KEY=<key>`. The committed default `'0000000000'` is the public anonymous key and is fine to leave.
- If you ever `git add -A`, re-check `git status` before commit for `.DS_Store`, `key.properties`, or `*.jks`. `.DS_Store` is already ignored and none are tracked; keep it that way.

---

## 5. Guardrails — don't derail

| Guardrail | Rule |
|-----------|------|
| **Respect "What not to change"** | Honor the constraints list in [ARCHITECTURE.md](ARCHITECTURE.md). Do not alter the layer dependency rule (**presentation → domain ← data**; domain depends on neither) or the queue pipeline contract as a side effect. |
| **Keep changes issue-scoped** | One `LL-###` per branch/PR. Spotted a second problem? File/append it in [BACKLOG.md](BACKLOG.md); don't fold it in. |
| **`INDEX.md` gotcha** | `.gitignore` has a bare `INDEX.md` (`.gitignore:53`) that ignores **any** file named `INDEX.md` at any depth. The docs index **must** stay `docs/README.md` — never create `docs/INDEX.md` (it would silently never commit). |
| **No secrets** | Never commit `key.properties` / `upload-keystore.jks` / real API keys (see §4). |
| **Analyze stays 0** | `flutter analyze` must remain **0 issues**. A change that adds warnings isn't done. |
| **Test with every behavioral fix** | Every behavior change ships with a regression test (see §3 recipes). No test → not Done. |
| **No new dead code** | Don't add commented-out files or unreachable widgets; the LL-014 cleanup is the baseline to preserve. |
| **Codegen after model edits** | Editing a Hive model → rerun `dart run build_runner build --delete-conflicting-outputs` and commit the regenerated `*.g.dart`. |

---

## 6. Release / Publish checklist

Do all of these before building a store artifact. Several are gated on open P1 issues.

- ☐ **Version bump** `version:` in `pubspec.yaml` (current `1.0.1+14`) — increment the `+build` for every upload
- ☐ **Compliance reconciled** — complete the full **LL-008** checklist (§3.5): contact, privacy policy, store description, permissions
- ☐ **Model selector honest** — **LL-017** completed: fake selector/state removed and screenshots/listing match
- ☐ **R8 decision** — **LL-018**: either **enable** `isMinifyEnabled`/`isShrinkResources` (currently `false` at `android/app/build.gradle.kts:53-54`, so `proguard-rules.pro` is dead config) **or delete `proguard-rules.pro` and document the choice**. If you enable R8, smoke-test a release build for missing-keep crashes.
- ☐ **Toolchain compatibility** — **LL-018**: resolve or explicitly document Flutter 3.44.1 warnings for `image_gallery_saver_plus` Swift Package Manager support and migration of the app/affected plugins from the Kotlin Gradle Plugin to Built-in Kotlin; do not upgrade Flutter blindly
- ☐ **Signing ready** — `android/key.properties` + `android/upload-keystore.jks` present locally (NOT committed)
- ☐ **Fresh screenshots** taken from the current build
- ☐ **Gates green** on the release commit: `dart format --output=none --set-exit-if-changed lib test` · `flutter analyze` (0) · `flutter test`
- ☐ **Build the store artifact:** `flutter build appbundle --release` (or `flutter build apk --release`) with signing configured
- ☐ **Store listing sanity** — declared features and permissions match the shipped binary (no under-declared/over-declared perms)
- ☐ **Case study current** — if this release changes the queue, update [AI_QUEUE_CASE_STUDY.md](AI_QUEUE_CASE_STUDY.md) (ties to **LL-004**, **LL-020**)
- ☐ **Tag** the release commit and record it in [PROGRESS.md](PROGRESS.md) Decisions

---

## 7. Rollback procedure

When a merged change breaks `main`, revert through a branch and PR so `main` remains protected and the rollback is reviewable:

| # | Step | Command / action |
|---|------|------------------|
| 1 | **Sync and identify** | `git switch main` → `git pull --ff-only` → `git log --oneline` |
| 2 | **Create a rollback branch** | `git switch -c revert-<short-slug>` |
| 3 | **Revert** the offending change | `git revert <merge-or-commit-sha>` (use `-m 1` for a merge commit) |
| 4 | **Re-run gates** | `dart format --output=none --set-exit-if-changed lib test` · `flutter analyze` · `flutter test` · `flutter build apk --debug` |
| 5 | **Re-verify** | Run the matching §3 recipe and confirm the broken flow is healthy |
| 6 | **Record and reopen** | Add a PROGRESS Decision, move the `LL-###` back to *Not started*/*In progress*, and note the regression in BACKLOG; commit that tracker update if changed |
| 7 | **Push and open the rollback PR** | `git push -u origin HEAD` → `gh pr create --base main` (or use the GitHub UI) |

> If a released build is broken, ship the reverted code as a new version/build and resubmit it using the **§6 Release / Publish checklist**.
