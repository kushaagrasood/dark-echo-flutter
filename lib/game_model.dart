import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'maze_generator.dart';

// --- DIFFICULTY CONFIGURATION ---
enum Difficulty { easy, medium, hard }

class DifficultyConfig {
  final double botSpeedMultiplier;
  final double hearingRadius; 
  final double loopPercentage; 
  final int maxEchoCharges; 
  final double searchDuration; 
  final double panicRadius; 
  final double mazeCellSize; 
  final int gridWidth; 
  final int gridHeight;

  const DifficultyConfig({
    required this.botSpeedMultiplier,
    required this.hearingRadius,
    required this.loopPercentage,
    required this.maxEchoCharges,
    required this.searchDuration,
    required this.panicRadius,
    required this.mazeCellSize,
    required this.gridWidth,
    required this.gridHeight,
  });

  factory DifficultyConfig.get(Difficulty level) {
    switch (level) {
      case Difficulty.easy:
        return const DifficultyConfig(
          botSpeedMultiplier: 0.64,
          hearingRadius: 300.0,
          loopPercentage: 0.25, 
          maxEchoCharges: 8,
          searchDuration: 6.0, 
          panicRadius: 100.0, 
          mazeCellSize: 60.0,
          gridWidth: 12,
          gridHeight: 7,
        );
      case Difficulty.medium:
        return const DifficultyConfig(
          botSpeedMultiplier: 0.8,
          hearingRadius: 400.0,
          loopPercentage: 0.15,
          maxEchoCharges: 6,
          searchDuration: 4.0,
          panicRadius: 150.0,
          mazeCellSize: 50.0,
          gridWidth: 14,
          gridHeight: 8,
        );
      case Difficulty.hard:
        return const DifficultyConfig(
          botSpeedMultiplier: 0.92,
          hearingRadius: 550.0,
          loopPercentage: 0.05, 
          maxEchoCharges: 5,
          searchDuration: 2.5, 
          panicRadius: 200.0, 
          mazeCellSize: 40.0,
          gridWidth: 18,
          gridHeight: 10,
        );
    }
  }
}

// --- GAME CLASSES ---
class EchoWave {
  Offset center;
  double radius;
  double opacity;
  final double maxRadius = 400.0;

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

  // Pathfinding
  List<Point<int>> currentPath = [];
  int currentPathIndex = 0;

  // Anti-corner trap
  double hesitationTimer = 0.0;

  Bot({
    required this.position,
    this.opacity = 1.0,
  }); 
}

class GameModel extends ChangeNotifier {
  late DifficultyConfig config;
  Difficulty currentDifficulty = Difficulty.medium;
  int currentEchoCharges = 0;

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

  late List<List<Offset>> walls; 
  final Offset mazeOffset = const Offset(20, 40); 

  // Camera follow
  Offset cameraOffset = Offset.zero;
  Offset cameraTarget = Offset.zero;
  final double cameraLag = 0.15;

  Map<int, double> wallRevealTimers = {};
  Set<int> currentlyHitWalls = {};

  List<EchoWave> waves = [];
  late List<Bot> bots; 

  late MazeGenerator mazeGenerator;

  Offset velocity = Offset.zero; 
  Offset _actualVelocity = Offset.zero; 
  final double maxSpeed = 150.0;
  final double acceleration = 800.0;
  final double friction = 600.0;

  // FIXED: Separate dedicated audio players - NEVER reuse
  final AudioPlayer _bgmPlayer = AudioPlayer();        // ONLY for background music
  final AudioPlayer _sfxPlayer = AudioPlayer();        // ONLY for one-shot SFX (ping, victory, scream)
  final AudioPlayer _footstepsPlayer = AudioPlayer();  // ONLY for footsteps
  final AudioPlayer _heartbeatPlayer = AudioPlayer();  // ONLY for heartbeat
  final AudioPlayer _breathingPlayer = AudioPlayer();  // ONLY for breathing
  final AudioPlayer _jumpscarePlayer = AudioPlayer(); // ONLY for jumpscare
  final AudioPlayer _tensionPlayer = AudioPlayer();    // ONLY for tension drone
  
  bool _isFootstepsPlaying = false;
  bool _isHeartbeatPlaying = false;
  bool _isTensionPlaying = false;
  double _currentHeartbeatVolume = 0.0;
  double _currentTensionVolume = 0.0;
  double _currentBgmVolume = 1.0;

  double visualPulseIntensity = 0.0;
  double _pulseTimer = 0.0;

