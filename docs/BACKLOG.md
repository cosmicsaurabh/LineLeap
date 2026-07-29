# LineLeap Backlog

**Purpose:** The canonical, prioritized registry of every known issue and objective for LineLeap. Each item has a permanent `LL-###` ID used across all docs.

**Last updated:** 2026-07-29

## How to use this doc

- This is the **single source of truth for issue IDs, titles, priorities, milestones, and implementation scope.** Never renumber, merge, reuse, or drop an ID. New work gets the next free `LL-###`.
- Pick work here; **track all live status only in [PROGRESS.md](PROGRESS.md)**. This file deliberately has no live status fields.
- To execute an item (branch, gates, verification, DoD), follow [RUNBOOK.md](RUNBOOK.md). Verification lines below use the RUNBOOK's exact section names.
- For how the system works (so an item makes sense), see [ARCHITECTURE.md](ARCHITECTURE.md). For setup and everyday commands, see [DEVELOPMENT.md](DEVELOPMENT.md). To navigate all docs, see [README.md](README.md).
- The AI queue engine (LL-004, LL-005, LL-009, LL-021) is documented in depth in [AI_QUEUE_CASE_STUDY.md](AI_QUEUE_CASE_STUDY.md) — read it before touching the queue.

**Priorities:** P0 = blocks core value / data loss · P1 = reliability/compliance before next release · P2 = correctness/quality · P3 = hygiene/polish.
**Milestones:** M1 = Immediate (1–2 days) · M2 = Short-term (1–2 weeks) · M3 = Medium (1–2 months).

---

## Summary table

| ID | Title | P | M | Effort |
|----|-------|---|---|--------|
| LL-001 | Undo/redo corrupts strokes into invisible dots | P0 | M1 | M |
| LL-002 | Canvas capture has a transparent background | P0 | M1 | S |
| LL-003 | Generation and gallery error details are hidden; offline guidance is missing | P0 | M1 | M |
| LL-006 | Saved theme is never restored on launch | P1 | M1 | S |
| LL-008 | Compliance: report email, privacy policy, and permissions contradict the app | P1 | M1 | L |
| LL-014 | Remove dead code, unused deps, and fix misnamed files | P1 | M1 | M |
| LL-020 | Establish and maintain the project documentation baseline | P1 | M1 | M |
| LL-004 | Long Horde queues fail; persist generationId, resume polling, remote cancel, adaptive polling | P1 | M2 | L |
| LL-005 | Bound queue history and define image-file ownership | P1 | M2 | L |
| LL-007 | Absolute file paths break the iOS gallery after app update | P1 | M2 | M |
| LL-017 | Remove the fake model selector | P1 | M2 | S |
| LL-018 | Harden CI and release build | P1 | M2 | M |
| LL-019 | Expand test coverage on the highest-risk paths | P1 | M2 | L |
| LL-021 | Show queue position/ETA and best-effort completion notifications | P1 | M2 | M |
| LL-009 | Make queue state transitions atomic and cancellation-safe | P2 | M3 | M |
| LL-010 | Add stable gallery IDs, normalized UTC timestamps, and deterministic sorting | P2 | M3 | M |
| LL-011 | Make gallery deletion recoverable and reconcilable | P2 | M3 | M |
| LL-013 | Unify error handling into one typed-failure flow | P2 | M3 | L |
| LL-012 | Rework canvas performance model | P2 | M3 | L |
| LL-015 | Fix memory leaks and lifecycle hazards | P2 | M3 | M |
| LL-016 | Single tap draws nothing | P2 | M3 | S |
| LL-019b | Widget & integration tests (deferred slice of LL-019) | P2 | M3 | L |

Effort key: XS ≈ <1h · S ≈ half-day · M ≈ 1–2 days · L ≈ 3+ days.

---

## P0 — Blocks core value / data loss (Milestone M1)

### LL-001 — Undo/redo corrupts strokes into invisible dots

- **Priority · Milestone · Effort:** P0 · M1 · M
- **Area:** Drawing canvas / state.
- **Problem:** The history snapshot is taken at `startStroke` while the stroke still holds a single point. `appendPoint` mutates the live stroke but never re-snapshots, so `undo`/`redo` restore a stale **1-point** stroke. The painter skips any stroke with fewer than 2 points, so the restored stroke renders invisibly (or as a dot), silently losing drawing data.
- **Impact:** Core drawing loses work. A user who draws, undoes, and redoes gets a mangled canvas — the app's primary interaction is untrustworthy.
- **Evidence:**
  - `lib/presentation/common/providers/scribble_notifier.dart:133-134` — `startStroke` snapshots `newStrokes` via `_saveToHistory` while the stroke has 1 point.
  - `lib/presentation/common/providers/scribble_notifier.dart:196-209` — `appendPoint` normal path mutates the last stroke's points but does **not** re-snapshot history.
  - `lib/presentation/common/providers/scribble_notifier.dart:245-255` — `_saveToHistory` truncates forward history and appends the passed list; snapshots are never refreshed on append.
  - `lib/presentation/features/scribble/scribble_painter.dart:82` — `if (stroke.points.length < 2) return;` (verified) drops short strokes from rendering.
- **Acceptance criteria:**
  - ☐ Draw stroke A, then stroke B; **undo** removes only B and leaves A intact with **all** its points.
  - ☐ **Redo** restores B fully with all its points.
  - ☐ History captures the completed stroke (with its full point list), not the 1-point start snapshot.
  - ☐ Regression test asserts the **point count** of each stroke after undo/redo, not merely the stroke count.
