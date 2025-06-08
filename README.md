# ✏️ Flutter Scribble with Generative AI

A modern Flutter app that lets you **draw sketches** and generate AI-powered images from them.  
Built with **Clean Architecture**, supports **light/dark/system themes**, and is ready for production use.

---

## 🚀 Features

- **Scribble Canvas:** Draw with your finger or stylus.
- **Undo/Redo/Clear:** Full drawing history support.
- **Color Picker:** Choose your pen color.
- **Prompt Input:** Add a text prompt for AI image generation.
- **AI Image Generation:** Uses [Stable Horde](https://stablehorde.net/) for sketch-to-image.
- **Theme Selector:** Switch between light, dark, and system themes.
- **Clean Architecture:** Domain, data, and presentation layers for maintainability and testability.

---

## 🏛️ Clean Architecture Overview

```
lib/
  core/           # Theme and utilities
  data/           # API and repository implementations
  domain/         # Business logic, use cases, abstract repositories
  presentation/   # UI, widgets, state management
```

- **Domain:** Business logic, use cases, abstract contracts (no Flutter or API dependencies)
- **Data:** Implements domain contracts, talks to APIs, handles persistence
- **Presentation:** UI, widgets, state management (Provider)
- **Core:** App-wide utilities and theme definitions

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

---

## 📦 Dependencies

- [provider](https://pub.dev/packages/provider)
- [shared_preferences](https://pub.dev/packages/shared_preferences)
- [flutter_colorpicker](https://pub.dev/packages/flutter_colorpicker)
- [adaptive_dialog](https://pub.dev/packages/adaptive_dialog)
- [http](https://pub.dev/packages/http)

---

## 🤓 Contributing

Pull requests are welcome! Please open an issue first to discuss what you would like to change.

---

## 🙏 Credits

- [Stable Horde](https://stablehorde.net/) for the AI backend
- Flutter and the open-source community

---

**Made with ❤️ by [cosmicsaurabh](https://github.com/cosmicsaurabh)**