  // Visual panic layer
  double panicIntensity = 0.0;

  final double displayWidth = 760.0;
  final double displayHeight = 410.0;

  GameModel({Difficulty difficulty = Difficulty.medium}) {
    currentDifficulty = difficulty;
    config = DifficultyConfig.get(difficulty);
    currentEchoCharges = config.maxEchoCharges;

    _loadBestTime();
    _initAudio();
    _generateLevel();
  }

  void changeDifficulty(Difficulty newDifficulty) {
    currentDifficulty = newDifficulty;
    config = DifficultyConfig.get(newDifficulty);
    resetGame();
  }

  void _generateLevel() {
    mazeGenerator = MazeGenerator(
      gridWidth: config.gridWidth,
      gridHeight: config.gridHeight,
      cellSize: config.mazeCellSize,
      loopPercentage: config.loopPercentage,
      startOffset: mazeOffset,
    );

    final startCell = const Point(0, 0);
    final exitCell = Point(config.gridWidth - 1, config.gridHeight - 1);

    walls = mazeGenerator.generate(startCell, exitCell);

    playerPos = mazeOffset + Offset(
      startCell.x * config.mazeCellSize + (config.mazeCellSize / 2), 
      startCell.y * config.mazeCellSize + (config.mazeCellSize / 2)
    );

    exitPos = mazeOffset + Offset(
      exitCell.x * config.mazeCellSize + (config.mazeCellSize / 2), 
      exitCell.y * config.mazeCellSize + (config.mazeCellSize / 2)
    );

    final rng = Random();
    Point<int> botCell;
    do {
      botCell = Point(rng.nextInt(config.gridWidth), rng.nextInt(config.gridHeight));
    } while (botCell.distanceTo(startCell) < 4);

    bots = [
      Bot(position: mazeOffset + Offset(
        botCell.x * config.mazeCellSize + (config.mazeCellSize / 2), 
        botCell.y * config.mazeCellSize + (config.mazeCellSize / 2)
      ))
    ];

    cameraOffset = Offset.zero;
    cameraTarget = Offset.zero;
  }

  void _initAudio() async {
    print('[AUDIO] Initializing audio players...');
    
    // CRITICAL: Set loop modes BEFORE playing
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _footstepsPlayer.setReleaseMode(ReleaseMode.loop);
    await _heartbeatPlayer.setReleaseMode(ReleaseMode.loop);
    await _tensionPlayer.setReleaseMode(ReleaseMode.loop);
    
    // Set initial volumes
    await _bgmPlayer.setVolume(1.0);
    await _footstepsPlayer.setVolume(0.6);
    await _heartbeatPlayer.setVolume(0.0); // Start silent
    await _tensionPlayer.setVolume(0.0); // Start silent
    
    // Start BGM - this should NEVER be stopped by footsteps
    await _bgmPlayer.play(AssetSource('audio/game_ambience.ogg'));
    print('[AUDIO] BGM started playing in loop mode');
  }

  Future<void> _loadBestTime() async {
    final prefs = await SharedPreferences.getInstance();
    bestTimeMilliseconds = prefs.getInt('best_time');
  }

  Future<void> _saveBestTime(int timeMs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('best_time', timeMs);
    bestTimeMilliseconds = timeMs;
  }