- **Verification:** RUNBOOK §3.1 "Canvas / drawing" — run the app, reproduce the A/B/undo/redo sequence manually, then add the point-count regression test (feeds LL-019). Gates: `flutter analyze`, `flutter test`.
- **Depends-on:** None. (Regression test contributes to LL-019.)

### LL-002 — Canvas capture has a transparent background

- **Priority · Milestone · Effort:** P0 · M1 · S
- **Area:** Capture pipeline.
- **Problem:** The capture `RepaintBoundary` wraps only `DrawingCanvas`; the visible white/dark surface color lives on an **ancestor** `Container`, so `toImage()` excludes it. The PNG sent to Horde is strokes-on-transparent and workers may flatten that alpha differently.
- **Impact:** Generation input is ambiguous and can vary by worker or theme presentation. The generation pipeline needs one deterministic canvas background.
- **Evidence:**
  - `lib/presentation/features/scribble/scribble_drawing_area.dart:22-41` (verified) — background color is on the outer `Container` (`isDark ? 0xFF2C2C2E : Colors.white`), while the `RepaintBoundary(key: paintKey)` wraps only `DrawingCanvas`, excluding that fill.
  - `lib/core/utils/image_utils.dart:7-25` (verified) — `capturePng` calls `boundary.toImage(pixelRatio: 3.0)` then `toByteData(format: png)`; no background is composited in.
- **Acceptance criteria:**
  - ☐ The PNG sent to Horde is composited over a fixed **opaque white (`#FFFFFFFF`) generation background**, regardless of the active app theme.
  - ☐ The on-screen drawing surface may remain theme-aware; only the captured generation input is normalized to white.
  - ☐ Stroke colors and geometry are preserved during compositing, with no transparent pixels in the output.
  - ☐ A regression test captures in light and dark themes and asserts identical white background pixels and full alpha.
- **Verification:** RUNBOOK §3.1 "Canvas / drawing" and §3.4 "API" — inspect captured PNG alpha/background in both themes, then confirm the normalized image is the one submitted in a mocked generation request.
- **Depends-on:** None.

### LL-003 — Generation and gallery error details are hidden; offline guidance is missing

- **Priority · Milestone · Effort:** P0 · M1 · M
- **Area:** Error surfacing / UX.
- **Problem:** The queue can show a coarse `failed` state, but it does not expose the failure reason or retryability. Capture/enqueue failures in `GenerationProvider` and load/save/delete failures in `GalleryNotifier` are stored in `_error` fields that no widget reads. The app also gives no useful guidance when generation is attempted without connectivity.
- **Impact:** Users can see that some queued jobs failed but cannot tell why or what to do; failures before enqueue and gallery failures can still appear to do nothing. A slow anonymous queue is also easy to confuse with an offline/network failure.
- **Evidence:**
  - `lib/presentation/common/providers/generation_provider.dart:24` — `_error` field, set in ~6 places but never surfaced.
  - `lib/presentation/common/providers/gallery_notifier.dart:52,76,92` — gallery load/delete error sets that no widget consumes.
  - No connectivity check exists anywhere in `lib/` (no `connectivity_plus` or equivalent).
- **Acceptance criteria:**
  - ☐ Capture/enqueue failures and terminal queue failures show an actionable message; queue errors include the stored reason and a retry affordance when appropriate.
  - ☐ Gallery load/save/delete failures show an equivalent actionable message.
  - ☐ Before or at enqueue, the UI explains that generation requires connectivity and that an anonymous Horde queue may be slow; a connectivity hint must not be treated as proof that a request will succeed.
  - ☐ Offline/network failures remain represented by the real request result, not only a preflight connectivity check.
  - ☐ Provider/widget tests cover one pre-enqueue failure, one queued provider failure, one gallery failure, and offline guidance.
- **Verification:** RUNBOOK §3.6 "Error and gallery UX" — force each failure class and confirm the message distinguishes slow, offline, retryable, and non-retryable outcomes. Ties into the typed-failure work in LL-013.
- **Depends-on:** None. Enables LL-011 (surface delete failures) and is the UI consumer for LL-013.

---

## P1 — Reliability / compliance before next release

### LL-006 — Saved theme is never restored on launch

- **Priority · Milestone · Effort:** P1 · M1 · S
- **Area:** Persistence.
- **Problem:** `setThemeMode` persists the choice, but the notifier hard-codes `ThemeMode.system` at startup and `getThemeMode` has zero callers — persistence is write-only.
- **Impact:** A user who picks light/dark is reset to system every cold start. Small but visible correctness/quality bug affecting first impression.
- **Evidence:**
  - `lib/presentation/common/providers/theme_notifier.dart:6` (verified) — `ThemeMode _themeMode = ThemeMode.system;` hard-coded default; constructor takes only `SetThemeModeUseCase`, no read-back.
  - `lib/data/repositories/theme_mode_repository._impl.dart:14-20` — `getThemeMode` exists but has **zero callers** (note the typo filename, cleaned up under LL-014).
- **Acceptance criteria:**
  - ☐ On cold start the app restores the last chosen theme.
  - ☐ A `GetThemeMode` path is wired through DI (get_it) into the notifier.
  - ☐ Theme initialization completes before the first app frame (or an explicit startup gate is shown), so the UI does not flash the wrong theme.
  - ☐ Covered by a test (contributes to LL-019).
- **Verification:** RUNBOOK §3.3 "Persistence / Hive" — set a theme, fully restart, confirm restoration, and add the theme-restore test.
- **Depends-on:** None. (Typo filename `theme_mode_repository._impl.dart` is renamed in LL-014 — coordinate ordering to avoid churn.)

