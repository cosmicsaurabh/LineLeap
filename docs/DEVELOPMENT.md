# DEVELOPMENT

Developer onboarding for **LineLeap**: how to install the toolchain, do a first run, run the everyday CI-parity commands, find your way around `lib/`, regenerate Hive code, and unblock common setup problems.

**Last updated: 2026-07-29**

## How to use this doc

- This is the **setup & run** doc. If you have been away for 3 weeks, start here to get a working build, then move to the tracker.
- For *what to work on*, see [BACKLOG.md](BACKLOG.md) (canonical issue registry, `LL-###`) and [PROGRESS.md](PROGRESS.md) (current focus + session log).
- For *how the system is built*, see [ARCHITECTURE.md](ARCHITECTURE.md).
- For *how to make a change safely* (branch → gates → verify → PR → release), see [RUNBOOK.md](RUNBOOK.md).
- Navigation across all docs: [README.md](README.md).
- Deep dive on the flagship subsystem: [AI_QUEUE_CASE_STUDY.md](AI_QUEUE_CASE_STUDY.md).

> **Doc-index gotcha:** the repo `.gitignore` contains a bare line `INDEX.md` (`.gitignore:53`), which git-ignores **any** file named `INDEX.md` at any depth. The documentation index is therefore `docs/README.md`, never `docs/INDEX.md`. Do not rename it.

---

## 1. What you are building

| | |
|---|---|
| App | **LineLeap** — Flutter sketch-to-image app |
| Flow | Draw on canvas → enter prompt → **queued img2img** generation via the **Stable Horde** public anonymous API → completed result remains in the queue until the user promotes it to the **local Hive gallery** |
| Backend | **None.** No custom server, no auth, no accounts. Local-first. |
| pubspec name | `lineleap` |
| Bundle id (Android/macOS) | `com.lineleapp` |
| Version | `1.0.1+14` |
| Size | ~7,415 lines `lib`, ~1,232 lines `test`; `flutter analyze` → 0 issues |

Only Stable Horde is wired. Abandoned Replicate and Google Vertex stubs are not part of the source tree.

---

## 2. Prerequisites

| Tool | Required version | Notes |
|---|---|---|
| Flutter | **3.44.1** (channel `stable`) | Framework revision `924134a44c`. Verify with `flutter --version`. |
| Dart SDK | **3.12.1** | Bundled with Flutter 3.44.1. The broader package constraint remains `sdk: ^3.7.0` in `pubspec.yaml`. |
| Android SDK + one emulator or physical device | current | For `flutter run` / APK builds. minSdk/targetSdk/compileSdk float from the Flutter toolchain (not pinned); NDK `28.2.13676358`; Java 11. |
| Xcode + CocoaPods | current | Only if you build/run the iOS target. |
| `flutter` on `PATH` | — | All commands below assume macOS/zsh with `flutter` resolvable. |

Confirm the environment before anything else:

```
flutter --version        # expect Flutter 3.44.1 stable / Dart 3.12.1
flutter doctor           # resolve any red X for the platform you target
```

> CI does **not** pin the Flutter version (it uses `channel: stable`, unpinned — see `.github/workflows/flutter_ci.yml`). Local drift from 3.44.1 can pass locally yet behave differently in CI. Tracked as an unpinned-toolchain gap; see [BACKLOG.md](BACKLOG.md).

---

## 3. First-time setup

Run in order from the repo root:

| # | Step | Command |
|---|---|---|
| 1 | Clone | `git clone <repo-url> && cd flutter_scribble` |
| 2 | Install deps | `flutter pub get` |
| 3 | Generate Hive adapters (codegen) | `dart run build_runner build --delete-conflicting-outputs` |
| 4 | Launch on an emulator/device | `flutter run` |

- Step 3 produces `lib/data/models/scribble_transformation_hive_model.g.dart` (the generated `part` of `scribble_transformation_hive_model.dart`). It is the only `*.g.dart` in the tree. See §6.
- **No secrets, keystore, or API key are needed** for debug run, tests, or CI. The app talks to Stable Horde with the public anonymous key by default (see §7). Release signing is the only thing that needs secret files — see §8.

---

## 4. Everyday commands / CI-parity quality gates

Use these local equivalents of the gates in `.github/workflows/flutter_ci.yml`, in order. The local format check adds `--output=none` so validation cannot rewrite source. GitHub Actions runs for direct pushes to `main` and for pull requests **targeting** `main`; a direct push to `feature`, `bug-fixes`, or another non-main branch does not run CI until that branch has an open PR targeting `main`.