  void update(double dt) {
    if (isGameOver || isGameWon) {
      _updateAudio(dt);
      return;
    }

    elapsedMilliseconds += (dt * 1000).round();

    // === PLAYER MOVEMENT ===
    Offset targetVelocity = velocity.distance > 0.1 
        ? Offset(velocity.dx, velocity.dy) * maxSpeed 
        : Offset.zero;

    _actualVelocity = _approachVelocity(
      _actualVelocity, 
      targetVelocity, 
      targetVelocity.distance > _actualVelocity.distance ? acceleration : friction, 
      dt
    );

    Offset newPos = playerPos + _actualVelocity * dt;
    if (!_checkCollision(newPos)) {
      playerPos = newPos;
    } else {
      Offset fallbackX = Offset(playerPos.dx + _actualVelocity.dx * dt, playerPos.dy);
      Offset fallbackY = Offset(playerPos.dx, playerPos.dy + _actualVelocity.dy * dt);
      
      if (!_checkCollision(fallbackX)) playerPos = fallbackX;
      else if (!_checkCollision(fallbackY)) playerPos = fallbackY;
    }

    // === CAMERA FOLLOW ===
    cameraTarget = playerPos - Offset(displayWidth / 2, displayHeight / 2);
    cameraOffset = Offset(
      cameraOffset.dx + (cameraTarget.dx - cameraOffset.dx) * cameraLag,
      cameraOffset.dy + (cameraTarget.dy - cameraOffset.dy) * cameraLag,
    );

    // === ECHO WAVES ===
    for (var wave in waves) {
      wave.radius += 300.0 * dt;
      wave.opacity = 1.0 - (wave.radius / wave.maxRadius).clamp(0.0, 1.0);
    }
    waves.removeWhere((w) => w.opacity <= 0);

    // === WALL REVEAL ===
    Set<int> newHitWalls = {};
    for (var wave in waves) {
      for (int wallIdx = 0; wallIdx < walls.length; wallIdx++) {
        var wall = walls[wallIdx];
        for (int i = 0; i < wall.length - 1; i++) {
          double dist = _distToSegment(wave.center, wall[i], wall[i + 1]);
          if ((dist - wave.radius).abs() < 15.0 && wave.opacity > 0.1) {
            newHitWalls.add(wallIdx);
          }
        }
      }
    }

    for (int idx in newHitWalls) {
      wallRevealTimers[idx] = 1.0;
    }
    currentlyHitWalls = newHitWalls;

    List<int> toRemove = [];
    wallRevealTimers.forEach((idx, timer) {
      double newTimer = timer - (currentlyHitWalls.contains(idx) ? dt * 0.2 : dt * 0.8);
      if (newTimer <= 0) {
        toRemove.add(idx);
      } else {
        wallRevealTimers[idx] = newTimer;
      }
    });
    for (int idx in toRemove) {
      wallRevealTimers.remove(idx);
    }

    // === BOT AI ===
    for (var bot in bots) {
      _updateBot(bot, dt);
    }

    // === COLLISION DETECTION ===
    for (var bot in bots) {
      if ((bot.position - playerPos).distance < 15.0 && !isCaught) {
        isCaught = true;
        caughtTimer = 1.2;
        _jumpscarePlayer.play(AssetSource('audio/jumpscare.ogg'));
        print('[GAME] Player caught! Jumpscare triggered.');
      }
    }

    if (isCaught) {
      caughtTimer -= dt;
      if (caughtTimer <= 0) {
        isGameOver = true;
        _bgmPlayer.stop();
        _heartbeatPlayer.stop();
        _footstepsPlayer.stop();
        _tensionPlayer.stop();
        _sfxPlayer.play(AssetSource('audio/death_scream.ogg'));
      }
    }

    // === VICTORY ===
    if ((playerPos - exitPos).distance < exitRadius) {
      isGameWon = true;
      _bgmPlayer.stop();
      _heartbeatPlayer.stop();
      _footstepsPlayer.stop();
      _tensionPlayer.stop();
      _sfxPlayer.play(AssetSource('audio/victory.ogg'));

      if (bestTimeMilliseconds == null || elapsedMilliseconds < bestTimeMilliseconds!) {
        _saveBestTime(elapsedMilliseconds);
      }
    }

    // === AUDIO UPDATE ===
    _updateAudio(dt);

    notifyListeners();
  }

  Offset _approachVelocity(Offset current, Offset target, double rate, double dt) {
    Offset delta = target - current;
    double distance = delta.distance;
    
    if (distance < 1.0) return target;
    
    double step = rate * dt;
    if (step >= distance) return target;
    
    return current + (delta / distance) * step;
  }