### LL-008 — Compliance: report email, privacy policy, and permissions contradict the app

- **Priority · Milestone · Effort:** P1 · M1 · L
- **Area:** Compliance / release.
- **Problem:** The privacy policy over-discloses data collection that never happens (analytics, crash reporting, cloud backup, a settings toggle that does not exist). The report-content flow opens a mail composer addressed to a personal Gmail, reports success even when no message is sent, and conflicts with the policy's `support@lineleap.app` contact. The Android manifest requests media permissions the app does not use (there is no video feature). The Play Store description overstates auto-retry and cloud backup and under-declares permissions.
- **Impact:** Direct Play Store rejection / policy-violation risk, reports that are never delivered, and a broken/mismatched user-facing support contact. Blocks a compliant release.
- **Evidence:**
  - `lib/presentation/common/widgets/report_content_dialog.dart:81` (verified) — `mailto` target is `saurabh.iiitk.job@gmail.com` (personal Gmail).
  - `PRIVACY_POLICY.md` — claims analytics / crash reporting / cloud backup / a settings toggle that do not exist; lists `support@lineleap.app`.
  - `PLAYSTORE_APP_DESCRIPTION.md` — overstated auto-retry / cloud backup; under-declared permissions.
  - `android/app/src/main/AndroidManifest.xml:63-64` — `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO` requested (no video feature exists).
- **Acceptance criteria:**
  - ☐ **Required product decision:** name the monitored reporting contact, service owner, retention policy, and approved direct transport/endpoint before implementation; record the decision in PROGRESS.
  - ☐ Submit reports directly in-app through that approved transport. A `mailto:` composer may be offered only as an explicit fallback and must never count as a submitted report.
  - ☐ Show success only after the transport acknowledges receipt; delivery failure stays visible and offers retry without losing the user's reason/comment.
  - ☐ Report contact, privacy-policy contact, and store listing are reconciled to the same monitored contact.
  - ☐ Policy edited to match reality — remove analytics/crash/cloud claims and the non-existent settings toggle unless actually implemented.
  - ☐ Drop `READ_MEDIA_VIDEO`; drop `READ_MEDIA_IMAGES` too if unused.
  - ☐ Store description matches real features, report behavior, and the final permission set.
  - ☐ Tests cover acknowledged delivery, transport failure, retry, and the optional mail fallback without false success.
- **Verification:** RUNBOOK §3.5 "Compliance" — cross-check each policy/description claim against code and the final manifest; submit against a mocked transport and verify success/failure semantics. Build still passes (`flutter build apk --debug`).
- **Depends-on:** None. Store-listing wording also touched by LL-017 (fake model selector) and LL-021 (notifications) — keep the description consistent as those land.

### LL-014 — Remove dead code, unused deps, and fix misnamed files

- **Priority · Milestone · Effort:** P1 · M1 · M
- **Area:** Hygiene.
- **Problem:** Large amounts of dead code, unused dependencies, unregistered/unused adapters, dead DI chains, and typo filenames inflate the codebase and mislead readers.
- **Impact:** Every future change is harder to reason about; a cold reader cannot tell live code from corpses. Reduces surface area and analyzer noise before release.
- **Evidence:**
  - `lib/data/remote/replicate_api.dart`, `lib/data/remote/google_vertex_ai_api.dart` — fully commented-out dead files.
  - `lib/presentation/features/scribble/generated_image_viewer.dart` — 428 lines, unreachable (also leaks a controller per LL-015).
  - ~8 unused widgets: `GlassContainer`, `AnimatedLoadingIndicator`, `AnimatedDialogWrapper`, `QueueEmptyState`, `ScribbleeToolbar`, `ToolbarIconButton`, `FadeSlideTransition`, `toolbar/action_button.dart`.
  - `lib/core/utils/logger.dart` — empty file.
  - `lib/data/models/date_time_adapter.dart` — unregistered adapter.
  - Dead DI chain: `ImageGenerationRepository` → `ImageGenerationRepositoryImpl` → `GenerateTransformationfromscribbleUseCase`, plus `DeleteImagebytesFromPathUseCase`.
  - Unused deps in `pubspec.yaml`: `adaptive_dialog`, `flutter_staggered_grid_view`.
  - Typo files: `theme_mode_repository._impl.dart`, `mirrot_mode.dart` (and their classes).
- **Acceptance criteria:**
  - ☐ Dead files, unused widgets, and dead DI registrations removed.
  - ☐ `adaptive_dialog` and `flutter_staggered_grid_view` dropped from `pubspec.yaml`.
  - ☐ Typo filenames and classes renamed (`theme_mode_repository._impl.dart`, `mirrot_mode.dart`).
  - ☐ `flutter analyze` still reports **0 issues**; app builds and `flutter test` passes.
- **Verification:** RUNBOOK §3.7 "Product honesty, cleanup, and lifecycle" plus §1 "Standard Change Workflow" — prove removed symbols have no live callers, then run `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter build apk --debug`.
- **Depends-on:** Coordinate with LL-006 (renames `theme_mode_repository._impl.dart`) and LL-015 (removes `generated_image_viewer.dart`, which also leaks a controller) so deletions land once.

### LL-020 — Establish and maintain the project documentation baseline

