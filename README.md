# Flipcard - Smart Flashcard Learning App

![Flipcard Banner](assets/images/logo.png)

*A modern learning companion for effective memorization* 

## Features ✨

- 📚 **Deck Organization** - Create nested decks with custom categories
- 🔄 **Import/Export** - Share decks via JSON with media support
- 🧠 **Adaptive Quizzing** - Built-in speech repetition algorithm
- 📊 **Progress Analytics** - Visual statistics of your learning progress
- 🌙 **Dark Mode** - Automatic theme switching based on system preferences

## Screenshots 📱

![Recorder](screenshots/screenrecord.gif)

## Installation Guide ⚙️ 

### Requirements  
- Flutter 3.32.4+ (Dart 3.8.1+)
- Android SDK 33+
- Supabase URL & ANON KEY
- Run Supabase SQL Editor [generated.sql](./generated.sql)

### Development Quick Start  
```bash
git clone https://github.com/fiqryx/flipcard.git

cd flipcard && flutter pub get
```

```bash
flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
```

📥 <a href="./outputs/app-release.apk" download="Flipcard.apk">Download Latest APK</a>