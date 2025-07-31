# Flipcard - Smart Flashcard Learning App

![Flipcard Banner](assets/images/logo.png)

*A modern learning companion for effective memorization* 


### Get On
| [<img src="https://play.google.com/intl/en_us/badges/images/generic/en-play-badge.png" alt="Get it on Google Play" height="80">](#) | [<img src="https://images-na.ssl-images-amazon.com/images/G/01/mobile-apps/devportal2/res/images/amazon-appstore-badge-english-black.png" alt="Available at Amazon Appstore" height="60">](https://www.amazon.com/gp/product/B0FKF4M5M9) |
|:----------------------------------------------------------------------------------------------------------------------------------:|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|

### Or Download latest from [Releases](https://github.com/fiqryx/flipcard/releases/latest)

## Features ✨

- 📚 **Deck Organization** - Create nested decks with custom categories
- 🔄 **Import/Export** - Share decks via JSON with media support
- 🧠 **Adaptive Quizzing** - Built-in speech repetition algorithm
- 📊 **Progress Analytics** - Visual statistics of your learning progress
- 🌙 **Dark Mode** - Automatic theme switching based on system preferences

## Screenshots 📱

![Recorder](screenshots/screenrecord.gif)

## Development Guide ⚙️ 

### Requirements  
- Flutter 3.32.4+ (Dart 3.8.1+)
- Android SDK 33+
- Supabase URL & ANON KEY
- Run Supabase SQL Editor [generated.sql](./generated.sql)

### Quick Start  
```bash
git clone https://github.com/fiqryx/flipcard.git

cd flipcard && flutter pub get
```

```bash
flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
```