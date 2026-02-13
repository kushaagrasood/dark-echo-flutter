import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'maze_generator.dart'; 

class EchoWave {
  Offset center;
  double radius;
  double opacity;

  EchoWave({required this.center, this.radius = 0.0, this.opacity = 1.0});
}

enum BotState { idle, investigating, searching, chasing, cooldown }

class Bot {
  Offset position;
  double opacity;
  final double baseSpeed = 90.0; 
  
  BotState state = BotState.idle;
  double stateTimer = 0.0;
  
  double facingAngle = 0.0; 
  Offset? lastSeenPosition;
  Offset? currentWaypoint; 

  Offset? lastHeardPosition;
  double lastHeardStrength = 0.0;
  final double hearingThreshold = 0.15; 

  Bot({
    required this.position,
    this.opacity = 1.0,
  }); 
}

class GameModel extends ChangeNotifier {
  late Offset playerPos;
  final double playerRadius = 8.0;
  
  bool isGameOver = false;
  bool isGameWon = false;
  bool isCaught = false; 
  double caughtTimer = 0.0;
  
  int elapsedMilliseconds = 0;
  int? bestTimeMilliseconds;
  
  late Offset exitPos; 
  final double exitRadius = 20.0;

  late List<List<Offset>> walls; // <--- Changed from hardcoded list
  
  // -- Maze Parameters --
  final int gridWidth = 9;
  final int gridHeight = 11;
  final double cellSize = 40.0;
  final Offset mazeOffset = const Offset(20, 40); // Pushes the maze slightly down/right

  List<EchoWave> waves = [];
  late List<Bot> bots; // <--- Late init so we can place bots dynamically

  Offset velocity = Offset.zero; 
  Offset _actualVelocity = Offset.zero; 
  final double maxSpeed = 150.0;
  final double acceleration = 800.0;
  final double friction = 600.0;

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _footstepsPlayer = AudioPlayer();
  final AudioPlayer _heartbeatPlayer = AudioPlayer(); 
  final AudioPlayer _breathingPlayer = AudioPlayer(); 
  final AudioPlayer _jumpscarePlayer = AudioPlayer();
  
  bool _isFootstepsPlaying = false;
  bool _isHeartbeatPlaying = false;
  
  // NEW: Audio smooth transition state
  double _currentHeartbeatVolume = 0.0;

  // NEW: Visual Heartbeat Pulse
  double visualPulseIntensity = 0.0;
  double _pulseTimer = 0.0;

  GameModel() {
    _loadBestTime();
    _initAudio();
    _generateLevel(); // <--- Call new level generation on boot
  }

  // --- NEW: Procedural Generation Integration ---
  void _generateLevel() {
    final generator = MazeGenerator(
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      cellSize: cellSize,
      loopPercentage: 0.15, // 15% loops
      startOffset: mazeOffset,
    );

    // Define spawn at top-left, exit at bottom-right
    final startCell = const Point(0, 0);
    final exitCell = Point(gridWidth - 1, gridHeight - 1);

    // Generate Wall Line Segments
    walls = generator.generate(startCell, exitCell);

    // Place Player in the physical center of the Start Cell
    playerPos = mazeOffset + Offset(
      startCell.x * cellSize + (cellSize / 2), 
      startCell.y * cellSize + (cellSize / 2)
    );

    // Place Exit Door in the physical center of the Exit Cell
    exitPos = mazeOffset + Offset(
      exitCell.x * cellSize + (cellSize / 2), 
      exitCell.y * cellSize + (cellSize / 2)
    );

    // Place Bot randomly, but at least 4 cells away from the player
    final rng = Random();
    Point<int> botCell;
    do {
      botCell = Point(rng.nextInt(gridWidth), rng.nextInt(gridHeight));
    } while (botCell.distanceTo(startCell) < 4);

    bots = [
      Bot(position: mazeOffset + Offset(
        botCell.x * cellSize + (cellSize / 2), 
        botCell.y * cellSize + (cellSize / 2)
      ))
    ];
  }