  void _updateAudio(double dt) {
    bool isMoving = _actualVelocity.distance > 5.0;
    
    // FOOTSTEPS LAYER - never touches BGM
    if (isMoving && !_isFootstepsPlaying && !isGameOver && !isGameWon) {
      _footstepsPlayer.play(AssetSource('audio/footsteps.ogg'));
      _isFootstepsPlaying = true;
      print('[AUDIO] Started footsteps loop');
    } else if (!isMoving && _isFootstepsPlaying) {
      _footstepsPlayer.stop();
      _isFootstepsPlaying = false;
      print('[AUDIO] Stopped footsteps loop');
    }

    // THREAT DETECTION
    double minBotDist = double.infinity;
    bool anyChasing = false;
    
    for (var bot in bots) {
      double dist = (bot.position - playerPos).distance;
      if (dist < minBotDist) minBotDist = dist;
      if (bot.state == BotState.chasing) anyChasing = true;
    }

    // HEARTBEAT & TENSION LAYERS
    double targetHeartbeatVol = 0.0;
    double targetTensionVol = 0.0;
    double targetBgmVol = 1.0;

    if (anyChasing) {
      // In chase: heartbeat dominant, BGM ducked
      double intensity = (1.0 - (minBotDist / 300.0)).clamp(0.0, 1.0);
      targetHeartbeatVol = 0.7 + (intensity * 0.3); // 0.7 to 1.0
      targetTensionVol = 0.5 + (intensity * 0.5);   // 0.5 to 1.0
      targetBgmVol = 0.2; // Duck BGM during chase
      
      // Visual pulse
      _pulseTimer += dt * (3.0 + intensity * 5.0);
      visualPulseIntensity = (sin(_pulseTimer) + 1.0) / 2.0;
      visualPulseIntensity *= intensity;
      
    } else if (minBotDist < 200.0) {
      // Proximity warning
      double intensity = (1.0 - (minBotDist / 200.0)).clamp(0.0, 1.0);
      targetHeartbeatVol = intensity * 0.5;
      targetTensionVol = intensity * 0.3;
      targetBgmVol = 0.6; // Slight duck
      
      visualPulseIntensity *= 0.95; // Fade pulse when not in chase
    } else {
      visualPulseIntensity = 0.0;
      _pulseTimer = 0.0;
    }

    // SMOOTH VOLUME TRANSITIONS
    double volumeSpeed = 2.0;
    _currentHeartbeatVolume += (targetHeartbeatVol - _currentHeartbeatVolume) * volumeSpeed * dt;
    _currentTensionVolume += (targetTensionVol - _currentTensionVolume) * volumeSpeed * dt;
    _currentBgmVolume += (targetBgmVol - _currentBgmVolume) * volumeSpeed * dt;

    // Apply volumes
    _heartbeatPlayer.setVolume(_currentHeartbeatVolume.clamp(0.0, 1.0));
    _tensionPlayer.setVolume(_currentTensionVolume.clamp(0.0, 1.0));
    _bgmPlayer.setVolume(_currentBgmVolume.clamp(0.0, 1.0));

    // Start/stop heartbeat loop
    if (targetHeartbeatVol > 0.01 && !_isHeartbeatPlaying) {
      _heartbeatPlayer.play(AssetSource('audio/heartbeat.ogg'));
      _isHeartbeatPlaying = true;
      print('[AUDIO] Started heartbeat loop');
    } else if (targetHeartbeatVol <= 0.01 && _isHeartbeatPlaying) {
      _heartbeatPlayer.stop();
      _isHeartbeatPlaying = false;
      print('[AUDIO] Stopped heartbeat loop');
    }

    // Start/stop tension loop
    if (targetTensionVol > 0.01 && !_isTensionPlaying) {
      _tensionPlayer.play(AssetSource('audio/tension.ogg'));
      _isTensionPlaying = true;
      print('[AUDIO] Started tension loop');
    } else if (targetTensionVol <= 0.01 && _isTensionPlaying) {
      _tensionPlayer.stop();
      _isTensionPlaying = false;
      print('[AUDIO] Stopped tension loop');
    }

    // PANIC VISUAL LAYER
    bool inDeadEnd = _isPlayerInDeadEnd();
    double targetPanic = (anyChasing && inDeadEnd) ? 0.6 : 0.0;
    panicIntensity += (targetPanic - panicIntensity) * 3.0 * dt;
  }

