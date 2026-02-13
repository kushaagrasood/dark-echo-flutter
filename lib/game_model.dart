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

enum BotState { idle, investigating, searching, chasing, cooldown }

class Bot {
  Offset position;
  double opacity;
  final double baseSpeed = 90.0; 
  
  BotState state = BotState.idle;
  double stateTimer = 0.0;

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

  Offset velocity = Offset.zero; 
  Offset _actualVelocity = Offset.zero; 
  final double maxSpeed = 150.0;
  final double acceleration = 800.0;
  final double friction = 600.0;

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

  void _updateBotFSM(Bot bot, double dt, double distToPlayer) {
    // Determine if bot has a direct, unbroken line of sight to the player
    bool canSeePlayer = distToPlayer <= 200.0 && _hasLineOfSight(bot.position, playerPos);

    if (canSeePlayer) { 
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
        
        // If the player breaks line of sight or gets out of range
        if (!canSeePlayer) { 
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
    _actualVelocity = Offset.zero; 
    
    bots = [Bot(position: const Offset(200, 250))];
    
    _isFootstepsPlaying = false;
    _isHeartbeatPlaying = false;
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

  // Casts a ray and checks against all walls
  bool _hasLineOfSight(Offset start, Offset end) {
    for (var wall in walls) {
      for (int i = 0; i < wall.length - 1; i++) {
        if (_doIntersect(start, end, wall[i], wall[i + 1])) {
          return false; // Vision is blocked by this wall
        }
      }
    }
    return true; // Vision is clear
  }

  // Evaluates intersection between line segment p1q1 and p2q2
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
    if (val == 0) return 0; // Collinear
    return (val > 0) ? 1 : 2; // Clockwise or Counterclockwise
  }

  bool _onSegment(Offset p, Offset q, Offset r) {
    return q.dx <= max(p.dx, r.dx) && q.dx >= min(p.dx, r.dx) &&
           q.dy <= max(p.dy, r.dy) && q.dy >= min(p.dy, r.dy);
  }
}