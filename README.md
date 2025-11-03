# Powered by OBSDIV
Powered by OBSDIV is a futuristic, neon-inspired AI image generator built with Flutter. It connects directly to the OpenAI Images API so you can transform text prompts into shareable artwork on Android and iOS.

## Features

- 🔮 Animated splash and guided onboarding experience.
- 🧠 Prompt-to-image pipeline powered by the OpenAI Images `gpt-image-1` model.
- 🖼️ Immersive result view with zoom, save to gallery, and share actions.
- 🗂️ Persistent creation history stored locally.
- 🎨 Theme controls with custom neon accent colors and profile naming.
- 🧱 Fully custom art direction with handcrafted logos, icons, mockups, and gradient backgrounds.

## Getting Started

1. **Install Flutter** (3.22 or newer is recommended).
2. **Clone this repository** and install dependencies:

   ```bash
   flutter pub get
   ```

3. **Configure your OpenAI API key** for image generation:

    - Copy `.env.example` to `.env` and fill in `OPENAI_API_KEY`.
    - Alternatively, pass the key at build time:

      ```bash
      flutter run --dart-define=OPENAI_API_KEY=sk-...your-key...
      ```

4. **Run the app** on a device or emulator:

   ```bash
   flutter run
   ```

   Grant gallery permissions when prompted so the app can save generated artwork.

## Notes

- Image generation relies on the OpenAI Images endpoint. Ensure the API key you provide has access to the `gpt-image-1` model.
- The design assets live under `lib/assets/` and are pre-configured in `pubspec.yaml`.
- History is stored locally via `SharedPreferences`. Clearing app data resets the timeline.

Enjoy crafting neon-grade visuals with Powered by OBSDIV!
