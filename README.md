# 🌸 MoodScape

A cross-platform mental wellness and mood companion mobile application built with Flutter and Firebase.

MoodScape helps users manage their emotional well-being through mood-based music therapy, personal journaling, and mood analytics — available on Android and iOS.

## Features

### Mood-Based Music
- Select from 5 mood states: Happy, Sad, Calm, Angry, and Nutcracker 🎄
- Streams curated playlists from Firebase Storage
- Full playback controls with real-time progress bar
- Music continues playing in the background

### Personal Journal
- Write daily journal entries with text or speech-to-text
- Attach photos from the camera or the gallery
- Tag your location with reverse geocoding
- Full CRUD — create, read, edit, and delete entries

### Mood History & Analytics
- Calendar heatmap showing mood per day
- Bar chart showing mood frequency breakdown
- Real-time sync across devices via Firestore
- Delete individual mood logs

### Notifications
- Daily mood check-in reminders at a user-defined time
- Wellness prompts triggered by accelerometer inactivity detection
- Out-of-app system notifications

### Settings
- Toggle daily reminders on/off
- Set custom reminder time
- Edit display name
- Sign out

### Authentication
- Email/password sign up and login
- Google Sign-In
- Auth state persistence — stay logged in between sessions

### Device Features (9 total)
| Feature | Usage |
|---|---|
| Speaker / Audio | Mood-based music playback |
| Microphone | Speech-to-text journaling |
| Camera | Journal photo attachments |
| GPS / Geolocation | Location tagging on journal entries |
| Push Notifications | Daily check-in reminders |
| Offline Storage | Hive local database for offline use |
| Background Tasks | Music continues when app is minimised |
| Accelerometer | Inactivity detection for wellness prompts |
| Splash Screen | Branded animated launch screen |

## Tech Stack

| Category | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Backend | Firebase (Auth, Firestore, Storage, FCM) |
| Local Storage | Hive |
| Audio | just_audio + audio_service |
| Charts | fl_chart + table_calendar |
| Maps/Location | geolocator + geocoding |
| Notifications | flutter_local_notifications + timezone |
| Speech | speech_to_text |
| UI | Google Fonts (Poppins) |


## Project Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   └── theme/
│       └── app_theme.dart
├── data/
│   ├── models/
│   │   ├── mood_model.dart
│   │   └── track_model.dart
│   └── services/
│       ├── mood_service.dart
│       ├── notification_service.dart
│       └── accelerometer_service.dart
├── features/
│   ├── auth/
│   │   └── screens/
│   │       ├── splash_screen.dart
│   │       ├── onboarding_screen.dart
│   │       └── login_screen.dart
│   ├── mood/
│   │   └── screens/
│   │       └── home_screen.dart
│   ├── player/
│   │   └── screens/
│   │       └── player_screen.dart
│   ├── journal/
│   │   └── screens/
│   │       └── journal_screen.dart
│   ├── history/
│   │   └── screens/
│   │       └── history_screen.dart
│   └── settings/
│       └── screens/
│           └── settings_screen.dart
└── shared/
    └── widgets/
        └── bottom_nav.dart
```


## Getting Started

### Prerequisites
- Flutter SDK 3.x
- Dart 3.x
- Android Studio or VS Code
- Firebase project

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/francesseyram/moodscape.git
cd moodscape
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Firebase**
```bash
flutterfire configure
```

4. **Run the app**
```bash
flutter run
```

### Building the APK
```bash
flutter build apk --release
```

---

## Firestore Structure

```
firestore/
├── moods/{moodId}          # Mood cards (admin-controlled)
├── playlists/{moodId}/
│   └── tracks/{trackId}    # Audio tracks per mood
├── quotes/{quoteId}        # Wellness quotes per mood
└── users/{uid}/
    ├── moodLogs/{logId}    # User mood history
    └── journalEntries/{id} # User journal entries
```


## Developer

Built by Frances Seyram Fiahagbe as a Mobile Application Development final project.

---