- **Priority · Milestone · Effort:** P1 · M1 · M
- **Area:** Docs.
- **Problem:** The architecture, backlog, operating workflow, live progress, and queue case study need one version-controlled, mutually linked baseline. Without that baseline, implementation decisions and queue behavior are easy to lose or contradict.
- **Impact:** Contributors cannot reliably resume work, reviewers miss the engineering rationale, and implementation can proceed from stale assumptions.
- **Evidence:** The documentation set lives under `docs/`; `.gitignore:53` contains a bare `INDEX.md`, so the index must remain `docs/README.md`.
- **Acceptance criteria:**
  - ☐ The full documentation set, including `AI_QUEUE_CASE_STUDY.md`, is version-controlled and reachable from `docs/README.md`.
  - ☐ Relative links resolve; cited paths, commands, package identifiers, toolchain versions, and current architecture claims match the repository.
  - ☐ BACKLOG owns issue definitions while PROGRESS alone owns live status; no document embeds temporary working-tree-state claims.
  - ☐ Any PR that changes queue behavior also updates the case study and relevant architecture/runbook text.
- **Verification:** RUNBOOK §3.9 "CI, build, and docs" — confirm `git ls-files docs/` includes the full set, links and citations resolve, and `docs/README.md` remains the index.
- **Depends-on:** None. LL-004 does not block this baseline; LL-004 must update the case study when it changes queue behavior.

### LL-004 — Long Horde queues fail; persist generationId, resume polling, remote cancel, adaptive polling

- **Priority · Milestone · Effort:** P1 · M2 · L
- **Area:** Queue engine / API.
- **Problem:** Polling stops after 20 attempts (about 5m50 of scheduled backoff, plus request time). Anonymous Horde queues can outlast that fixed attempt budget, producing **false failures**. The Horde job id is never stored on the request, so retry/restart resubmit brand-new jobs — losing queue position and duplicating backend work — and abandoned jobs are never cancelled server-side.
- **Impact:** The core generation flow fails on exactly the free/anonymous path most users hit, and wastes shared Horde capacity. This is the app's central reliability problem.
- **Evidence:**
  - `lib/data/remote/ai_horde_api.dart:77-99,212-289` — 20-attempt polling loop with about 5m50 of scheduled delay; response latency and per-request timeouts make wall time longer.
  - `lib/domain/entities/generation_request.dart:14` — `generationId` field is never assigned.
  - `lib/data/services/horde_generation_service_impl.dart:37-55` combines submit and poll in one call, so the queue use case has no seam at which it can persist the returned id before polling.
  - `lib/domain/usecases/process_generation_queue_usecase.dart` orchestrates only the combined service call; recovered or retried work resubmits rather than resuming.
- **Acceptance criteria:**
  - ☐ Split provider submission from polling at the API/service seam: submit returns a `generationId`; poll accepts an existing id.
  - ☐ Persist `generationId` to both queue stores **immediately after a successful submit and before the first poll**. A queued request with no id may submit; a request with an id must not submit again by default.
  - ☐ On restart, recovered `submitting`/`polling` work with an id resumes polling that id. A record without an id returns to `queued` and may submit once.
  - ☐ Retry rules are explicit: a retryable transport/timeout failure with an id resumes polling; a provider-confirmed terminal/faulted/missing job clears the old id and may submit a new job; retrying a locally or remotely cancelled request starts a new job.
  - ☐ Local cancel stops local polling and, when an id exists, calls Horde `DELETE /api/v2/generate/status/{id}`. The request remains locally cancelled even if remote cleanup fails, and the cleanup failure is logged/surfaced for retry.
  - ☐ Polling budget adapts using API `wait_time` / `queue_position` instead of a fixed 20 attempts.
  - ☐ Tests prove one submit per id, persistence before polling, restart/retry resume, terminal-job resubmit, and remote cancel path/method.
- **Verification:** RUNBOOK §3.2 "Queue / generation" and §3.4 "API" — script submit/poll/cancel with `MockClient`, kill/restart after id persistence, and confirm the same id resumes without a second submit. Update [AI_QUEUE_CASE_STUDY.md](AI_QUEUE_CASE_STUDY.md) in the same change.
- **Depends-on:** None. Land before LL-009 and LL-021; coordinate its queue-record changes with LL-005.

### LL-005 — Bound queue history and define image-file ownership

- **Priority · Milestone · Effort:** P1 · M2 · L
- **Area:** Persistence / storage.
- **Problem:** Terminal records (completed/failed/cancelled) are restored forever, while explicit queue removal deletes only the record. The queue initially owns scribble/generated files, but gallery promotion stores the same paths and then removes the queue record; cleanup cannot safely delete files without a defined ownership transfer.
- **Impact:** Without retention, records and queue-owned files grow without bound. Without ownership rules, a cleanup fix can either leak files or delete images that the gallery still references.
- **Evidence:**
  - `lib/data/repositories/generation_queue_repo_impl.dart:15-28,59-62` — terminal records restored verbatim; removal drops the record only.
  - Datasource `clear()` and notifier `clearQueue()` have **zero callers**.
- **Acceptance criteria:**
  - ☐ Retain all active requests plus the **20 most recent terminal records**, ordered by terminal time with a deterministic fallback; prune older terminal records during restore and after new terminal transitions.
  - ☐ A request owns its scribble/generated files while they are queue-only. Cancelling retains the scribble while the cancelled record remains retryable; explicit removal or retention pruning deletes only queue-owned, unreferenced files. Deletion is idempotent.
  - ☐ Successful gallery promotion atomically saves the gallery record and transfers ownership before removing the queue record. Queue removal/pruning must never delete a path referenced by the gallery.
  - ☐ If gallery promotion fails, the queue record and its owned files remain intact for retry.
  - ☐ Tests cover 21+ terminal records, active-record preservation, explicit removal/cancel cleanup, failed promotion, successful ownership transfer, restart, and repeated cleanup.