| Gate | Command | CI step? |
|---|---|---|
| Install deps | `flutter pub get` | ✅ |
| Format check (read-only; fails on diff) | `dart format --output=none --set-exit-if-changed lib test` | ✅ (same formatting gate, without local writes) |
| Static analysis | `flutter analyze` | ✅ (baseline: `flutter_lints` only; expect 0 issues) |
| Unit tests | `flutter test` | ✅ |
| Debug APK build | `flutter build apk --debug` | ✅ (CI builds debug only) |

Additional local commands (not in CI):

| Task | Command |
|---|---|
| Run app (debug) | `flutter run` |
| Regenerate Hive adapters | `dart run build_runner build --delete-conflicting-outputs` |
| Release APK | `flutter build apk --release` |
| Release AAB | `flutter build appbundle --release` |
| Run with a real Horde key | `flutter run --dart-define=AI_HORDE_API_KEY=<key>` |

**Order for a clean pre-push check:** `dart format --output=none --set-exit-if-changed lib test` → `flutter analyze` → `flutter test`. If format fails, run `dart format lib test` to auto-fix, review the resulting diff, then re-check.

> Known CI gaps (tracked in [BACKLOG.md](BACKLOG.md)): unpinned Flutter version; no CI for direct pushes to non-main branches without a PR targeting `main`; debug-only build; no artifact upload; no coverage.

Flutter 3.44.1 also reports two forward-compatibility warnings tracked under **LL-018**:

- `image_gallery_saver_plus` does not yet support Swift Package Manager for iOS; Flutter warns this will become an error in a future release.
- The Android app and some plugins still apply the Kotlin Gradle Plugin; Flutter warns that a future release will require migration to Built-in Kotlin. Do not upgrade Flutter until the app and affected plugins have a verified migration path.

---

## 5. Project layout tour

Clean-architecture layering. Dependency rule: **presentation → domain ← data** — `domain` is the seam and depends on neither; `data` implements the `domain` interfaces and `presentation` consumes them. (For the full dependency rule, known layering violations, and the queue pipeline, read [ARCHITECTURE.md](ARCHITECTURE.md); this is only a where-things-live map.)

| Path | Responsibility |
|---|---|
| `lib/main.dart` | Bootstrap: `WidgetsFlutterBinding`, `Hive.initFlutter`, register `ScribbleTransformationHiveAdapter` (typeId 0), `initDependencies()`, then `MultiProvider` → `MaterialApp` home `NavBar`. Global `FlutterError.onError` + `ErrorApp` fallback. |
| `lib/core/` | Cross-cutting: `di/injection_container.dart` (GetIt composition root), `config/` (brush, tool, mirror-mode constants), `service/`, `utils/`. |
| `lib/data/` | Outer layer: `remote/` (`ai_horde_api.dart` — the only live API), `datasources/`, `repositories/` (impls), `models/` (Hive models + generated `.g.dart`), `services/`. |
| `lib/domain/` | Business core: `entities/`, `repositories/` (interfaces), `usecases/`, `services/`. |
| `lib/presentation/` | UI: `common/` (providers, shared widgets), `features/` (screens). Providers include `EnhancedScribbleNotifier`, `GenerationProvider`, `GalleryNotifier`, `QueueStatusProvider`, `ThemeNotifier`. |
| `lib/theme/` | App theming. |
| `test/` | `ai_horde_api_test`, `scribble_notifier_test`, `process_generation_queue_usecase_test`. ~10–15% effective logic coverage; 0% UI/persistence/DI. |

Config anchors worth knowing:
- Horde API key default: `lib/data/remote/ai_horde_api.dart:9`.
- Hive bootstrap / adapter registration: `lib/main.dart:28`–`29`.

---

## 6. Hive codegen (when to re-run `build_runner`)

Hive adapters are generated code. The one generated file is `lib/data/models/scribble_transformation_hive_model.g.dart` (a `part` of `scribble_transformation_hive_model.dart`).

**Re-run codegen whenever you change a Hive-annotated model** (add/remove/reorder `@HiveField`s, change types, add a new `@HiveType`):

```
dart run build_runner build --delete-conflicting-outputs
```

