import 'package:flutter/material.dart';
import 'dart:math';

class EchoWave {
  Offset center;
  double radius;
  double opacity;

  EchoWave({required this.center, this.radius = 0.0, this.opacity = 1.0});
}

class GameModel extends ChangeNotifier  {
  Offset playerPos = Offset(50,50);
  final double playerRadius = 8.0;

  // List of walls, where each wall is a list of points (segments)
  List<List<Offset>> walls = [
    [Offset(100,100), Offset(300,100)],
    [Offset(300,100), Offset(300,400)],
    [Offset(100,400), Offset(100,100)]
  ];

  List<EchoWave> waves = [];
  Offset velocity = Offset.zero;
  
  void update(double dt) {
    // 1. Update Waves
    for (int i = waves.length - 1; i >= 0; i--) {
      waves[i].radius += 150 * dt; // Expansion speed
      waves[i].opacity -= 0.5 * dt; // Fade speed
      if(waves[i].opacity <= 0) {
        waves.removeAt(i);
      }
    }

    // 2. Update Player Position with Sliding Collision
    double speed = 150 * dt;
    Offset moveX = Offset(velocity.dx * speed, 0);
    Offset moveY = Offset(0, velocity.dy * speed);

    // Try moving along the X axis first
    Offset newPosX = playerPos + moveX;
    if (!_checkCollision(newPosX)) {
      playerPos = newPosX;
    }

    // Try moving along the Y axis second
    Offset newPosY = playerPos + moveY;
    if (!_checkCollision(newPosY)) {
      playerPos = newPosY;
    }

    notifyListeners();
  }

  void emitWave() {
    waves.add(EchoWave(center: playerPos));
  }

  bool _checkCollision(Offset pos) {
    for(var wall in walls) {
      for(int i = 0; i< wall.length - 1; i++) {
        if(_distToSegment(pos,wall[i], wall[i+1]) < playerRadius) {
          return true;
        }
      }
    }
    return false;
  }

  // Helper math: Distance from point to line segment
  double _distToSegment(Offset p, Offset v, Offset w) {
    double l2 = (v - w).distanceSquared;
    if(l2 == 0) return (p - v).distance;
    double t = ((p.dx - v.dx) * (w.dx - v.dx) + (p.dy - v.dy) * (w.dy - v.dy)) /l2;
    t = max(0, min(1,t));
    return (p - Offset(v.dx + t * (w.dx - v.dx), v.dy + t * (w.dy - v.dy))).distance;
  }
}