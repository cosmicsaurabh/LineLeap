# DEVELOPMENT

Developer onboarding for **LineLeap**: how to install the toolchain, do a first run, run the everyday CI-parity commands, find your way around `lib/`, regenerate Hive code, and unblock common setup problems.

**Last updated: 2026-07-30**

## How to use this doc

- This is the **setup & run** doc. If you have been away for 3 weeks, start here to get a working build, then move to the tracker.
- For *what to work on*, see [BACKLOG.md](BACKLOG.md) (canonical issue registry, `LL-###`) and [PROGRESS.md](PROGRESS.md) (current focus + session log).
- For *how the system is built*, see [ARCHITECTURE.md](ARCHITECTURE.md).
- For *how to make a change safely* (branch → gates → verify → PR → release), see [RUNBOOK.md](RUNBOOK.md).
- Navigation across all docs: [README.md](README.md).
- Deep dive on the flagship subsystem: [AI_QUEUE_CASE_STUDY.md](AI_QUEUE_CASE_STUDY.md).

> **Doc-index gotcha:** the repo `.gitignore` contains a bare line `INDEX.md` (`.gitignore:54`), which git-ignores **any** file named `INDEX.md` at any depth. The documentation index is therefore `docs/README.md`, never `docs/INDEX.md`. Do not rename it.

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
| Size | ~7,316 lines `lib`, ~1,288 lines `test`; `flutter analyze` → 0 issues |

Only Stable Horde is wired. Abandoned Replicate and Google Vertex stubs are not part of the source tree.

---

## 2. Prerequisites

| Tool | Required version | Notes |
|---|---|---|
| Flutter | **3.44.1** (channel `stable`) | Framework revision `924134a44c`. Verify with `flutter --version`. |
| Dart SDK | **3.12.1** | Bundled with Flutter 3.44.1. The broader package constraint remains `sdk: ^3.7.0` in `pubspec.yaml`. |
| Android SDK + JDK 17 + one emulator or physical device | current / 17 | For `flutter run` / APK builds. minSdk/targetSdk/compileSdk float from the Flutter toolchain (not pinned); NDK `28.2.13676358`; app bytecode target remains Java 11. |
| Xcode + CocoaPods | current | Only if you build/run the iOS target. |
| `flutter` on `PATH` | — | All commands below assume macOS/zsh with `flutter` resolvable. |

Confirm the environment before anything else:

```
flutter --version        # expect Flutter 3.44.1 stable / Dart 3.12.1
flutter doctor           # resolve any red X for the platform you target
```

> CI pins Flutter **3.44.1** explicitly in `.github/workflows/flutter_ci.yml`. Treat the local and CI pins as one compatibility baseline; follow the intentional upgrade procedure in §4 rather than running `flutter upgrade` in isolation.

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
- **No secrets, production keystore, or API key are needed** for debug run, tests, or CI. The app talks to Stable Horde with the public anonymous key by default (see §7). CI creates a one-job throwaway signing key only for its non-publishable release smoke; production release signing still uses local secret files — see §8.

---

## 4. Everyday commands / CI-parity quality gates

Use these local equivalents of the gates in `.github/workflows/flutter_ci.yml`, in order. GitHub Actions runs the quality job for every branch push, every pull request **targeting** `main`, and manual dispatches. A gated release smoke runs after quality on pull requests, direct pushes to `main`, and manual dispatches.

| Gate | Command | CI step? |
|---|---|---|
| Install deps | `flutter pub get` | ✅ |
| Format check (read-only; fails on diff) | `dart format --output=none --set-exit-if-changed lib test` | ✅ |
| Static analysis | `flutter analyze` | ✅ (baseline: `flutter_lints` only; expect 0 issues) |
| Tests + line coverage | `flutter test --coverage` | ✅; uploads `coverage/lcov.info` for 14 days |
| Debug APK build | `flutter build apk --debug` | ✅; uploads the APK for 14 days |
| Release AAB smoke | `flutter build appbundle --release` | ✅ on the gated events above; CI uses a throwaway key and never uploads this AAB |

Additional local commands (not in CI):

| Task | Command |
|---|---|
| Run app (debug) | `flutter run` |
| Regenerate Hive adapters | `dart run build_runner build --delete-conflicting-outputs` |
| Release APK | `flutter build apk --release` |
| Release AAB | `flutter build appbundle --release` |
| Run with a real Horde key | `flutter run --dart-define=AI_HORDE_API_KEY=<key>` |

**Order for a clean pre-push check:** `dart format --output=none --set-exit-if-changed lib test` → `flutter analyze` → `flutter test --coverage` → `flutter build apk --debug`. If format fails, run `dart format lib test` to auto-fix, review the resulting diff, then re-check. The generated `coverage/` directory is git-ignored.

CI is verification-only. It does not publish an app, use the production upload key, or retain its disposable release bundle. Production publishing remains the manual, protected process in §8 and [RUNBOOK.md](RUNBOOK.md).

### Intentional toolchain compatibility hold

The lockfile and CI intentionally hold this tested combination while two compatibility tracks remain:

| Component | Locked version | Compatibility state |
|---|---:|---|
| Flutter / Dart | 3.44.1 / 3.12.1 | Built-in Kotlin cannot be enabled yet; Flutter's migration guide requires Flutter 3.47 or later. |
| Android Gradle Plugin / Gradle / Kotlin plugin | 8.11.1 / 8.14 / 2.2.20 | The app remains on the legacy Kotlin Gradle Plugin with `android.builtInKotlin=false` and `android.newDsl=false`. |
| `image_gallery_saver_plus` | 4.0.1 | Lacks iOS Swift Package Manager support and applies the legacy Kotlin Gradle Plugin. |
| `share_plus` | 11.1.0 | Applies the legacy Kotlin Gradle Plugin. |

