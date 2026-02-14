# 🎮 Dark Echo

**A survival horror experience built entirely in Flutter—no game engines, just code.**

---

## Overview

Dark Echo is a 2D top-down survival horror game where darkness is your enemy and sound is your only guide. Navigate procedurally generated mazes while being hunted by an intelligent AI adversary. Every footstep matters. Every echo reveals—and betrays.

Built from the ground up using Flutter's rendering pipeline, Dark Echo demonstrates that compelling game experiences don't require traditional game engines.

---

## Gameplay

You awaken in absolute darkness. The maze shifts with each attempt. An unseen entity stalks you, reacting to your sounds.

**Survival depends on:**
- **Echo Location** – Emit sonar pulses to temporarily reveal walls
- **Stealth** – Movement creates noise; the enemy hears everything
- **Evasion** – Break line-of-sight, outsmart the AI's search patterns
- **Speed** – Find the exit before your resources or luck run out

The game features three difficulty tiers, each tuning enemy speed, detection range, maze complexity, and available resources.

---

## Technical Architecture

Dark Echo is a technical exercise in building a real-time game using Flutter's core APIs, without relying on external game frameworks.

### Core Systems

**Game Loop**  
Custom game loop implemented using Flutter's `Ticker` API, running at 60 FPS. Delta time calculations ensure frame-rate-independent physics and AI updates.

**Rendering Pipeline**  
All visual elements—maze walls, entities, particles, post-processing effects—are drawn using `CustomPainter`. Camera follows the player with interpolated lag. Chase sequences trigger subtle screen shake and visual distortion.

**Procedural Maze Generation**  
Mazes are generated using recursive backtracking with strategic loop injection. A BFS validation pass ensures multiple valid paths exist between start and exit, eliminating chokepoint scenarios. Grid-based pathfinding powers enemy navigation.

**AI State Machine**  
The enemy operates through five distinct states:
- **Idle** – Random patrol with timed pauses
- **Investigating** – Moves toward approximate sound origin
- **Chasing** – Direct pursuit with vision cone + line-of-sight validation
- **Searching** – Explores last known player position when LOS breaks
- **Cooldown** – Gradual return to idle state

The AI uses *approximate* position tracking—not omniscient perfect tracking. Sound-based detection has distance-based intensity falloff. Vision requires both cone angle alignment and unobstructed line-of-sight.

**Audio System**  
Layered dynamic audio creates tension:
- Player footsteps (rate scales with velocity)
- Proximity-based heartbeat (volume + rate increase with danger)
- Sub-bass tension drone during active chase
- Audio ducking system (ambient reduces 30% during chase)
- Smooth crossfades prevent jarring transitions

**Death Sequence**  
Contact triggers a multi-phase death state: movement freeze → breathing audio → delayed jumpscare → game over screen. Player retains control flow without abrupt transitions.

**Pause System**  
Game supports full pause with state preservation. Audio pauses cleanly, BGM ducks to 30%, and all game logic halts. Resume restores exact state without frame skips.

---

## Key Features

- **Pure Flutter Implementation** – No Flame, no Unity, no external engines
- **Procedural Generation** – Every maze is unique with guaranteed solvability
- **Intelligent AI** – State-driven behavior with vision, hearing, and memory
- **Dynamic Audio** – Layered soundscape responds to gameplay events
- **Responsive UI** – Terminal-aesthetic menus scale across device sizes
- **Multiple Difficulties** – Easy, Medium, Hard with distinct tuning
- **Death & Victory States** – Narrative-driven sequences with audio cues
- **Performance Optimized** – 60 FPS target on mid-range devices

---

## Screenshots

![IMG_20260215_023218](https://github.com/user-attachments/assets/945a033c-4400-4dd6-a6df-5cfe17e25b37)

![IMG_20260215_023349](https://github.com/user-attachments/assets/5fe4b4c0-495b-44f9-b110-17791f92ab36)

![IMG_20260215_023459](https://github.com/user-attachments/assets/f43127b6-33bb-4ec3-9732-d10b760b7aeb)

![IMG_20260215_023628](https://github.com/user-attachments/assets/66ee9231-1d59-4e51-89bb-d70a97884268)

![IMG_20260215_023659](https://github.com/user-attachments/assets/4f0d023f-33f6-4968-9bcd-85e70c442928)

---

## How to Run

### Prerequisites
- Flutter SDK (3.27.0 or higher)
- Dart 3.0+

### Installation
```bash
# Clone the repository
git clone https://github.com/kushaagrasood/dark-echo-flutter.git
cd dark-echo-flutter

# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run
```

### Audio Assets
Ensure `assets/audio/` contains the following files:
- `game_ambience.ogg`
- `menu_theme.ogg`
- `footsteps.ogg`
- `heartbeat.ogg`
- `tension.ogg`
- `breathing.ogg`
- `caught.ogg`
- `ping.ogg`
- `victory.ogg`

---

## Project Structure
```
lib/
├── main.dart              # App entry point
├── main_menu.dart         # Terminal-style main menu
├── game_page.dart         # Game container & UI overlay
├── game_model.dart        # Core game state & logic
├── game_painter.dart      # Custom rendering pipeline
├── maze_generator.dart    # Procedural maze algorithm
├── arrow_controls.dart    # Touch-based directional input
└── credits_screen.dart    # Attribution screen
```

---

## Technical Specifications

| Component | Implementation |
|-----------|---------------|
| **Rendering** | `CustomPainter` with `Canvas` API |
| **Game Loop** | `Ticker` (SingleTickerProviderStateMixin) |
| **Physics** | Custom 2D vector math, collision detection |
| **AI** | Finite state machine with BFS pathfinding |
| **Audio** | `audioplayers` package (7 concurrent channels) |
| **Persistence** | `shared_preferences` for best times |
| **UI Framework** | Pure Flutter widgets, no game-specific UI libraries |

---

## Credits

**Developer**  
Kushaagra Sood

**Organization**  
Android Club VIT Chennai

**Connect**  
- GitHub: [kushaagrasood](https://github.com/kushaagrasood/)
- LinkedIn: [kushaagrasood23](https://www.linkedin.com/in/kushaagrasood23/)
  
---

## Acknowledgments

Developed as part of Android Club VIT Chennai project activities.
---

*Dark Echo proves that compelling interactive experiences can emerge from fundamental APIs and creative problem-solving. No engines required - just Flutter.*
