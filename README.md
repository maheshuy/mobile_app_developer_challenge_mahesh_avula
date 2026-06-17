# Peblo Flutter Developer Intern Challenge

## AI Story Buddy & Quiz Component

Candidate: Mahesh Avula
Framework: Flutter

## Overview

This project is a single-screen, kid-friendly Flutter app built for the Peblo Flutter Developer Intern Challenge. It presents a joyful AI Story Buddy experience where a child can listen to a short story through text-to-speech narration and then answer an interactive quiz question.

The app includes a playful robo-dragon buddy, a story card, a large "Read Me a Story" button, text-to-speech narration, and a data-driven quiz that appears after the narration is completed.

## Framework Chosen and Why

I chose Flutter because it allows building smooth, lightweight, cross-platform mobile apps with a single codebase. Flutter is suitable for colourful UI, quick animations, and responsive layouts. It also supports native text-to-speech integration through the `flutter_tts` package.

Since Peblo's target audience includes children using mid-range Android devices, Flutter is a good choice because it can deliver polished UI while keeping the app lightweight.

## Features Implemented

* Single-screen kid-friendly UI
* Colourful pastel background with playful visual elements
* Cute robo-dragon AI Buddy character
* Story card displaying the given story text
* Large "Read Me a Story" button
* Text-to-speech narration using `flutter_tts`
* Loading/preparing state before narration starts
* Speaking state while the story is being read
* Friendly failure message if TTS fails
* Quiz revealed after narration completes
* Quiz rendered from JSON data
* Wrong answer feedback with red state and shake animation
* Correct answer feedback with green success state
* Confetti celebration on success
* Provider-based state management

## Story Text

The story text narrated by the app is:

```text
Once upon a time, a clever little robot named Pip lost his shiny blue gear in the Whispering Woods...
```

## Audio and Quiz Transition

The app uses the `flutter_tts` package for text-to-speech narration.

When the user taps the "Read Me a Story" button:

1. The app moves to a preparing state.
2. The button shows a preparing/loading state.
3. The story narration begins.
4. Once the TTS completion callback is triggered, the app updates the state.
5. The quiz is smoothly revealed using `AnimatedSwitcher`.

The quiz is intentionally hidden until the narration is completed, so the user experiences the flow as story first, quiz next.

## Data-Driven Quiz Rendering

The quiz is built from this JSON object:

```json
{
  "question": "What colour was Pip the Robot's lost gear?",
  "options": ["Red", "Green", "Blue", "Yellow"],
  "answer": "Blue"
}
```

The question and answer options are not hardcoded in the UI. The JSON is parsed into a `QuizData` model, and the UI dynamically renders the available options from the `options` list.

This means that if a backend sends a different question or a different number of options, such as 3, 4, or 5 options, the same renderer can display them without requiring UI code changes.

## Wrong Answer Interaction

When the child selects a wrong answer:

* The quiz card changes to a red error state.
* The selected wrong option is highlighted.
* A shake animation is triggered.
* Haptic feedback is triggered.
* A friendly retry message is displayed.
* The child can try again without restarting the app.

This gives clear feedback while keeping the experience playful and encouraging.

## Correct Answer Interaction

When the child selects the correct answer:

* The quiz card changes to a green success state.
* The correct answer is highlighted.
* The AI Buddy moves into a happy state.
* Confetti is triggered.
* A success message is displayed.

This creates a celebratory moment for the child after answering correctly.

## State Management

I used Provider for state management.

The `StoryQuizProvider` manages:

* Audio state
* Quiz visibility
* Selected option
* Wrong answer state
* Success state
* Friendly UI messages
* Parsed quiz data

This keeps the UI reactive and avoids unnecessary logic inside widgets.

## Caching Approach

This version uses the native/device TTS engine through `flutter_tts`, so no remote audio file is downloaded or cached.

If a remote API such as ElevenLabs were used, I would cache the generated audio file locally. The cache key would be based on the story text or story ID. On the next playback, the app would first check local storage and only call the remote API if the audio was missing or expired.

This would reduce network calls, improve startup time, and support better playback on slower connections.

## Loading and Failure Handling

The app handles the following audio states:

* Idle
* Preparing
* Speaking
* Completed
* Failed

During the preparing state, the button shows a loading/preparing message. If TTS fails, the app shows a friendly retry message instead of crashing or freezing.

## Performance and Lightweight Optimization

The app is designed to stay lightweight for mid-range Android devices with around 3GB RAM.

Optimizations used:

* No heavy video assets
* No large Lottie files
* Custom UI drawn using Flutter widgets and shapes
* Provider-based state updates
* Confetti only runs during the success state
* Built-in Flutter animations such as `AnimatedSwitcher`, `AnimatedContainer`, `AnimatedScale`, and `TweenAnimationBuilder`
* Quiz options generated dynamically from JSON
* Responsive layout using `SingleChildScrollView`, `ConstrainedBox`, `Wrap`, and `LayoutBuilder`

## Performance Profiling

I manually tested the following interactions:

* App launch
* Story button state change
* TTS start and completion
* Quiz reveal animation
* Wrong answer red shake animation
* Correct answer green success state
* Confetti celebration

During testing, the UI remained smooth in Chrome debug mode. In a production pass, I would use Flutter DevTools frame timing to measure build/raster times before and after reducing unnecessary rebuilds.

## AI Usage and Judgment

I used AI assistance to plan the Flutter structure, UI improvements, package choices, and README coverage.

One suggestion I changed was using a remote ElevenLabs API for narration. I rejected that for this version because native TTS is more reliable for a short challenge, avoids API key handling, reduces network dependency, and works better for a lightweight app.

One issue I faced was setting up Flutter dependencies on Windows. I resolved it by enabling Developer Mode and running `flutter pub get` successfully.

## What I Tried That Did Not Work

Initially, Flutter package installation failed because Windows Developer Mode was disabled. Since plugin-based Flutter builds require symlink support on Windows, I enabled Developer Mode and reran `flutter pub get`. After that, dependencies installed successfully.

## How to Run

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

Run on Chrome for testing:

```bash
flutter run -d chrome
```

## Demo Flow

The submitted screen recording shows:

1. App opening with the AI Story Buddy
2. User tapping "Read Me a Story"
3. Story narration flow
4. Quiz appearing after narration
5. Wrong answer feedback with red shake animation
6. Correct answer selection
7. Green success state with celebration