Audited upgrade candidates on 2026-07-30 are `image_gallery_saver_plus` 5.1.1 (adds Swift Package Manager support but still applies KGP) and `share_plus` 13.3.0 (Built-in Kotlin support began in 13.2.0; requires AGP 8.12.1+). Both raise the iOS deployment floor from 12 to 13, so adopting them is a deliberate platform-support decision rather than an automatic dependency refresh.

Before changing the Flutter pin:

1. Re-check the current plugin changelogs and platform requirements; do not rely indefinitely on the candidate versions above.
2. Decide whether dropping iOS 12 support is acceptable, then upgrade the plugins and all iOS deployment-target declarations together; raise the `pubspec.yaml` Dart floor from `^3.7.0` to at least `^3.10.0` for `share_plus` 13.3.0.
3. Move the app to Flutter 3.47+ and the required AGP only after the plugin set is compatible.
4. Follow Flutter's [Built-in Kotlin migration guide](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers): remove the app KGP/legacy `kotlinOptions`, enable Built-in Kotlin, and verify that no plugin still applies KGP.
5. Update the local requirement, CI pin, lockfile, and this table in the same PR; run format, analyze, coverage tests, debug APK, release AAB, an iOS build, and Android/iOS save/share device smokes.

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
| `test/` | Eight focused test files covering Horde parsing, queue processing, drawing/history, capture pixels, theme restore, tool honesty, and generation/gallery feedback. CI now publishes line coverage; repository/Hive and broader widget/integration gaps remain LL-019/LL-019b. |

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

Debug builds and tests need **none** of the following. These files exist only to sign publishable release artifacts and are **git-ignored and not in the repo** (verified never committed to git history):

| File | Purpose | Keys |
|---|---|---|
| `android/key.properties` | Signing config read by `android/app/build.gradle.kts:11` | `storePassword`, `keyPassword`, `keyAlias`, `storeFile` |
| `android/upload-keystore.jks` | The upload keystore referenced by `storeFile` | — |

Rules:
- **Never commit** `key.properties` or `*.jks`. Both are git-ignored; keep them out of history. See secret-handling guardrails in [RUNBOOK.md](RUNBOOK.md).
- Use a relative keystore path such as `storeFile=upload-keystore.jks`; Gradle resolves it from `android/`, so the ignored config is portable across checkouts. Release builds validate the file and all four required properties before compilation.
- You need the production files for `flutter build apk --release` / `flutter build appbundle --release`. Without them, a publishable release build fails with a focused signing error while debug/test work remains unaffected.
- CI is the exception: its gated release smoke creates a one-job throwaway keystore and ignored `key.properties`, exercises the normal release signing path, deletes both, and does **not** upload the bundle. It proves release compilation/signing only; that AAB is never a store artifact.
- R8/minification and resource shrinking remain explicitly disabled. The old broad `proguard-rules.pro` was deleted because it was dead configuration and kept nearly every app/plugin class; enabling shrink safely requires a separate release-device save/share smoke first.
- Before upgrading Flutter or publishing a new release, follow the compatibility procedure in §4.

---

## 9. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Build errors mentioning `*.g.dart`, missing adapter, or "conflicting outputs" | Generated Hive code stale after a model edit / fresh clone | `dart run build_runner build --delete-conflicting-outputs` (see §6) |
| CI (or local) format gate fails | Unformatted code in `lib`/`test` | Auto-fix: `dart format lib test`, review the diff, then re-run `dart format --output=none --set-exit-if-changed lib test` |
| iOS build fails on Pods / missing pods | CocoaPods not installed or out of date | From the iOS folder: `pod install --repo-update` (ensure Xcode + CocoaPods installed; then `flutter run`) |
| `flutter run` reports no device / emulator not found | No emulator running or no device connected | `flutter devices`; launch an Android emulator (or `flutter emulators --launch <id>`) or plug in a device, then re-run |
| Passes locally, differs in CI | Local Flutter or the lockfile differs from the pinned CI baseline | Align local to **Flutter 3.44.1 stable**, restore `pubspec.lock`, and verify with `flutter --version` |
| Generation never completes / stuck in queue | Horde anonymous queue is slow, or network issue | Expected with the default anonymous key; try a real key via `--dart-define` (§7). Behavior detail in [AI_QUEUE_CASE_STUDY.md](AI_QUEUE_CASE_STUDY.md) |
| Release build fails signing | `android/key.properties` is absent/incomplete or `storeFile` points outside the current checkout | Keep the ignored keystore under `android/`, set `storeFile=upload-keystore.jks`, and retry. Never commit either file (§8). |

---

## Related docs

- [README.md](README.md) — documentation index & navigation
- [ARCHITECTURE.md](ARCHITECTURE.md) — how the system is built (layers, queue pipeline, data model)
- [BACKLOG.md](BACKLOG.md) — prioritized `LL-###` issue registry (known issues)
- [PROGRESS.md](PROGRESS.md) — current focus & session log
- [RUNBOOK.md](RUNBOOK.md) — the change workflow, guardrails, release/rollback
- [AI_QUEUE_CASE_STUDY.md](AI_QUEUE_CASE_STUDY.md) — deep dive on the generation queue