- Commit the regenerated `.g.dart` alongside your model change.
- If a build fails with "conflicting outputs" or stale-generated errors, the `--delete-conflicting-outputs` flag above resolves it.
- **Data-safety caution:** the `generation_queue` box stores `status` as an enum **index**, and there is no schema versioning or migration anywhere. Reordering that enum (or changing stored field order) can corrupt persisted data. Do not reorder Hive fields/enums casually — see the persistence constraints in [ARCHITECTURE.md](ARCHITECTURE.md) and the related items in [BACKLOG.md](BACKLOG.md).

---

## 7. Horde API key override (`--dart-define`)

- Default key is the **Stable Horde public anonymous key** `'0000000000'`, wired via `String.fromEnvironment('AI_HORDE_API_KEY', defaultValue: '0000000000')` at `lib/data/remote/ai_horde_api.dart:9`.
- The default works out of the box (anonymous, low priority in the Horde queue). No key setup is required to develop or test.
- To use your own registered key (higher priority):

```
flutter run --dart-define=AI_HORDE_API_KEY=<your-key>
```

- This is a compile-time define, not a file. There is **no `.env`** to create.

---

## 8. Release signing (release builds only)

Debug builds, `flutter test`, and CI need **none** of the following. These files exist only to sign release artifacts and are **git-ignored and not in the repo** (verified never committed to git history):

| File | Purpose | Keys |
|---|---|---|
| `android/key.properties` | Signing config read by `android/app/build.gradle.kts:12` | `storePassword`, `keyPassword`, `keyAlias`, `storeFile` |
| `android/upload-keystore.jks` | The upload keystore referenced by `storeFile` | — |

Rules:
- **Never commit** `key.properties` or `*.jks`. Both are git-ignored; keep them out of history. See secret-handling guardrails in [RUNBOOK.md](RUNBOOK.md).
- You only need them for `flutter build apk --release` / `flutter build appbundle --release`. Without them, release builds will fail signing but everything else works.
- Note: Android release currently has **R8/minify and resource shrinking disabled** (`isMinifyEnabled=false`, `isShrinkResources=false` at `android/app/build.gradle.kts:53`–`54`), so `android/app/proguard-rules.pro` is presently dead config. Tracked in [BACKLOG.md](BACKLOG.md).
- Before upgrading Flutter or publishing a new release, resolve or explicitly document the Swift Package Manager and Built-in Kotlin warnings listed in §4 under **LL-018**.

---

## 9. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Build errors mentioning `*.g.dart`, missing adapter, or "conflicting outputs" | Generated Hive code stale after a model edit / fresh clone | `dart run build_runner build --delete-conflicting-outputs` (see §6) |
| CI (or local) format gate fails | Unformatted code in `lib`/`test` | Auto-fix: `dart format lib test`, review the diff, then re-run `dart format --output=none --set-exit-if-changed lib test` |
| iOS build fails on Pods / missing pods | CocoaPods not installed or out of date | From the iOS folder: `pod install --repo-update` (ensure Xcode + CocoaPods installed; then `flutter run`) |
| `flutter run` reports no device / emulator not found | No emulator running or no device connected | `flutter devices`; launch an Android emulator (or `flutter emulators --launch <id>`) or plug in a device, then re-run |
| Passes locally, differs in CI | CI Flutter is unpinned (`channel: stable`), local may drift from 3.44.1 | Align local to **3.44.1 stable**; verify with `flutter --version` |
| Generation never completes / stuck in queue | Horde anonymous queue is slow, or network issue | Expected with the default anonymous key; try a real key via `--dart-define` (§7). Behavior detail in [AI_QUEUE_CASE_STUDY.md](AI_QUEUE_CASE_STUDY.md) |
| Release build fails signing | `android/key.properties` / `upload-keystore.jks` absent | Provide them locally (never commit). Not needed for debug/test/CI (§8) |

---

## Related docs

- [README.md](README.md) — documentation index & navigation
- [ARCHITECTURE.md](ARCHITECTURE.md) — how the system is built (layers, queue pipeline, data model)
- [BACKLOG.md](BACKLOG.md) — prioritized `LL-###` issue registry (known issues)
- [PROGRESS.md](PROGRESS.md) — current focus & session log
- [RUNBOOK.md](RUNBOOK.md) — the change workflow, guardrails, release/rollback
- [AI_QUEUE_CASE_STUDY.md](AI_QUEUE_CASE_STUDY.md) — deep dive on the generation queue