  void _updateBot(Bot bot, double dt) {
    // === VISION CHECK ===
    bool canSeePlayer = false;
    double distToPlayer = (bot.position - playerPos).distance;
    
    if (distToPlayer < 150.0) {
      Offset dirToPlayer = playerPos - bot.position;
      double angleToPlayer = atan2(dirToPlayer.dy, dirToPlayer.dx);
      double angleDiff = (angleToPlayer - bot.facingAngle).abs();
      
      while (angleDiff > pi) angleDiff -= 2 * pi;
      angleDiff = angleDiff.abs();
      
      if (angleDiff < pi / 3 && _hasLineOfSight(bot.position, playerPos)) {
        canSeePlayer = true;
      }
    }

    // === HEARING CHECK ===
    for (var wave in waves) {
      double waveDistToBot = (wave.center - bot.position).distance;
      if (waveDistToBot < config.hearingRadius) {
        double strength = 1.0 - (waveDistToBot / config.hearingRadius);
        if (strength > bot.lastHeardStrength) {
          bot.lastHeardStrength = strength;
          bot.lastHeardPosition = wave.center;
        }
      }
    }

    // === STATE MACHINE ===
    // CRITICAL: Vision overrides all other states
    if (canSeePlayer && bot.state != BotState.chasing) {
      bot.state = BotState.chasing;
      bot.lastSeenPosition = playerPos;
      bot.currentPath.clear();
      print('[BOT] Visual contact! Entering CHASING state');
    }

    switch (bot.state) {
      case BotState.idle:
        // Check if we heard something strong enough
        if (bot.lastHeardStrength > bot.hearingThreshold) {
          bot.state = BotState.investigating;
          bot.stateTimer = 0.0;
          bot.currentPath.clear();
          print('[BOT] Sound detected (strength: ${bot.lastHeardStrength}), switching to INVESTIGATING');
          print('[BOT] Target position: ${bot.lastHeardPosition}');
        }
        
        bot.lastHeardStrength *= 0.95;
        break;

      case BotState.investigating:
        if (bot.lastHeardPosition != null) {
          Offset beforePos = bot.position;
          
          // CRITICAL FIX: This is where bot movement happens
          _moveBotWithPathfinding(bot, bot.lastHeardPosition!, dt, 1.0);
          
          Offset afterPos = bot.position;
          
          // Reduced debug logging - only when position actually changes
          if ((afterPos - beforePos).distance > 0.1) {
            print('[BOT] Investigating - Moved ${(afterPos - beforePos).distance.toStringAsFixed(2)} units toward ${bot.lastHeardPosition}');
          }
          
          // Check if reached target
          if ((bot.position - bot.lastHeardPosition!).distance < 10.0) {
            bot.state = BotState.searching;
            bot.stateTimer = config.searchDuration; 
            bot.lastSeenPosition = bot.lastHeardPosition; 
            bot.currentWaypoint = _getRandomNearbyPosition(bot.position, 60.0);
            bot.lastHeardStrength = 0.0;
            bot.currentPath.clear();
            print('[BOT] Reached investigation target, switching to SEARCHING');
          }
        } else {
          bot.state = BotState.idle;
          print('[BOT] No target, returning to IDLE');
        }
        break;

      case BotState.chasing:
        if (canSeePlayer) {
          _moveBotWithPathfinding(bot, playerPos, dt, 1.4);
        } else {
          // Lost sight - move to last known position
          if (bot.lastSeenPosition != null) {
            _moveBotWithPathfinding(bot, bot.lastSeenPosition!, dt, 1.4);
            
            if ((bot.position - bot.lastSeenPosition!).distance < 10.0) {
              bot.state = BotState.searching;
              bot.stateTimer = config.searchDuration; 
              bot.currentWaypoint = _getRandomNearbyPosition(bot.position, 80.0);
              bot.currentPath.clear();
              print('[BOT] Lost target, entering SEARCHING mode');
            }
          }
        }
        break;

      case BotState.searching:
        bot.stateTimer -= dt;
        if (bot.currentWaypoint != null) {
          _moveBotWithPathfinding(bot, bot.currentWaypoint!, dt, 0.6);
          
          if ((bot.position - bot.currentWaypoint!).distance < 10.0) {
            if (bot.lastSeenPosition != null) {
               bot.currentWaypoint = _getRandomNearbyPosition(bot.lastSeenPosition!, 80.0);
               bot.currentPath.clear();
            }
          }
        }
        
        if (bot.stateTimer <= 0) {
          bot.state = BotState.cooldown;
          bot.stateTimer = 3.0; 
          bot.lastSeenPosition = null;
          bot.currentWaypoint = null;
          bot.currentPath.clear();
          print('[BOT] Search complete, entering COOLDOWN');
        }
        break;

      case BotState.cooldown:
        bot.stateTimer -= dt;
        if (bot.stateTimer <= 0) {
          bot.state = BotState.idle;
          print('[BOT] Cooldown complete, returning to IDLE');
        }
        break;
    }
  }

  bool _isPlayerInDeadEnd() {
    int openDirections = 0;
    double checkDist = config.mazeCellSize;
    
    List<Offset> directions = [
      Offset(checkDist, 0),
      Offset(-checkDist, 0),
      Offset(0, checkDist),
      Offset(0, -checkDist),
    ];
    
    for (var dir in directions) {
      if (!_checkCollision(playerPos + dir)) {
        openDirections++;
      }
    }
    
    return openDirections <= 1;
  }