- **Verification:** RUNBOOK §3.2 "Queue / generation" and §3.3 "Persistence / Hive" — exceed the 20-record cap, restart, inspect both boxes/files, and prove promoted gallery images still load while queue-only files are reclaimed.
- **Depends-on:** Coordinate with LL-004 (queue model/transitions), LL-007 (path resolution), and LL-011 (idempotent cleanup/reconciliation).

### LL-007 — Absolute file paths break the iOS gallery after app update

- **Priority · Milestone · Effort:** P1 · M2 · M
- **Area:** Persistence.
- **Problem:** Absolute app-container paths are persisted in Hive, but an iOS container base path is not a durable identifier and can change across updates/restores. A changed base leaves stored paths dangling even when the files and Hive records still exist.
- **Impact:** A container-path change can make the gallery appear empty until paths are re-resolved. This is release-blocking for a reliable iOS build.
- **Evidence:**
  - `lib/core/service/image_device_interaction_service.dart:10-14` — writes/reads absolute paths.
  - Absolute paths persisted in Hive via `scribble_transformation_hive_model` and `generation_queue_local_datasource`.
- **Acceptance criteria:**
  - ☐ Introduce one centralized app-document path resolver used by image save/read/delete, queue restore, gallery load, promotion, and cleanup. Callers do not concatenate container paths themselves.
  - ☐ Store normalized relative paths for all new queue and gallery records; reject traversal outside the app documents directory.
  - ☐ Add an idempotent migration for both boxes: preserve valid relative paths, convert legacy absolute paths to their app-document-relative suffix, resolve them against the current container, and persist the converted value once.
  - ☐ Invalid/unresolvable legacy records are reported and skipped/quarantined without crashing startup or deleting unrelated files.
  - ☐ Round-trip and migration tests use two different temporary document roots and prove the same records resolve after the root changes.
- **Verification:** RUNBOOK §3.3 "Persistence / Hive" — seed both legacy absolute and relative records, reopen under a different temp root, verify migration/read/delete, and confirm a second migration run is a no-op.
- **Depends-on:** Coordinate the shared migration with LL-005 and LL-010 so the same records are rewritten once.

### LL-017 — Remove the fake model selector

- **Priority · Milestone · Effort:** P1 · M2 · S
- **Area:** Product honesty.
- **Problem:** The model-selector sheet offers DALL-E 3 / Midjourney / Leonardo — models Horde cannot serve — and the selection is never sent to the API. The current product supports one Horde generation path, so this control has no honest behavior.
- **Impact:** The UI lies about capability; a store reviewer or user who tests it finds a dead control. Honesty/compliance risk before release.
- **Evidence:**
  - `lib/presentation/features/scribble/model_selector_sheet.dart:12-17` — hard-coded fake model list.
  - `lib/presentation/features/scribble/scribble_page.dart:40,372-379` — selection state exists but is not threaded into the enqueue/API payload.
- **Acceptance criteria:**
  - ☐ Remove the selector entry point, sheet, and unused selection state.
  - ☐ Remove store-listing text and screenshots that imply DALL-E, Midjourney, Leonardo, or runtime model selection.
  - ☐ Keep the existing Horde request behavior unchanged.
  - ☐ Treat future selection among real Horde models as separately scoped work with its own model-discovery and persistence design.
- **Verification:** RUNBOOK §3.7 "Product honesty, cleanup, and lifecycle" — confirm no selector entry point, stale state, model claim, or screenshot remains; the existing mocked Horde request tests still pass.
- **Depends-on:** LL-008 (store description must match).

### LL-018 — Harden CI and release build

- **Priority · Milestone · Effort:** P1 · M2 · M
- **Area:** CI/CD / build.
- **Problem:** The Flutter version in CI is unpinned. Direct pushes run CI only on `main`; PRs targeting `main` already run regardless of source branch, so feature work gets remote checks only once a PR exists. The build is debug-only; R8/shrink are disabled so `proguard-rules.pro` is dead config; there is no artifact or coverage output. Flutter 3.44.1 also warns that `image_gallery_saver_plus` lacks Swift Package Manager support and that the app/plugins still use the Kotlin Gradle Plugin instead of Built-in Kotlin.
- **Impact:** Pre-PR branch pushes can drift unchecked, CI can silently change toolchains, the release path is unexercised, and a future Flutter upgrade can turn known iOS/Android compatibility warnings into build errors.
- **Evidence:**
  - `.github/workflows/flutter_ci.yml:3-7` — direct pushes are filtered to `main`; `pull_request.branches: [main]` filters the PR base, not its source branch.
  - `.github/workflows/flutter_ci.yml:17-21,35-36` — `setup-flutter` uses unpinned `stable`; the final step is `flutter build apk --debug`.
  - `android/app/build.gradle.kts:53-54` — `isMinifyEnabled = false`, `isShrinkResources = false`.
  - `android/app/proguard-rules.pro` — dead config while shrink is off.
  - Flutter 3.44.1 command output warns about missing Swift Package Manager support; `android/gradle.properties:7` sets `android.builtInKotlin=false`, and the app applies `kotlin-android`.
- **Acceptance criteria:**
  - ☐ Pin Flutter **3.44.1** in CI and document the intentional upgrade procedure.
  - ☐ Keep PR checks for every PR targeting `main`; also run push checks on active development branches (or explicitly adopt and document a PR-only policy with required checks before merge).
  - ☐ Add a release-build smoke or gated release job with an explicit signing strategy that does not expose keystore secrets.
  - ☐ Enable R8 + resource shrinking, **or** delete `proguard-rules.pro` and document the choice.
  - ☐ Resolve or explicitly pin/track the `image_gallery_saver_plus` Swift Package Manager warning before a Flutter upgrade.
  - ☐ Plan and verify migration of the app and affected plugins from the Kotlin Gradle Plugin to Built-in Kotlin before Flutter makes it mandatory.
  - ☐ Run tests with coverage and upload `coverage/lcov.info` plus the debug APK as CI artifacts; this issue adds visibility, not a new coverage threshold.
