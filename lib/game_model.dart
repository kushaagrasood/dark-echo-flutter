import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class EchoWave {
  Offset center;
  double radius;
  double opacity;

  EchoWave({required this.center, this.radius = 0.0, this.opacity = 1.0});
}

// 1. Define the FSM States
enum BotState { idle, investigating, searching, chasing, cooldown }

class Bot {
  Offset position;
  double opacity;
  final double baseSpeed = 90.0; 
  
  // FSM Variables
  BotState state = BotState.idle;
  double stateTimer = 0.0;

  // Advanced Hearing Mechanics
  Offset? lastHeardPosition;
  double lastHeardStrength = 0.0;
  final double hearingThreshold = 0.15; // Ignore waves weaker than this

  Bot({
    required this.position,
    this.opacity = 1.0,
  }); 
}
class GameModel extends ChangeNotifier {
  Offset playerPos = const Offset(50, 50);
  final double playerRadius = 8.0;
  
  bool isGameOver = false;
  bool isGameWon = false;
  
  int elapsedMilliseconds = 0;
  int? bestTimeMilliseconds;
  
  Offset exitPos = const Offset(350, 450); 
  final double exitRadius = 20.0;

  List<List<Offset>> walls = [
    [const Offset(100, 100), const Offset(300, 100)],
    [const Offset(300, 100), const Offset(300, 400)],
    [const Offset(100, 400), const Offset(100, 100)]
  ];

  List<EchoWave> waves = [];
  Offset velocity = Offset.zero;
  List<Bot> bots = [Bot(position: const Offset(200, 250))];

  // --- AUDIO ENGINE ---
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _footstepsPlayer = AudioPlayer();
  final AudioPlayer _heartbeatPlayer = AudioPlayer(); 
  final AudioPlayer _jumpscarePlayer = AudioPlayer();
  
  bool _isFootstepsPlaying = false;
  bool _isHeartbeatPlaying = false;

  GameModel() {
    _loadBestTime();
    _initAudio();
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

    elapsedMilliseconds += (dt * 1000).toInt();

    for (int i = waves.length - 1; i >= 0; i--) {
      waves[i].radius += 150 * dt;
      waves[i].opacity -= 0.5 * dt;
      if (waves[i].opacity <= 0) waves.removeAt(i);
    }

    double speed = 150 * dt;
    Offset moveX = Offset(velocity.dx * speed, 0);
    Offset moveY = Offset(0, velocity.dy * speed);

    Offset newPosX = playerPos + moveX;
    if (!_checkCollision(newPosX)) playerPos = newPosX;

    Offset newPosY = playerPos + moveY;
    if (!_checkCollision(newPosY)) playerPos = newPosY;

    // --- PROXIMITY AUDIO LOGIC ---
    double botDist = (bots[0].position - playerPos).distance;
    
    // Footsteps
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

    // Heartbeat
    double heartbeatThreshold = 150.0;
    if (botDist < heartbeatThreshold) {
      if (!_isHeartbeatPlaying) {
        _heartbeatPlayer.play(AssetSource('audio/heartbeat.ogg'));
        _isHeartbeatPlaying = true;
      }
      double hbVol = 1.0 - (botDist / heartbeatThreshold);
      _heartbeatPlayer.setVolume(hbVol.clamp(0.0, 1.0));
      double hbRate = 1.0 + (1.5 * (1.0 - (botDist / heartbeatThreshold)));
      _heartbeatPlayer.setPlaybackRate(hbRate.clamp(1.0, 2.5));
    } else {
      if (_isHeartbeatPlaying) {
        _heartbeatPlayer.pause();
        _isHeartbeatPlaying = false;
      }
    }

    // --- WIN STATE ---
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

    // --- BOT AI & LOSS STATE ---
    for (var bot in bots) {
      _updateBotFSM(bot, dt, botDist);

      if (botDist < 15) {
        if (!isGameOver) {
          isGameOver = true;
          _bgmPlayer.stop();
          _footstepsPlayer.stop();
          _heartbeatPlayer.stop();
          _jumpscarePlayer.play(AssetSource('audio/caught(fnaf).ogg'));
        }
      }
    }

    notifyListeners();
  }

