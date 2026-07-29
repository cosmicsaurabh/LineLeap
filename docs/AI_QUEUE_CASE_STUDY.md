# AI Queue Architecture Case Study

**Last updated: 2026-07-29**

This document describes the queue that exists today and the contracts required to evolve it safely. It is not evidence that remote work survives restart: queue **records** persist, but active Horde jobs are currently submitted again after recovery.

## Current pipeline

1. `GenerationProvider` captures the `RepaintBoundary` and saves a scribble PNG in the application documents directory.
2. `EnqueueGenerationRequestUseCase` creates a UUID-backed `GenerationRequest` and the repository writes it to the in-memory notifier and the raw Hive `generation_queue` box.
3. `ProcessGenerationQueueUseCase` uses `_isProcessing` to select and process one `queued` request at a time.
4. `HordeGenerationServiceImpl.generateFromPrompt` currently performs the complete remote lifecycle in one call: read scribble → submit → poll → download → save result.
5. Immediately after submit returns a Horde job ID, the service invokes `onProgress(1)`. The use case treats that post-submit notification as the transition to `polling`; it occurs **before** the first status request and is not an awaited transactional boundary.
6. Later API progress contains `queue_position` and `wait_time`, but the service reduces it to an integer percent and the use case does not retain the value. Position and ETA never reach the UI.
7. The use case persists `completed`, `failed`, or `cancelled`, then schedules the next queued item.
8. On explicit user action, gallery promotion writes a Hive row that references the **same** scribble and generated files, then removes the queue record. No file is copied or transferred.

## What persistence currently guarantees

| State | Current behavior after restart |
|---|---|
| `queued` | Loaded into memory and eligible for processing. |
| `submitting` / `polling` | Reset to `queued`. Because the Horde job ID was not persisted by the service flow, processing submits a new remote job rather than resuming the old one. |
| `completed` / `failed` / `cancelled` | Restored unchanged and retained indefinitely until explicitly removed. |

The queue is represented twice: an in-memory `GenerationQueueNotifier` drives streams/UI and a raw Hive box survives restart. Enqueue, update, and remove write both sequentially; there is no cross-store transaction, so a failed second write can leave memory and disk inconsistent.

Files are a separate persistence concern. Queue and gallery records can reference the same PNGs in the app documents directory. A record's lifecycle therefore does not, by itself, prove that its files are safe to delete.

## Current useful properties

- Queue processing depends on `GenerationQueueRepository` and `HordeGenerationService` interfaces rather than widgets.
- The `_isProcessing` guard prevents two queue items from being intentionally processed at once.
- API parsing uses typed `HordeApiException` failures and defensive response decoding.
- `GenerationCancellationToken` is checked around network sends and in backoff delays.
- Tests cover successful processing, provider failure, retry, local cancellation-token propagation, submission parsing, progress parsing, and polling timeout.

These properties are useful, but they do not provide atomic state transitions, remote-job resumption, remote cancellation, background execution, or file ownership.

## Safe evolution contracts

### LL-004 — submit, persist, then poll or resume

- Split the provider contract into submit, poll/resume, download, and cancel operations, or expose an equivalent durable post-submit seam.
- Persist `generationId` as the first local operation after submit returns and before polling begins.
- Recovery rules must be explicit:
  - no `generationId` → a new submission may be made;
  - valid `generationId` → resume status polling without uploading the scribble again;
  - terminal/missing remote job → require an explicit new-submission transition and clear or replace the old ID.
- Local cancellation should call the Horde DELETE endpoint when a persisted ID exists, while retaining local token cancellation for in-flight requests.
- Replace the fixed attempt budget with a bounded wall-clock policy informed by `wait_time` and `queue_position`. The current backoff contributes about 5m50 of scheduled delay, but network latency and per-request timeouts make wall time longer; it is not a hard six-minute ceiling.

There remains a small crash window between receiving a server ID and persisting it. Keep that window minimal and document it; do not claim exactly-once remote submission unless the provider offers an idempotency mechanism.

### LL-005 — make file ownership explicit before pruning

- Define whether each scribble/result file is queue-owned, gallery-owned, or shared.
- Promotion must transfer ownership, copy into gallery-owned storage, or use reference counting. Removing the queue record after promotion must not delete files still referenced by the gallery.
- Preserve the scribble while a failed/cancelled item remains retryable.
- Apply a concrete retention policy to terminal queue records only after ownership is known.
- Make cleanup idempotent and reconcile interrupted cleanup on launch.

### LL-007 — centralize durable path resolution

- Persist paths relative to an application storage root, not an absolute container path.
- Route **all** reads, writes, deletes, `Image.file`, shares, downloads, and Horde input reads through one storage-path resolver or value object.
- Migrate both `gallery_history` and `generation_queue` records. The migration must be versioned or safely idempotent, tolerate missing files, and retain legacy-path read support until completion.

Changing only `ImageDeviceInteractionService.saveImageToDevice` is insufficient because several data and presentation classes currently construct `File(path)` directly.

### LL-009 — serialize or condition terminal transitions

A final re-read before writing `completed` is still a time-of-check/time-of-use race. Use one of these equivalent contracts:

- serialize cancellation, progress, and terminal transitions through one request-scoped executor; or
- add an atomic compare-and-set/versioned repository operation such as “write completed only if current status is still polling.”

Whichever contract is chosen must update memory and Hive consistently. An unawaited progress callback must not overwrite a newer terminal state.

### LL-010 — migrate identity and time as data, not display text

- Give every gallery record a stable ID and backfill it for existing rows.
- Set `GenerationRequest.createdAt` at enqueue and use a single domain timestamp meaning, preferably normalized to UTC.
- Define serialization and migrate existing epoch strings, missing values, and invalid values without changing existing Hive field numbers.
- Sort explicitly by parsed time plus stable ID; never rely on Hive iteration order.
- Keep transient display formatting out of persisted entities.

### LL-021 — carry progress; scope notification guarantees honestly

- Introduce a provider-neutral progress value in the domain/service contract and carry queue position and ETA through use case/state to the overlay.
- Decide whether progress is transient or persisted for restart; do not accidentally store display strings as queue data.
- A local completion notification is reliable only while the process is executing. If the OS suspends or terminates the app, the current Dart polling loop cannot guarantee completion or notification.
- Reliable completion while suspended/terminated requires a supported background-execution design, foreground service where appropriate, or a remote service that can send push notifications. Adding `flutter_local_notifications` alone is not that design.

## Verification focus

- Crash/relaunch immediately after submit and confirm whether the same Horde ID resumes.
- Race cancellation against final download/save and assert cancellation cannot be overwritten.
- Promote a completed item, remove/prune its queue record, and confirm both gallery images remain readable.
- Migrate legacy absolute paths, timestamps, and rows without stable IDs in temporary Hive boxes.
- Inject failure between memory and Hive writes and confirm reconciliation behavior.
- Verify progress transport separately from display formatting.
- Test notification behavior in foreground, background-while-running, OS-suspended, and terminated states; document which states are supported.
