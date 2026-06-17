# Peblo Flutter Developer Intern Challenge

## AI Story Buddy & Quiz Component

Candidate: Mahesh Avula
Framework: Flutter

## Overview

This project is a single-screen kid-friendly Flutter app built for the Peblo Flutter / Swift Developer Intern Challenge. The app shows an AI Story Buddy character, a story card, a "Read Me a Story" button, text-to-speech narration, and a data-driven quiz that appears after the narration completes.

## Framework Chosen and Why

I chose Flutter because it supports building smooth, lightweight mobile interfaces using a single codebase. Flutter also provides good support for animations, state-driven UI updates, and native text-to-speech integration through packages such as `flutter_tts`.

## Features Implemented

* Kid-friendly colourful UI
* AI Buddy character with happy state
* Story text card
* Text-to-speech narration trigger
* Loading/preparing state while narration starts
* Friendly error handling if TTS fails
* Quiz revealed after narration completion
* Quiz rendered from JSON data
* Wrong-answer shake feedback
* Haptic feedback for quiz interaction
* Correct-answer success state
* Confetti celebration

## Audio and Quiz Transition

The app uses `flutter_tts` for text-to-speech narration. The audio state is managed using Provider. When the user taps "Read Me a Story", the app moves into a preparing state and then starts narration.

The quiz is not visible initially. Once the TTS completion callback is triggered, the app updates the state and smoothly reveals the quiz using `AnimatedSwitcher`.

## Data-Driven Quiz Rendering

The quiz is created from the following JSON object:

```json
{
  "question": "What colour was Pip the Robot's lost gear?",
  "options": ["Red", "Green", "Blue", "Yellow"],
  "answer": "Blue"
}
```

The UI does not hardcode the options. The options are rendered dynamically using the `options` list from the parsed JSON. If the backend sends a different question or 3, 4, or 5 options, the same renderer can display them without code changes.

## Caching Approach

This version uses the device/native TTS engine, so no remote audio file is downloaded or cached.

If a remote audio API such as ElevenLabs were used, I would cache the generated audio file locally using a file-based cache. The cache key would be based on the story text or a story ID. On the next playback, the app would first check local cache and only call the remote API if the audio is missing or expired.

## Loading and Failure Handling

The app handles the following audio states:

* Idle
* Preparing
* Speaking
* Completed
* Failed

During preparation, the button shows a loading state. If narration fails, the app displays a friendly retry message instead of crashing or freezing.

## Performance and Lightweight Optimization

The app is designed to stay lightweight for mid-range Android devices with around 3GB RAM.

Optimizations used:

* Simple Flutter widgets instead of heavy video or large animation assets
* Lightweight emoji-based Buddy placeholder
* Provider-based state management to keep UI updates predictable
* Smooth built-in animations such as `AnimatedSwitcher`, `AnimatedContainer`, and `AnimatedSlide`
* Confetti only plays during success state
* Quiz options are generated efficiently using the JSON options list

For profiling, I checked the app in debug mode and verified that the UI interaction, quiz reveal, shake feedback, and success animation were smooth during manual testing. In a production pass, I would use Flutter DevTools frame timing to compare frame performance before and after reducing unnecessary rebuilds.

## AI Usage and Judgment

I used AI assistance to plan the project structure, Flutter package choices, and README coverage. One suggestion I changed was using a remote ElevenLabs API for narration. I rejected that for this version because native TTS is more reliable for a short internship assignment, avoids API key handling, and works better without depending on network availability.

One issue I faced was setting up Flutter dependencies on Windows. I resolved it by enabling Developer Mode and running `flutter pub get` again successfully.

## How to Run

```bash
flutter pub get
flutter run
```

For Chrome testing:

```bash
flutter run -d chrome
```

## Demo Flow

The screen recording shows:

1. App opening with AI Story Buddy
2. User tapping "Read Me a Story"
3. Story narration flow
4. Quiz appearing after narration
5. Wrong answer feedback with shake
6. Correct answer selection
7. Success state with celebration
