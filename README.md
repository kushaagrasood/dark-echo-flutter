# 🎮 Dark Echo

**A survival horror experience built entirely in Flutter**

[![Download APK](https://img.shields.io/badge/Download-APK-success)](https://github.com/kushaagrasood/dark-echo-flutter/releases/latest)
[![Flutter](https://img.shields.io/badge/Flutter-3.27-blue)](https://flutter.dev)

---

## What is this?

Dark Echo is a 2D top-down survival horror game where darkness isn't just an aesthetic choice - it's your primary obstacle. You're stuck in a procedurally generated maze with zero visibility, armed only with a sonar-like echo ability to reveal your surroundings. Oh, and something's hunting you.

Built from scratch using Flutter's rendering pipeline without any game engines.

---

## Gameplay

The concept is simple but unforgiving: navigate pitch-black mazes, use sound pulses to see where you're going, and don't let the AI catch you. Every movement you make creates noise. Every echo you emit gives away your position. The entity hunting you can hear, see (kind of), and remember where you were.

**What you need to survive:**
- **Echo Location** – Your only way to "see" is by emitting sonar pulses that briefly reveal walls
- **Stealth** – Movement creates noise that the AI can hear from a distance
- **Smart Evasion** – Break line-of-sight and outsmart the AI's search patterns
- **Speed** – Find the green exit before your ping charges run out or you run out of luck

Three difficulty modes scale enemy behavior, detection ranges, maze complexity, and your available resources. Easy is actually easy. Hard is... not.

---

## Technical Deep Dive

This started as an experiment: "Can you make a real-time game in Flutter without a game engine?" Turns out, yes - but it requires building basically everything yourself.

### Game Loop

Custom 60 FPS game loop using Flutter's `Ticker` API. Delta time calculations keep physics and AI frame-rate independent, so the game runs consistently whether you're on a flagship phone or something from 2016.

### Rendering

Everything - maze walls, characters, particle effects, post-processing - is drawn using `CustomPainter`. The camera smoothly follows the player with interpolated lag. During chase sequences, subtle screen shake and visual distortion kick in. No sprites, no pre-built renderers, just Canvas API calls.

### Procedural Maze Generation

Mazes are generated fresh each game using recursive backtracking with intentional loop injection. A BFS validation pass ensures there are always multiple valid paths from start to exit - no single chokepoint hallways. The same pathfinding system powers enemy navigation.

### AI State Machine

The enemy isn't just chasing you blindly. It operates through five behavioral states:

- **Idle** – Random patrol with pauses (it's just vibing until you make noise)
- **Investigating** – Moves toward the approximate origin of sounds it heard
- **Chasing** – Direct pursuit when it has both vision cone alignment AND clear line-of-sight
- **Searching** – Explores your last known position when line-of-sight breaks
- **Cooldown** – Gradually returns to idle after losing track of you

The AI uses *approximate* position tracking, not perfect omniscience. Sound detection has distance-based falloff. Vision requires both angle alignment and unobstructed line-of-sight - you can actually hide around corners.

### Audio System

Audio does a lot of heavy lifting for tension:
- **Footsteps** scale playback rate with movement speed
- **Heartbeat** increases in volume and rate as danger approaches
- **Tension drone** (sub-bass layer) kicks in during active chases
- **Audio ducking** reduces ambient music by 30% during high-intensity moments
- **Smooth crossfades** prevent jarring audio cuts

### Death Sequence

Getting caught triggers a multi-phase sequence: movement freeze → sharp breath intake audio → delayed jumpscare → game over. No abrupt cuts or janky transitions - everything flows naturally.

### Pause System

Full pause functionality with complete state preservation. Audio pauses cleanly, BGM ducks to 30% volume, all game logic halts. Resuming restores the exact game state without frame skips or desyncs.

---

## Features

-  Pure Flutter implementation (seriously, no game engines)
-  Procedural generation with guaranteed solvability
-  AI with vision, hearing, memory, and behavioral states
-  Layered dynamic audio that responds to gameplay
-  Responsive terminal-aesthetic UI
-  Three difficulty modes with distinct tuning
-  Proper death and victory sequences
-  Runs at 60 FPS on mid-range devices

---

## Screenshots

![Main Menu](https://github.com/user-attachments/assets/945a033c-4400-4dd6-a6df-5cfe17e25b37)

![Gameplay - Chase Sequence](https://github.com/user-attachments/assets/f43127b6-33bb-4ec3-9732-d10b760b7aeb)

![Gameplay - Echo Pulse](https://github.com/user-attachments/assets/5fe4b4c0-495b-44f9-b110-17791f92ab36)

![Death Screen](https://github.com/user-attachments/assets/66ee9231-1d59-4e51-89bb-d70a97884268)

![Victory Screen](https://github.com/user-attachments/assets/4f0d023f-33f6-4968-9bcd-85e70c442928)

---

## Running the Game

### Prerequisites
- Flutter SDK 3.27.0 or higher
- Dart 3.0+
- An Android device or emulator

### Installation
```bash
# Clone the repo
git clone https://github.com/kushaagrasood/dark-echo-flutter.git
cd dark-echo-flutter

# Get dependencies
flutter pub get

# Run on device/emulator
flutter run
```

### Or Just Download the APK

Head to [Releases](https://github.com/kushaagrasood/dark-echo-flutter/releases/latest) and grab the latest APK. Works on Android 5.0+.

---

## Project Structure
```
dark-echo-flutter/
├── assets/
│   ├── audio/              # All sound effects and music
│   │   ├── breathing.ogg
│   │   ├── caught.ogg
│   │   ├── footsteps.ogg
│   │   ├── game_ambience.ogg
│   │   ├── heartbeat.ogg
│   │   ├── menu_theme.ogg
│   │   ├── ping.ogg
│   │   └── tension.ogg
│   └── fonts/
│       └── VT323-Regular.ttf
│
├── lib/
│   ├── main.dart           # Entry point, theme config
│   ├── main_menu.dart      # Terminal-style main menu
│   ├── credits_screen.dart # Credits screen
│   ├── game_page.dart      # Game UI and controls overlay
│   ├── game_model.dart     # Core game logic, AI, physics
│   ├── game_painter.dart   # Custom rendering pipeline
│   ├── maze_generator.dart # Procedural maze algorithm
│   └── arrow_controls.dart # Touch-based directional input
│
├── android/                # Android platform files
└── pubspec.yaml            # Dependencies and assets
```

---

## Technical Stack

| Component | Implementation |
|-----------|---------------|
| **Rendering** | `CustomPainter` + `Canvas` API |
| **Game Loop** | `Ticker` (60 FPS target) |
| **Physics** | Custom 2D collision detection |
| **AI** | Finite state machine + BFS pathfinding |
| **Audio** | `audioplayers` (7 concurrent channels) |
| **Persistence** | `shared_preferences` for best times |
| **UI** | Pure Flutter widgets (no game-specific libraries) |

---

## Why This Exists

This project started as a challenge: build a real-time game using only Flutter's standard APIs. No shortcuts, no game engines, no "just use Flame." It's a proof-of-concept that Flutter's rendering and event systems are capable of more than they're typically given credit for.

It's also a learning exercise in systems programming - building a custom game loop, implementing AI behavior trees, managing audio layers, optimizing render cycles. If you're curious about low-level game development or want to see Flutter pushed beyond typical mobile app patterns, this might be interesting.

---

## Known Issues

None at the moment, but if you find something broken, [open an issue](https://github.com/kushaagrasood/dark-echo-flutter/issues).

---

## Credits

**Developer:** Kushaagra Sood  
**Organization:** Android Club VIT Chennai

**Connect:**
- GitHub: [@kushaagrasood](https://github.com/kushaagrasood/)
- LinkedIn: [kushaagrasood23](https://www.linkedin.com/in/kushaagrasood23/)

---
## License

MIT License - See [LICENSE](LICENSE) for details.

Copyright © 2026 Kushaagra Sood

Developed for Android Club VIT Chennai.

---

*Proof that compelling game experiences don't require game engines - just Flutter and a willingness to build everything yourself.*