  void _moveBotWithPathfinding(Bot bot, Offset destination, double dt, double stateSpeedMultiplier) {
    Point<int> botCell = _offsetToCell(bot.position);
    Point<int> targetCell = _offsetToCell(destination);

    // Generate path if needed
    if (bot.currentPath.isEmpty || bot.currentPathIndex >= bot.currentPath.length) {
      bot.currentPath = mazeGenerator.findPath(botCell, targetCell);
      bot.currentPathIndex = 0;
      
      if (bot.currentPath.isEmpty) {
        print('[BOT] WARNING: No path found from $botCell to $targetCell');
        return;
      }
    }

    // CRITICAL FIX: Execute movement every frame if path exists
    if (bot.currentPath.isNotEmpty && bot.currentPathIndex < bot.currentPath.length) {
      Point<int> nextCell = bot.currentPath[bot.currentPathIndex];
      Offset nextWaypoint = _cellToOffset(nextCell);

      Offset dir = nextWaypoint - bot.position;
      double distance = dir.distance;
      
      if (distance < config.mazeCellSize * 0.3) {
        // Reached waypoint, advance to next
        bot.currentPathIndex++;
        
        // Only print when advancing waypoints to reduce spam
        if (bot.currentPathIndex < bot.currentPath.length) {
          print('[BOT] Reached waypoint ${bot.currentPathIndex}/${bot.currentPath.length}');
        }
      } else {
        // CRITICAL: Apply movement every frame
        bot.facingAngle = atan2(dir.dy, dir.dx);
        double finalSpeed = bot.baseSpeed * stateSpeedMultiplier * config.botSpeedMultiplier;
        Offset movement = (dir / distance) * (finalSpeed * dt);
        bot.position += movement;
      }
    }
  }

  Point<int> _offsetToCell(Offset pos) {
    int x = ((pos.dx - mazeOffset.dx) / config.mazeCellSize).floor().clamp(0, config.gridWidth - 1);
    int y = ((pos.dy - mazeOffset.dy) / config.mazeCellSize).floor().clamp(0, config.gridHeight - 1);
    return Point(x, y);
  }

  Offset _cellToOffset(Point<int> cell) {
    return mazeOffset + Offset(
      cell.x * config.mazeCellSize + (config.mazeCellSize / 2),
      cell.y * config.mazeCellSize + (config.mazeCellSize / 2),
    );
  }

  Offset _getRandomNearbyPosition(Offset center, double radius) {
    final random = Random();
    double angle = random.nextDouble() * 2 * pi;
    double r = random.nextDouble() * radius;
    return center + Offset(r * cos(angle), r * sin(angle));
  }

  void emitWave() {
    if (!isGameOver && !isGameWon && !isCaught && currentEchoCharges > 0) {
      waves.add(EchoWave(center: playerPos));
      _sfxPlayer.play(AssetSource('audio/ping.ogg')); 
      currentEchoCharges--;
    }
  }

  void resetGame() {
    isGameOver = false;
    isGameWon = false;
    
    isCaught = false;
    caughtTimer = 0.0;
    
    elapsedMilliseconds = 0; 
    waves.clear();
    wallRevealTimers.clear();
    currentlyHitWalls.clear();
    velocity = Offset.zero;
    _actualVelocity = Offset.zero; 
    
    panicIntensity = 0.0;
    visualPulseIntensity = 0.0;
    _pulseTimer = 0.0;
    
    currentEchoCharges = config.maxEchoCharges;

    _generateLevel();
    
    // Reset audio state
    _isFootstepsPlaying = false;
    _isHeartbeatPlaying = false;
    _isTensionPlaying = false;
    _currentHeartbeatVolume = 0.0;
    _currentTensionVolume = 0.0;
    _currentBgmVolume = 1.0;
    
    // Stop all layered audio
    _footstepsPlayer.stop();
    _heartbeatPlayer.stop();
    _breathingPlayer.stop();
    _jumpscarePlayer.stop();
    _tensionPlayer.stop();
    
    // Restart BGM at full volume
    print('[AUDIO] Restarting BGM for new game');
    _bgmPlayer.setVolume(1.0);
    _bgmPlayer.play(AssetSource('audio/game_ambience.ogg'));
    
    notifyListeners();
  }

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

  @override
  void dispose() {
    // Clean up all audio players
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
    _footstepsPlayer.dispose();
    _heartbeatPlayer.dispose();
    _breathingPlayer.dispose();
    _jumpscarePlayer.dispose();
    _tensionPlayer.dispose();
    super.dispose();
  }
}