import 'package:flutter/material.dart';
// ignore: unused_import
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class EchoWave {
  Offset center;
  double radius;
  double opacity;

  EchoWave({required this.center, this.radius = 0.0, this.opacity = 1.0});
}

class Bot {
  Offset position;
  double opacity;
  Offset? target;
  final double speed = 90.0; 

  Bot({
    required this.position,
    this.opacity = 1.0,
  }); // <-- The extra '}' that was breaking your code is gone
}

class GameModel extends ChangeNotifier {
  Offset playerPos = const Offset(50, 50);
  final double playerRadius = 8.0;
  
  bool isGameOver = false;
  bool isGameWon = false;
  
  // Phase 3: Timer Data
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

  // Constructor loads the best time immediately
  GameModel() {
    _loadBestTime();
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

    // Phase 3: Increment Timer
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

    // Phase 2 & 3: Win Detection & Highscore Logic
    if ((playerPos - exitPos).distance < exitRadius) {
      isGameWon = true;
      if (bestTimeMilliseconds == null || elapsedMilliseconds < bestTimeMilliseconds!) {
        bestTimeMilliseconds = elapsedMilliseconds;
        _saveBestTime(); // Save new record to device!
      }
    }

    for (var bot in bots) {
      for (var wave in waves) {
        if ((bot.position - wave.center).distance <= wave.radius) {
          bot.target = wave.center; 
        }
      }

      if (bot.target != null) {
        Offset dir = bot.target! - bot.position;
        if (dir.distance < 5) {
          bot.target = null; 
        } else {
          bot.position += (dir / dir.distance) * (bot.speed * dt);
        }
      }

      if ((bot.position - playerPos).distance < 15) {
        isGameOver = true;
      }
    }

    notifyListeners();
  }

  void emitWave() {
    if (!isGameOver && !isGameWon) waves.add(EchoWave(center: playerPos));
  }

  void resetGame() {
    playerPos = const Offset(50, 50);
    isGameOver = false;
    isGameWon = false;
    elapsedMilliseconds = 0; // Phase 3: Reset clock
    waves.clear();
    velocity = Offset.zero;
    bots = [Bot(position: const Offset(200, 250))];
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