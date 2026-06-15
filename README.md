# LineLeap

LineLeap is a Flutter sketch-to-image app. Users draw a rough idea, add a prompt, queue AI generation jobs, and save generated results into a local gallery.

## Features

- Touch/stylus drawing canvas with brush styles, color selection, undo, redo, clear, and mirror modes.
- AI sketch-to-image generation through Stable Horde.
- Persistent generation queue with queued, submitting, generating, completed, failed, retry, view, save, and delete states.
- Local-first gallery backed by Hive metadata and image files in app storage.
- Light, dark, and system theme persistence.
- In-app content reporting flow for generated images.

## Architecture

```text
lib/
  core/           shared services, config, utilities, dependency injection
  data/           API clients, datasources, repository implementations, Hive models
  domain/         entities, repository contracts, use cases, generation services
  presentation/   widgets, pages, dialogs, providers, UI state
```

The project uses Provider for UI state, GetIt for dependency injection, Hive for local metadata, and use cases around queue, gallery, theme, and generation workflows.

## Quality Gates

Run these before opening a pull request:

```sh
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

The repository includes a GitHub Actions workflow at `.github/workflows/flutter_ci.yml` that runs the same checks on pushes and pull requests to `main`.

## Getting Started

```sh
flutter pub get
flutter run
```

Image generation requires internet access because requests are sent to Stable Horde. Drawing, queue metadata, and gallery browsing are local-first.

## Testing

Current tests cover:

- Drawing history behavior, including undo, redo, and mirror strokes.
- Queue processing from queued request to completed generated output with mocked generation service.

## Project Notes

- Android package: `com.lineleapp`
- macOS bundle id: `com.lineleapp`
- AI provider: Stable Horde anonymous API by default
- Local persistence: Hive plus app document storage

Before publishing, capture fresh screenshots from release builds and add them under `screenshots/`.
