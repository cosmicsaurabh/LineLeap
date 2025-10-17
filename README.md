# ✏️ Flutter Scribble with Generative AI

A modern Flutter app to **draw sketches** and generate AI-powered images.  
Built with **Clean Architecture**, supports **light/dark/system themes**, and features a persistent gallery using Hive and device storage.

---

## 🚀 Features

- **Scribble Canvas:** Draw with your finger or stylus.
- **Undo/Redo/Clear:** Full drawing history support.
- **Color Picker:** Choose your pen color.
- **Prompt Input:** Add a text prompt for AI image generation.
- **AI Image Generation:** Uses [Stable Horde](https://stablehorde.net/) for sketch-to-image.
- **Generation Queue:** Enqueue and track multiple AI generation requests with live status indicators (queued, submitting, generating, completed, failed) and controls to retry, view, download, or delete.
- **Gallery:** View all your generated images, loaded from file paths.
- **Theme Selector:** Switch between light, dark, and system themes.
- **Clean Architecture:** Domain, data, and presentation layers for maintainability and testability.

---

## 🏛️ Clean Architecture Overview

```
lib/
  core/           # Theme, services, and utilities
  data/           # API and repository implementations, models
  domain/         # Business logic, use cases, abstract repositories, entities
  presentation/   # UI, widgets, notifiers
```

- **Domain:** Business logic, use cases, abstract contracts (no Flutter or API dependencies)
- **Data:** Implements domain contracts, talks to APIs, handles persistence (Hive, file storage)
- **Presentation:** UI, widgets, state management (Provider)
- **Core:** App-wide utilities, theme, and services

---

## 🧰 Tech Highlights

- **Clean Architecture** with strict separation of domain, data, presentation and core layers
- **Dependency Injection** via GetIt (`injection_container.dart`)
- **State Management** using Provider and ChangeNotifier (`GenerationProvider`, `GalleryNotifier`, `QueueStatusProvider`)
- **Real-time Queue Processing** with polling, streams (`WatchGenerationRequestUseCase`) and auto-retry logic
- **In-Memory Queue** backed by `GenerationQueueNotifier` for ultra-fast UI updates
- **Haptic Feedback & Animations** on button taps and card swipes (`flutter_card_swiper`)
- **Offline-First Storage**: Hive for metadata + file system for images via `ImageDeviceInteractionService`
- **Modular, Testable Code** – each use-case and repository easily mocked for unit/integration tests
- **CI-Ready** – add GitHub Actions for linting, formatting, analysis and test coverage

---

## 🗓️ Upcoming features
- **Multimodal Support** Coming soon.


---

## 🖼️ Screenshots

| Light Mode                      | Dark Mode                     |
| ------------------------------- | ----------------------------- |
| ![Light](screenshots/light.png) | ![Dark](screenshots/dark.png) |

---

## 🛠️ Getting Started

1. **Clone the repo:**

   ```sh
   git clone https://github.com/cosmicsaurabh/scribble-with-generative-ai.git
   cd scribble-with-generative-ai
   ```

2. **Install dependencies:**

   ```sh
   flutter pub get
   ```

3. **Run the app:**
   ```sh
   flutter run
   ```

---

## ⚙️ Configuration

- **AI API:** Uses Stable Horde (no API key required for anonymous use, but you can add your own for higher limits).
- **Theme Persistence:** Theme mode is saved using `shared_preferences`.
- **Image Storage:** Generated images are saved as files in the app's documents directory. Only the file path and metadata are stored in Hive for efficient gallery loading.

---

## 📦 Dependencies

- [provider](https://pub.dev/packages/provider)
- [hive](https://pub.dev/packages/hive)
- [hive_flutter](https://pub.dev/packages/hive_flutter)
- [shared_preferences](https://pub.dev/packages/shared_preferences)
- [flutter_colorpicker](https://pub.dev/packages/flutter_colorpicker)
- [adaptive_dialog](https://pub.dev/packages/adaptive_dialog)
- [http](https://pub.dev/packages/http)
- [flutter_card_swiper](https://pub.dev/packages/flutter_card_swiper)

---

## 🤓 Contributing

Pull requests are welcome! Please open an issue first to discuss what you would like to change.

---

## 🙏 Credits

- [Stable Horde](https://stablehorde.net/) for the AI backend
- Flutter and the open-source community

---

**Made with ❤️ by [cosmicsaurabh](https://github.com/cosmicsaurabh)**