- **Verification:** RUNBOOK §3.9 "CI, build, and docs" and §6 "Release / Publish checklist" — inspect trigger behavior for a direct branch push and a PR targeting `main`, confirm the pinned toolchain/jobs, and run the selected release smoke.
- **Depends-on:** None; strengthens verification for all other items.

### LL-019 — Expand test coverage on the highest-risk paths

- **Priority · Milestone · Effort:** P1 · M2 · L
- **Area:** Testing.
- **Problem:** Only ~10 tests exist (~409 lines). Untested: repositories, Hive persistence/adapters/migrations, gallery, DI, all presentation widgets, `horde_generation_service_impl`, datasources, and most usecases.
- **Impact:** No safety net under the exact code the P0/P1 fixes touch; regressions ship unnoticed. Coverage is the precondition for confident change.
- **Evidence:** `test/` — 10 tests today; the modules above have no coverage.
- **Acceptance criteria (M2 slice):**
  - ☐ Regression test for LL-001 asserting stroke **point counts** after undo/redo.
  - ☐ Regression test for LL-006 theme restore on cold start.
  - ☐ Queue persistence save/restore **round-trip** against a temp Hive dir.
  - ☐ Repository tests for history + queue.
- **Verification:** RUNBOOK §3.8 "Test coverage" and §1 "Standard Change Workflow" — `flutter test` is green and each new regression test fails against the pre-fix code before passing after the fix.
- **Depends-on:** Pairs with LL-001 and LL-006 (their regression tests live here). Widget/integration coverage is deferred to **LL-019b**.

### LL-021 — Show queue position/ETA and best-effort completion notifications

- **Priority · Milestone · Effort:** P1 · M2 · M
- **Area:** Product / retention.
- **Problem:** `queue_position` and `wait_time` are already parsed into `HordeGenerationProgress` but never displayed. The app has no completion signal outside the queue UI, and its in-process polling is not guaranteed to run after the OS suspends or kills the app.
- **Impact:** Long anonymous-queue waits feel broken; users abandon before completion. Directly affects retention and perceived reliability.
- **Evidence:**
  - `lib/data/remote/ai_horde_api.dart:100-128` (verified) — `HordeGenerationProgress` holds `queuePosition` / `waitTimeSeconds`, surfaced only as a coarse `percentEstimate`; position/ETA are not shown.
  - Presentation queue widgets do not render position or ETA.
- **Acceptance criteria:**
  - ☐ Queue overlay shows **position + ETA** from the API.
  - ☐ Request notification permission contextually and emit a **best-effort local notification** when the running app observes completion (add `flutter_local_notifications`).
  - ☐ UI/docs state the boundary honestly: notification is not guaranteed after OS suspension/process death because reliable background execution is out of scope for this issue.
  - ☐ Do not claim background completion unless a later platform background-worker design is implemented and tested separately.
  - ☐ Expectation-setting copy is present (e.g. "Anonymous queue can take several minutes").
- **Verification:** RUNBOOK §3.2 "Queue / generation" — feed scripted position/ETA updates, verify permission-denied and app-running notification paths, and verify copy does not promise notification after suspension. Keep store wording aligned through LL-008.
- **Depends-on:** LL-004 (adaptive polling exposes the same `wait_time`/`queue_position`); LL-008 (description honesty).

---

## P2 — Correctness / quality (Milestone M3)

### LL-009 — Make queue state transitions atomic and cancellation-safe

- **Priority · Milestone · Effort:** P2 · M3 · M
- **Area:** Queue concurrency.
- **Problem:** `processQueue` persists a **captured** local request at the end, while cancellation and async progress callbacks write independently. A cancel that lands after the last token check but before the final persist can be overwritten by `completed` (last-write-wins).
- **Impact:** A user's cancel silently fails and the item completes anyway — confusing, and wastes a slot. Data-integrity bug in the queue.
- **Evidence:** `lib/domain/usecases/process_generation_queue_usecase.dart:60-113,153-172`.
- **Acceptance criteria:**
  - ☐ Route every state change through one per-request serialized compare-and-set transition API (`allowed current states` → `next state`).
  - ☐ Validate the latest record and update Hive plus memory as one repository operation; reject stale transitions without overwriting newer state.
  - ☐ `cancelled` cannot transition to `polling` or `completed`; duplicate terminal transitions are idempotent.
  - ☐ Progress callbacks await transitions and never mutate a shared captured request.
  - ☐ Deterministic tests force cancel-vs-progress and cancel-vs-complete interleavings and assert memory and Hive remain `cancelled`.
- **Verification:** RUNBOOK §3.2 "Queue / generation" — run deterministic concurrency tests for each interleaving, then repeat near-completion cancellation manually.
- **Depends-on:** LL-004 defines the revised submit/poll transition flow; implement this immediately after or in the same coordinated queue change.

### LL-010 — Add stable gallery IDs, normalized UTC timestamps, and deterministic sorting