  // --- FINITE STATE MACHINE LOGIC ---
  void _updateBotFSM(Bot bot, double dt, double distToPlayer) {
    // 1. Global High-Priority Override: Proximity
    if (distToPlayer < 75.0) { 
      bot.state = BotState.chasing;
    }

    bool heardNewSound = false;
    double strongestCurrentWave = 0.0;
    Offset? strongestWavePos;

    // 2. Advanced Hearing Evaluation (Performance Safe O(W) loop)
    for (var wave in waves) {
      double distToWaveCenter = (bot.position - wave.center).distance;
      
      // The wave ring must have physically expanded far enough to reach the bot
      if (wave.radius >= distToWaveCenter) {
        
        // Intensity = Opacity (fade over time) * Distance Attenuation
        // Sounds further than 400 pixels are naturally muffled
        double distanceFactor = 1.0 - (distToWaveCenter / 400.0).clamp(0.0, 1.0);
        double intensity = wave.opacity * distanceFactor;

        // Only process waves that break the threshold and are the loudest currently happening
        if (intensity > bot.hearingThreshold && intensity > strongestCurrentWave) {
          strongestCurrentWave = intensity;
          strongestWavePos = wave.center;
        }
      }
    }

    // 3. Memory & Distraction Logic
    // If the new sound is louder than the decaying memory of the last sound, investigate it!
    if (strongestWavePos != null && strongestCurrentWave >= bot.lastHeardStrength) {
      bot.lastHeardPosition = strongestWavePos;
      bot.lastHeardStrength = strongestCurrentWave;
      heardNewSound = true;
    }

    // Decay the memory of the sound strength so the bot can be distracted by new, slightly weaker sounds later
    if (bot.lastHeardStrength > 0) {
      bot.lastHeardStrength -= 0.1 * dt; 
    }

    // Trigger state change if a valid sound was heard
    if (heardNewSound && bot.state != BotState.chasing) {
      bot.state = BotState.investigating;
    }

    // 4. State Specific Behaviors
    switch (bot.state) {
      case BotState.idle:
        // Stands still, waiting for input
        break;

      case BotState.investigating:
        if (bot.lastHeardPosition != null) {
          _moveBot(bot, bot.lastHeardPosition!, dt, 1.0); // Standard speed
          
          if ((bot.position - bot.lastHeardPosition!).distance < 5.0) {
            // Reached the exact origin of the sound, begin searching area
            bot.state = BotState.searching;
            bot.stateTimer = 4.0; // Search for 4 seconds
            bot.lastHeardPosition = _getRandomNearbyPosition(bot.position, 60.0);
            bot.lastHeardStrength = 0.0; // Clear memory of the sound once investigated
          }
        } else {
          bot.state = BotState.idle;
        }
        break;

      case BotState.searching:
        bot.stateTimer -= dt;
        if (bot.lastHeardPosition != null) {
          _moveBot(bot, bot.lastHeardPosition!, dt, 0.6); // Move slower, "scanning"
          
          if ((bot.position - bot.lastHeardPosition!).distance < 5.0) {
            // Reached the search waypoint, pick a new random one
            bot.lastHeardPosition = _getRandomNearbyPosition(bot.position, 60.0);
          }
        }
        
        if (bot.stateTimer <= 0) {
          bot.state = BotState.cooldown;
          bot.stateTimer = 2.0; // Rest for 2 seconds before returning to idle
          bot.lastHeardPosition = null;
        }
        break;

      case BotState.chasing:
        bot.lastHeardPosition = playerPos;
        _moveBot(bot, playerPos, dt, 1.4); // Sprint faster than normal
        
        if (distToPlayer > 120.0) { 
          // Player managed to break direct line of sight/proximity
          bot.state = BotState.cooldown;
          bot.stateTimer = 3.0;
          bot.lastHeardPosition = null;
          bot.lastHeardStrength = 0.0;
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

  // AI Helper: Vector Movement
  void _moveBot(Bot bot, Offset destination, double dt, double speedMultiplier) {
    Offset dir = destination - bot.position;
    if (dir.distance > 0) {
      bot.position += (dir / dir.distance) * (bot.baseSpeed * speedMultiplier * dt);
    }
  }

  // AI Helper: Random Waypoint Generation
  Offset _getRandomNearbyPosition(Offset center, double radius) {
    final random = Random();
    double angle = random.nextDouble() * 2 * pi;
    double r = random.nextDouble() * radius;
    return center + Offset(r * cos(angle), r * sin(angle));
  }

  void emitWave() {
    if (!isGameOver && !isGameWon) {
      waves.add(EchoWave(center: playerPos));
      _sfxPlayer.play(AssetSource('audio/ping.ogg')); 
    }
  }

  void resetGame() {
    playerPos = const Offset(50, 50);
    isGameOver = false;
    isGameWon = false;
    elapsedMilliseconds = 0; 
    waves.clear();
    velocity = Offset.zero;
    
    // Reset Bot FSM
    bots = [Bot(position: const Offset(200, 250))];
    
    _isFootstepsPlaying = false;
    _isHeartbeatPlaying = false;
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
}