  void _initAudio() async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _footstepsPlayer.setReleaseMode(ReleaseMode.loop);
    await _heartbeatPlayer.setReleaseMode(ReleaseMode.loop);
    _bgmPlayer.play(AssetSource('audio/game_ambience.ogg'));
  }

  @override
  void dispose() {
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
    _footstepsPlayer.dispose();
    _heartbeatPlayer.dispose();
    _breathingPlayer.dispose();
    _jumpscarePlayer.dispose();
    super.dispose();
  }

  Future<void> _loadBestTime() async {
    final prefs = await SharedPreferences.getInstance();
    bestTimeMilliseconds = prefs.getInt('best_time');
    notifyListeners();
  }

  Future<void> _saveBestTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('best_time', bestTimeMilliseconds!);
  }
  
  void update(double dt) {
    if (isGameOver || isGameWon) return; 

    if (isCaught) {
      caughtTimer += dt;
      if (caughtTimer >= 1.0) {
        isGameOver = true; 
        _jumpscarePlayer.play(AssetSource('audio/caught(fnaf).ogg'));
        notifyListeners();
      }
      return; 
    }

    elapsedMilliseconds += (dt * 1000).toInt();

    for (int i = waves.length - 1; i >= 0; i--) {
      waves[i].radius += 150 * dt;
      waves[i].opacity -= 0.5 * dt;
      if (waves[i].opacity <= 0) waves.removeAt(i);
    }

    if (velocity != Offset.zero) {
      _actualVelocity += velocity * acceleration * dt;
      if (_actualVelocity.distance > maxSpeed) {
        _actualVelocity = (_actualVelocity / _actualVelocity.distance) * maxSpeed;
      }
    } else {
      double currentSpeed = _actualVelocity.distance;
      if (currentSpeed > 0) {
        double newSpeed = currentSpeed - friction * dt;
        if (newSpeed <= 0) {
          _actualVelocity = Offset.zero;
        } else {
          _actualVelocity = (_actualVelocity / currentSpeed) * newSpeed;
        }
      }
    }

    Offset moveX = Offset(_actualVelocity.dx * dt, 0);
    Offset newPosX = playerPos + moveX;
    if (!_checkCollision(newPosX)) {
      playerPos = newPosX;
    } else {
      _actualVelocity = Offset(0, _actualVelocity.dy); 
    }

    Offset moveY = Offset(0, _actualVelocity.dy * dt);
    Offset newPosY = playerPos + moveY;
    if (!_checkCollision(newPosY)) {
      playerPos = newPosY;
    } else {
      _actualVelocity = Offset(_actualVelocity.dx, 0); 
    }

    double botDist = (bots[0].position - playerPos).distance;
    
    // --- 1. Footsteps Audio (Strictly Proximity) ---
    double hearingThreshold = 300.0; 
    if (botDist < hearingThreshold) {
      if (!_isFootstepsPlaying) {
        _footstepsPlayer.play(AssetSource('audio/footsteps.ogg'));
        _isFootstepsPlaying = true;
      }
      double vol = 1.0 - (botDist / hearingThreshold);
      _footstepsPlayer.setVolume(vol.clamp(0.0, 1.0));
      double rate = 1.0 + (1.0 - (botDist / hearingThreshold));
      _footstepsPlayer.setPlaybackRate(rate.clamp(1.0, 2.0));
    } else {
      if (_isFootstepsPlaying) {
        _footstepsPlayer.pause();
        _isFootstepsPlaying = false;
      }
    }

    // --- 2. NEW Layered Heartbeat Audio (State + Proximity) ---
    double targetHbVolume = 0.0;
    double targetHbRate = 1.0;

    if (bots[0].state == BotState.chasing) {
      // Climax state: Immediate high intensity
      targetHbVolume = 1.0;
      targetHbRate = 2.0; 
    } else if (botDist < 200.0) {
      // Proximity state: Scales gently with distance
      targetHbVolume = 1.0 - (botDist / 200.0);
      targetHbRate = 1.0 + (targetHbVolume * 0.5); 
    }

    // Smooth Volume Envelope (Attack and Fade)
    if (_currentHeartbeatVolume < targetHbVolume) {
      // Ramp up quickly when spotted (0.5 seconds to max)
      _currentHeartbeatVolume += 2.0 * dt; 
      if (_currentHeartbeatVolume > targetHbVolume) _currentHeartbeatVolume = targetHbVolume;
    } else if (_currentHeartbeatVolume > targetHbVolume) {
      // Fade out slowly when chase ends (2.0 seconds from max to 0)
      _currentHeartbeatVolume -= 0.5 * dt; 
      if (_currentHeartbeatVolume < targetHbVolume) _currentHeartbeatVolume = targetHbVolume;
    }

    // Apply the audio state
    if (_currentHeartbeatVolume > 0.0) {
      if (!_isHeartbeatPlaying) {
        _heartbeatPlayer.play(AssetSource('audio/heartbeat.ogg'));
        _isHeartbeatPlaying = true;
      }
      _heartbeatPlayer.setVolume(_currentHeartbeatVolume.clamp(0.0, 1.0));
      _heartbeatPlayer.setPlaybackRate(targetHbRate.clamp(1.0, 2.0));
    } else {
      if (_isHeartbeatPlaying) {
        _heartbeatPlayer.pause();
        _isHeartbeatPlaying = false;
      }
    }

    // --- Win & Loss Logic ---
    if ((playerPos - exitPos).distance < exitRadius) {
      if (!isGameWon) {
        isGameWon = true;
        _bgmPlayer.stop();
        _footstepsPlayer.stop();
        _heartbeatPlayer.stop();
        _sfxPlayer.play(AssetSource('audio/victory.ogg')); 
        
        if (bestTimeMilliseconds == null || elapsedMilliseconds < bestTimeMilliseconds!) {
          bestTimeMilliseconds = elapsedMilliseconds;
          _saveBestTime(); 
        }
      }
    }

    for (var bot in bots) {
      _updateBotFSM(bot, dt, botDist);

      if (botDist < 15) {
        if (!isCaught) {
          isCaught = true; 
          _actualVelocity = Offset.zero; 
          
          _bgmPlayer.stop();
          _footstepsPlayer.stop();
          _heartbeatPlayer.stop();
          _breathingPlayer.play(AssetSource('audio/breathing.ogg')); 
        }
      }
    }

    // --- VISUAL HEARTBEAT PULSE ---
    bool isChasing = bots.any((b) => b.state == BotState.chasing);
    if (isChasing) {
      double secondsPerBeat = 60.0 / 130.0; // 130 BPM panic heart rate
      _pulseTimer += dt;
      if (_pulseTimer >= secondsPerBeat) {
        visualPulseIntensity = 1.0; // Spike the visual intensity
        _pulseTimer -= secondsPerBeat; // Keep the remainder for accurate timing
      }
    } else {
      _pulseTimer = 0.0;
    }

    if (visualPulseIntensity > 0) {
      visualPulseIntensity -= dt * 3.0; // Fade out quickly over ~0.33 seconds
      if (visualPulseIntensity < 0) visualPulseIntensity = 0.0;
    }

    notifyListeners();
  }

  void _updateBotFSM(Bot bot, double dt, double distToPlayer) {
    bool canSeePlayer = false;
    if (distToPlayer <= 220.0) { 
      Offset toPlayer = playerPos - bot.position;
      double angleToPlayer = atan2(toPlayer.dy, toPlayer.dx);
      
      double angleDiff = (angleToPlayer - bot.facingAngle).abs();
      if (angleDiff > pi) angleDiff = 2 * pi - angleDiff;
      
      if (angleDiff <= (pi / 3)) { 
        if (_hasLineOfSight(bot.position, playerPos)) {
          canSeePlayer = true;
        }
      }
    }

    if (canSeePlayer) {
      bot.state = BotState.chasing;
      bot.lastSeenPosition = playerPos; 
    }

    bool heardNewSound = false;
    double strongestCurrentWave = 0.0;
    Offset? strongestWavePos;

    for (var wave in waves) {
      double distToWaveCenter = (bot.position - wave.center).distance;
      if (wave.radius >= distToWaveCenter) {
        double distanceFactor = 1.0 - (distToWaveCenter / 400.0).clamp(0.0, 1.0);
        double intensity = wave.opacity * distanceFactor;

        if (intensity > bot.hearingThreshold && intensity > strongestCurrentWave) {
          strongestCurrentWave = intensity;
          strongestWavePos = wave.center;
        }
      }
    }

    if (strongestWavePos != null && strongestCurrentWave >= bot.lastHeardStrength) {
      bot.lastHeardPosition = strongestWavePos;
      bot.lastHeardStrength = strongestCurrentWave;
      heardNewSound = true;
    }

    if (bot.lastHeardStrength > 0) {
      bot.lastHeardStrength -= 0.1 * dt; 
    }

    if (heardNewSound && bot.state != BotState.chasing && bot.state != BotState.searching) {
      bot.state = BotState.investigating;
    }

    switch (bot.state) {
      case BotState.idle:
        break;

      case BotState.investigating:
        if (bot.lastHeardPosition != null) {
          _moveBot(bot, bot.lastHeardPosition!, dt, 1.0); 
          
          if ((bot.position - bot.lastHeardPosition!).distance < 5.0) {
            bot.state = BotState.searching;
            bot.stateTimer = 4.0; 
            bot.lastSeenPosition = bot.lastHeardPosition; 
            bot.currentWaypoint = _getRandomNearbyPosition(bot.position, 60.0);
            bot.lastHeardStrength = 0.0; 
          }
        } else {
          bot.state = BotState.idle;
        }
        break;

      case BotState.chasing:
        if (canSeePlayer) {
          _moveBot(bot, playerPos, dt, 1.4); 
        } else {
          if (bot.lastSeenPosition != null) {
            _moveBot(bot, bot.lastSeenPosition!, dt, 1.4); 
            
            if ((bot.position - bot.lastSeenPosition!).distance < 5.0) {
              bot.state = BotState.searching;
              bot.stateTimer = 5.0; 
              bot.currentWaypoint = _getRandomNearbyPosition(bot.position, 80.0);
            }
          }
        }
        break;

      case BotState.searching:
        bot.stateTimer -= dt;
        if (bot.currentWaypoint != null) {
          _moveBot(bot, bot.currentWaypoint!, dt, 0.6); 
          
          if ((bot.position - bot.currentWaypoint!).distance < 5.0) {
            if (bot.lastSeenPosition != null) {
               bot.currentWaypoint = _getRandomNearbyPosition(bot.lastSeenPosition!, 80.0);
            }
          }
        }
        
        if (bot.stateTimer <= 0) {
          bot.state = BotState.cooldown;
          bot.stateTimer = 3.0; 
          bot.lastSeenPosition = null;
          bot.currentWaypoint = null;
        }
        break;

      case BotState.cooldown:
        bot.stateTimer -= dt;
        if (bot.stateTimer <= 0) {
          bot.state = BotState.idle;
        }
        break;
    }
  }

  void _moveBot(Bot bot, Offset destination, double dt, double speedMultiplier) {
    Offset dir = destination - bot.position;
    if (dir.distance > 0) {
      bot.facingAngle = atan2(dir.dy, dir.dx); 
      bot.position += (dir / dir.distance) * (bot.baseSpeed * speedMultiplier * dt);
    }
  }

  Offset _getRandomNearbyPosition(Offset center, double radius) {
    final random = Random();
    double angle = random.nextDouble() * 2 * pi;
    double r = random.nextDouble() * radius;
    return center + Offset(r * cos(angle), r * sin(angle));
  }

  void emitWave() {
    if (!isGameOver && !isGameWon && !isCaught) {
      waves.add(EchoWave(center: playerPos));
      _sfxPlayer.play(AssetSource('audio/ping.ogg')); 
    }
  }

  void resetGame() {
    isGameOver = false;
    isGameWon = false;
    isCaught = false;
    caughtTimer = 0.0;
    elapsedMilliseconds = 0; 
    waves.clear();
    velocity = Offset.zero;
    _actualVelocity = Offset.zero; 
    
    _generateLevel(); // <--- Generate a brand new layout every time they restart!
    
    _isFootstepsPlaying = false;
    _isHeartbeatPlaying = false;
    _currentHeartbeatVolume = 0.0; 
    
    _breathingPlayer.stop(); 
    _bgmPlayer.play(AssetSource('audio/game_ambience.ogg'));
    
    notifyListeners();
  }

  // --- MATH & COLLISION HELPERS ---

  bool _checkCollision(Offset pos) {
    for (var wall in walls) {
      for (int i = 0; i < wall.length - 1; i++) {
        if (_distToSegment(pos, wall[i], wall[i + 1]) < playerRadius) return true;
      }
    }
    return false;
  }

  double _distToSegment(Offset p, Offset v, Offset w) {
    double l2 = (v - w).distanceSquared;
    if (l2 == 0) return (p - v).distance;
    double t = ((p.dx - v.dx) * (w.dx - v.dx) + (p.dy - v.dy) * (w.dy - v.dy)) / l2;
    t = (t < 0) ? 0 : (t > 1 ? 1 : t);
    return (p - Offset(v.dx + t * (w.dx - v.dx), v.dy + t * (w.dy - v.dy))).distance;
  }

  bool _hasLineOfSight(Offset start, Offset end) {
    for (var wall in walls) {
      for (int i = 0; i < wall.length - 1; i++) {
        if (_doIntersect(start, end, wall[i], wall[i + 1])) {
          return false; 
        }
      }
    }
    return true; 
  }

  bool _doIntersect(Offset p1, Offset q1, Offset p2, Offset q2) {
    int o1 = _orientation(p1, q1, p2);
    int o2 = _orientation(p1, q1, q2);
    int o3 = _orientation(p2, q2, p1);
    int o4 = _orientation(p2, q2, q1);

    if (o1 != o2 && o3 != o4) return true;

    if (o1 == 0 && _onSegment(p1, p2, q1)) return true;
    if (o2 == 0 && _onSegment(p1, q2, q1)) return true;
    if (o3 == 0 && _onSegment(p2, p1, q2)) return true;
    if (o4 == 0 && _onSegment(p2, q1, q2)) return true;

    return false;
  }

  int _orientation(Offset p, Offset q, Offset r) {
    double val = (q.dy - p.dy) * (r.dx - q.dx) - (q.dx - p.dx) * (r.dy - q.dy);
    if (val == 0) return 0; 
    return (val > 0) ? 1 : 2; 
  }

  bool _onSegment(Offset p, Offset q, Offset r) {
    return q.dx <= max(p.dx, r.dx) && q.dx >= min(p.dx, r.dx) &&
           q.dy <= max(p.dy, r.dy) && q.dy >= min(p.dy, r.dy);
  }
}