- **Priority · Milestone · Effort:** P2 · M3 · M
- **Area:** Data model.
- **Problem:** `GenerationRequest.createdAt` is not set at enqueue. New gallery rows save an epoch-millisecond string, loads are unsorted, and deletion looks up a row by generated path plus timestamp. The ISO/`"-"` value built for queue preview is transient display data, not a second persisted gallery format.
- **Impact:** Ordering changes after reload and deletion identity is coupled to mutable metadata.
- **Evidence:**
  - `lib/presentation/features/scribble/queue_overlay_widget.dart:68-70` persists epoch milliseconds; `:92-95` creates ISO/`"-"` only for a transient preview entity.
  - `lib/domain/usecases/enqueue_generation_request_usecase.dart:14-23` does not set `createdAt`.
  - `lib/data/repositories/history_repository_impl.dart:15-24,31-38` loads without sorting and deletes by path + timestamp.
- **Acceptance criteria:**
  - ☐ Add an immutable UUID `galleryId`, assigned once on promotion and used for lookup/delete.
  - ☐ Store gallery and queue creation times as normalized **UTC ISO-8601 strings**; set queue `createdAt` at enqueue.
  - ☐ Idempotently migrate legacy rows: preserve existing ids, otherwise generate/persist one once; normalize epoch/ISO timestamps and use existing Hive order as the deterministic fallback for invalid/missing values.
  - ☐ Sort newest-first by creation time, with `galleryId` as tie-breaker.
  - ☐ Tests cover mixed legacy values, duplicate times, migration twice, restart ordering, and delete-by-id.
- **Verification:** RUNBOOK §3.3 "Persistence / Hive" — seed legacy records, migrate twice, verify stable newest-first order across reopen, and delete the intended duplicate-time row by id.
- **Depends-on:** Coordinate the single Hive migration with LL-007; the stable id is the basis for LL-011 tombstones.

### LL-011 — Make gallery deletion recoverable and reconcilable

- **Priority · Milestone · Effort:** P2 · M3 · M
- **Area:** Gallery / storage.
- **Problem:** The item is removed from the list before async deletion; on failure it is never reinserted. The repository deletes the Hive row before files and swallows file-delete failures, so partial failure can create zombies or orphaned files.
- **Impact:** Cleanup cannot resume safely and repeated attempts do not reliably converge.
- **Evidence:**
  - `lib/presentation/common/providers/gallery_notifier.dart:83-95` — optimistic list removal with no rollback on failure.
  - `lib/data/repositories/history_repository_impl.dart:38-51` — deletes the Hive row first, swallows file-delete errors.
- **Acceptance criteria:**
  - ☐ Delete by LL-010's stable `galleryId` and persist a deletion tombstone before hiding the item.
  - ☐ File deletion is idempotent (`already missing` is success); remove the row/tombstone only after all owned files are gone.
  - ☐ Startup/load reconciliation resumes incomplete tombstones, and repeated delete/reconcile calls converge.
  - ☐ Recoverable failure keeps the tombstone for retry, surfaces an error through LL-003, and never restores the item as a normal gallery row.
  - ☐ Tests inject failures before/after each deletion step and prove reopen + reconciliation leaves neither zombies nor orphans.
- **Verification:** RUNBOOK §3.6 "Error and gallery UX" — inject each partial failure, reopen, reconcile, and verify the stable id, tombstone, files, and visible error converge correctly.
- **Depends-on:** LL-003 (error surface), LL-005 (ownership/idempotent cleanup), and LL-010 (stable id + migration).

### LL-013 — Unify error handling into one typed-failure flow

- **Priority · Milestone · Effort:** P2 · M3 · L
- **Area:** Cross-cutting.
- **Problem:** Three coexisting conventions — return-null, rethrow, and typed exceptions. Rich failure info (`HordeApiException.kind` / `statusCode`) is flattened to `error.toString()` before the UI, and there is an empty catch that drops errors entirely. Retryability is lost.
- **Impact:** The UI cannot tell retryable from fatal, cannot show useful messages, and can silently swallow failures. Foundational to good error UX.
- **Evidence:**
  - Mixed styles across `data/`, `usecases/`, `providers/`.
  - `lib/domain/usecases/process_generation_queue_usecase.dart` — `HordeApiException.kind`/`statusCode` flattened to `error.toString()`; empty catch at `:148-150`.
- **Acceptance criteria:**
  - ☐ One `Result`/typed-failure convention from API → usecase → provider → widget.
  - ☐ Retryable vs non-retryable surfaced to the user.
  - ☐ No empty catches remain.
- **Verification:** RUNBOOK §3.4 "API" and §3.6 "Error and gallery UX" — inject typed failures of each kind, confirm the correct message/retry affordance, and verify no empty `catch {}` remains.
- **Depends-on:** LL-003 is the UI consumer of these typed failures; build LL-003 first, then generalize here.

### LL-012 — Rework canvas performance model

- **Priority · Milestone · Effort:** P2 · M3 · L
- **Area:** Performance.
- **Problem:** Every pointer sample copies stroke lists (O(n²)) and repaints all strokes with paths re-tessellated; `shouldRepaint` is ref-based and always true; the pinned toolbar rebuilds 60–120×/sec while drawing.
- **Impact:** Visible jank on complex drawings and battery drain; the core drawing experience degrades as art grows.
- **Evidence:**
  - `lib/presentation/common/providers/scribble_notifier.dart:196-209` — O(n²) list copies on each `appendPoint`.
  - `lib/presentation/features/scribble/scribble_painter.dart:64-121` — full repaint per sample; `shouldRepaint` always true.
  - `lib/presentation/features/scribble/pinned_toolbar_overlay.dart:32` — toolbar rebuild storm.
