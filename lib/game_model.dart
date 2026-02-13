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

// FSM States
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
  final double hearingThreshold = 0.15; 

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
  List<Bot> bots = [Bot(position: const Offset(200, 250))];

  // --- PHYSICS ENGINE VARIABLES ---
  Offset velocity = Offset.zero; // This receives Joystick Input (-1.0 to 1.0) from GamePage
  Offset _actualVelocity = Offset.zero; // Internal physics velocity
  final double maxSpeed = 150.0;
  final double acceleration = 800.0;
  final double friction = 600.0;

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

    // 1. Update Waves
    for (int i = waves.length - 1; i >= 0; i--) {
      waves[i].radius += 150 * dt;
      waves[i].opacity -= 0.5 * dt;
      if (waves[i].opacity <= 0) waves.removeAt(i);
    }

    // 2. --- PLAYER PHYSICS & MOMENTUM ---
    if (velocity != Offset.zero) {
      // Apply Acceleration based on joystick input direction
      _actualVelocity += velocity * acceleration * dt;
      
      // Clamp to max speed
      if (_actualVelocity.distance > maxSpeed) {
        _actualVelocity = (_actualVelocity / _actualVelocity.distance) * maxSpeed;
      }
    } else {
      // Apply Friction when joystick is released
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

    // 3. --- DISCRETE AXIS RESOLUTION (Sliding & Jitter Prevention) ---
    Offset moveX = Offset(_actualVelocity.dx * dt, 0);
    Offset newPosX = playerPos + moveX;
    if (!_checkCollision(newPosX)) {
      playerPos = newPosX;
    } else {
      _actualVelocity = Offset(0, _actualVelocity.dy); // Kill X-momentum on impact
    }

    Offset moveY = Offset(0, _actualVelocity.dy * dt);
    Offset newPosY = playerPos + moveY;
    if (!_checkCollision(newPosY)) {
      playerPos = newPosY;
    } else {
      _actualVelocity = Offset(_actualVelocity.dx, 0); // Kill Y-momentum on impact
    }

    // 4. --- PROXIMITY AUDIO LOGIC ---
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

    // 5. --- WIN STATE ---
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

    // 6. --- BOT AI & LOSS STATE ---
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
    if (distToPlayer < 75.0) { 
      bot.state = BotState.chasing;
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

    if (heardNewSound && bot.state != BotState.chasing) {
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
            bot.lastHeardPosition = _getRandomNearbyPosition(bot.position, 60.0);
            bot.lastHeardStrength = 0.0; 
          }
        } else {
          bot.state = BotState.idle;
        }
        break;

      case BotState.searching:
        bot.stateTimer -= dt;
        if (bot.lastHeardPosition != null) {
          _moveBot(bot, bot.lastHeardPosition!, dt, 0.6); 
          
          if ((bot.position - bot.lastHeardPosition!).distance < 5.0) {
            bot.lastHeardPosition = _getRandomNearbyPosition(bot.position, 60.0);
          }
        }
        
        if (bot.stateTimer <= 0) {
          bot.state = BotState.cooldown;
          bot.stateTimer = 2.0; 
          bot.lastHeardPosition = null;
        }
        break;

      case BotState.chasing:
        bot.lastHeardPosition = playerPos;
        _moveBot(bot, playerPos, dt, 1.4); 
        
        if (distToPlayer > 120.0) { 
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

  void _moveBot(Bot bot, Offset destination, double dt, double speedMultiplier) {
    Offset dir = destination - bot.position;
    if (dir.distance > 0) {
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
    _actualVelocity = Offset.zero; // Reset physics
    
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