- **Acceptance criteria:**
  - ☐ Appending an in-progress stroke avoids copying the full point history on every sample, while completed/history snapshots remain immutable and cannot be changed by later drawing.
  - ☐ Repaint invalidation uses an explicit revision/listenable or equivalent dirty signal; mutating a list in place must not make `shouldRepaint` incorrectly return false.
  - ☐ Completed strokes cached to a `Picture`/layer.
  - ☐ Point decimation has a documented visual tolerance and preserves endpoints.
  - ☐ Scoped rebuilds so the toolbar does not rebuild per sample.
  - ☐ No visible jank on complex drawings.
- **Verification:** RUNBOOK §3.1 "Canvas / drawing" — profile a long, dense drawing before/after and confirm the toolbar no longer rebuilds per pointer sample.
- **Depends-on:** Interacts with LL-001 (history/append semantics) — land LL-001's correctness fix first so in-place mutation doesn't reintroduce the snapshot bug.

### LL-015 — Fix memory leaks and lifecycle hazards

- **Priority · Milestone · Effort:** P2 · M3 · M
- **Area:** Lifecycle.
- **Problem:** Controllers are never disposed, `setState` runs after `await` without a `mounted` check, the gallery loads twice, and captured `ui.Image` objects are never disposed.
- **Impact:** Growing memory use and "setState after dispose" crashes over a session. Stability/quality issue.
- **Evidence:**
  - `lib/presentation/features/gallery/gallery_image_dialog.dart:31` — `TransformationController` never disposed; `:72-74` — `setState` before a `mounted` check.
  - `lib/presentation/features/scribble/generated_image_viewer.dart:24` — controller leak (this whole file is also dead per LL-014).
  - Double gallery load: `gallery_notifier` constructor + `gallery_page` `initState` under an `IndexedStack`.
  - Captured `ui.Image` never disposed.
- **Acceptance criteria:**
  - ☐ All controllers disposed in `dispose()`.
  - ☐ `mounted` checked before `setState` after awaits.
  - ☐ Gallery loads exactly once.
  - ☐ Captured images disposed.
- **Verification:** RUNBOOK §3.7 "Product honesty, cleanup, and lifecycle" — repeatedly open/close affected views under a memory profile and confirm no growth or lifecycle exceptions.
- **Depends-on:** LL-014 removes `generated_image_viewer.dart` — if that lands first, its controller leak is moot; otherwise fix in place.

### LL-016 — Single tap draws nothing

- **Priority · Milestone · Effort:** P2 · M3 · S
- **Area:** Canvas UX.
- **Problem:** Gestures are pan-only, so a single tap produces no mark and dots are impossible with smooth brushes.
- **Impact:** A natural drawing action (dot / tap) does nothing — surprising and limiting. Quality-of-life gap in the core canvas.
- **Evidence:** `lib/presentation/features/scribble/drawing_canvas.dart:37` — pan-only gesture handling.
- **Acceptance criteria:**
  - ☐ A single tap places a visible dot / short mark.
  - ☐ Consistent across brush styles.
- **Verification:** RUNBOOK §3.1 "Canvas / drawing" — tap once with each brush and confirm a visible mark; this interacts with LL-001's short-stroke rendering rule.
- **Depends-on:** LL-001 (painter must render a single-point/dot stroke for a tap to be visible).

### LL-019b — Widget & integration tests (deferred slice of LL-019)

- **Priority · Milestone · Effort:** P2 · M3 · L
- **Area:** Testing.
- **Problem:** The M2 test slice (LL-019) covers unit/persistence/repository paths only. Widget-level coverage of the two top-level pages plus the embedded queue/generation flow, and end-to-end queue recovery, are deferred.
- **Impact:** UI regressions and queue-recovery regressions can still ship unnoticed after the M2 slice. This is the medium-term completion of the testing effort.
- **Evidence:** No widget or integration tests exist under `test/` (or an `integration_test/` dir); `ScribblePage`, `GalleryPage`, the queue overlay/widgets, and restart recovery are unexercised.
- **Acceptance criteria:**
  - ☐ Widget tests for `ScribblePage`, `GalleryPage`, and the queue/generation overlay/widget flow.
  - ☐ An integration test for **restart / queue recovery** (submit → kill → relaunch → resume, per LL-004).
- **Verification:** RUNBOOK §3.8 "Test coverage" — `flutter test` and the configured integration-test target are green; the recovery test fails against pre-LL-004 behavior and passes after.
- **Depends-on:** LL-019 (the M2 unit slice) and LL-004 (the recovery behavior under test).

---

## How this backlog is maintained

- **IDs are permanent.** Never renumber, merge, reuse, or delete an `LL-###`. Titles may be clarified during this pre-baseline review; after the baseline, rename deliberately and update all references. If work is dropped, keep the definition and mark it **Won't do** only in [PROGRESS.md](PROGRESS.md).
- **Live status lives only in [PROGRESS.md](PROGRESS.md).** Do not add status columns, checkboxes, or mirrored state to this file.
- **Priorities/milestones are stable.** Re-prioritizing is a deliberate edit, noted in the PROGRESS Decisions log (ADR-lite), not a silent change.
- **New work gets the next free `LL-###`** (highest existing is LL-021; `LL-019b` is a named sub-slice of LL-019, not a new number). Add it to the summary table and to the correct priority section with the full field set.
- **Execution discipline lives in [RUNBOOK.md](RUNBOOK.md); the "why/how it's built" lives in [ARCHITECTURE.md](ARCHITECTURE.md); setup in [DEVELOPMENT.md](DEVELOPMENT.md).** This doc is only *what to do and why*.
- **Gotcha to remember:** the docs index is `docs/README.md`, **never `docs/INDEX.md`** — `.gitignore` contains a bare `INDEX.md` line that would silently exclude it at any depth.
