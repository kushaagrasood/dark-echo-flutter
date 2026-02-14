import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:collection';

class _WallRef {
  final int x, y;
  final bool isHorizontal;
  _WallRef(this.x, this.y, this.isHorizontal);
}

class MazeGenerator {
  final int gridWidth;
  final int gridHeight;
  final double cellSize;
  final double loopPercentage;
  final Offset startOffset;

  late List<List<bool>> hWalls; // Horizontal walls: [x][y]
  late List<List<bool>> vWalls; // Vertical walls: [x][y]
  
  final Random _rng = Random();

  MazeGenerator({
    this.gridWidth = 10,
    this.gridHeight = 10,
    this.cellSize = 40.0,
    this.loopPercentage = 0.15,
    this.startOffset = const Offset(0, 0),
  }) {
    // Initialize grids with ALL walls closed (true)
    hWalls = List.generate(gridWidth, (_) => List.filled(gridHeight + 1, true));
    vWalls = List.generate(gridWidth + 1, (_) => List.filled(gridHeight, true));
  }

  /// Master generation function
  List<List<Offset>> generate(Point<int> startCell, Point<int> exitCell) {
    _generatePerfectMaze();
    _addLoops();
    _ensureMultiplePaths(startCell, exitCell);
    return _convertToLineSegments();
  }

  // 1. Recursive Backtracking for a perfect maze
  void _generatePerfectMaze() {
    var visited = List.generate(gridWidth, (_) => List.filled(gridHeight, false));
    var stack = <Point<int>>[];
    var current = const Point(0, 0);
    
    visited[current.x][current.y] = true;

    while (true) {
      var neighbors = _getUnvisitedNeighbors(current, visited);
      if (neighbors.isNotEmpty) {
        var next = neighbors[_rng.nextInt(neighbors.length)];
        stack.add(current);
        _removeWallBetween(current, next);
        current = next;
        visited[current.x][current.y] = true;
      } else if (stack.isNotEmpty) {
        current = stack.removeLast();
      } else {
        break; // Maze complete
      }
    }
  }

  // 2. Imperfection Step: Randomly remove internal walls to create loops
  void _addLoops() {
    var internalWalls = _getAllInternalClosedWalls();
    int wallsToRemove = (internalWalls.length * loopPercentage).round();
    
    internalWalls.shuffle(_rng);
    for (int i = 0; i < wallsToRemove && i < internalWalls.length; i++) {
      var w = internalWalls[i];
      if (w.isHorizontal) {
        hWalls[w.x][w.y] = false;
      } else {
        vWalls[w.x][w.y] = false;
      }
    }
  }

  // 3. BFS Validation: Guarantees at least 2 distinct routes
  void _ensureMultiplePaths(Point<int> start, Point<int> end) {
    while (!_hasMultiplePaths(start, end)) {
      var walls = _getAllInternalClosedWalls();
      if (walls.isEmpty) break; // Failsafe
      
      // Knock down another random wall to create a bypass
      var w = walls[_rng.nextInt(walls.length)];
      if (w.isHorizontal) {
        hWalls[w.x][w.y] = false;
      }
      else {
        vWalls[w.x][w.y] = false;
      }
    }
  }

  bool _hasMultiplePaths(Point<int> start, Point<int> end) {
    var path = _bfs(start, end);
    if (path.isEmpty) return false;

    // Test every step in the shortest path. 
    // If blocking ANY step makes the exit unreachable, it's a chokepoint.
    for (int i = 0; i < path.length - 1; i++) {
      var p1 = path[i];
      var p2 = path[i + 1];
      
      _setWallBetween(p1, p2, true); // Temporarily block
      var altPath = _bfs(start, end); // Try to find an alternate route
      _setWallBetween(p1, p2, false); // Restore wall
      
      if (altPath.isEmpty) return false; // Found a chokepoint!
    }
    return true; // No single hallway is a chokepoint. Multiple paths exist!
  }

  List<Point<int>> _bfs(Point<int> start, Point<int> end) {
    var queue = Queue<List<Point<int>>>();
    var visited = List.generate(gridWidth, (_) => List.filled(gridHeight, false));

    queue.add([start]);
    visited[start.x][start.y] = true;

    while (queue.isNotEmpty) {
      var path = queue.removeFirst();
      var current = path.last;

      if (current == end) return path;

      for (var neighbor in _getReachableNeighbors(current)) {
        if (!visited[neighbor.x][neighbor.y]) {
          visited[neighbor.x][neighbor.y] = true;
          queue.add(List.from(path)..add(neighbor));
        }
      }
    }
    return [];
  }

  /// Public pathfinding method for bot navigation
  List<Point<int>> findPath(Point<int> start, Point<int> end) {
    return _bfs(start, end);
  }

  // --- Helpers ---

  List<Point<int>> _getUnvisitedNeighbors(Point<int> cell, List<List<bool>> visited) {
    var neighbors = <Point<int>>[];
    if (cell.y > 0 && !visited[cell.x][cell.y - 1]) neighbors.add(Point(cell.x, cell.y - 1)); // Top
    if (cell.x < gridWidth - 1 && !visited[cell.x + 1][cell.y]) neighbors.add(Point(cell.x + 1, cell.y)); // Right
    if (cell.y < gridHeight - 1 && !visited[cell.x][cell.y + 1]) neighbors.add(Point(cell.x, cell.y + 1)); // Bottom
    if (cell.x > 0 && !visited[cell.x - 1][cell.y]) neighbors.add(Point(cell.x - 1, cell.y)); // Left
    return neighbors;
  }

  List<Point<int>> _getReachableNeighbors(Point<int> cell) {
    var neighbors = <Point<int>>[];
    if (cell.y > 0 && !hWalls[cell.x][cell.y]) neighbors.add(Point(cell.x, cell.y - 1)); // Top
    if (cell.x < gridWidth - 1 && !vWalls[cell.x + 1][cell.y]) neighbors.add(Point(cell.x + 1, cell.y)); // Right
    if (cell.y < gridHeight - 1 && !hWalls[cell.x][cell.y + 1]) neighbors.add(Point(cell.x, cell.y + 1)); // Bottom
    if (cell.x > 0 && !vWalls[cell.x][cell.y]) neighbors.add(Point(cell.x - 1, cell.y)); // Left
    return neighbors;
  }

  void _removeWallBetween(Point<int> a, Point<int> b) => _setWallBetween(a, b, false);

  void _setWallBetween(Point<int> a, Point<int> b, bool state) {
    if (a.x == b.x) {
      hWalls[a.x][min(a.y, b.y) + 1] = state; // Vertical neighbors share a horizontal wall
    } else {
      vWalls[min(a.x, b.x) + 1][a.y] = state; // Horizontal neighbors share a vertical wall
    }
  }

  List<_WallRef> _getAllInternalClosedWalls() {
    var walls = <_WallRef>[];
    for (int x = 0; x < gridWidth; x++) {
      for (int y = 1; y < gridHeight; y++) {
        if (hWalls[x][y]) walls.add(_WallRef(x, y, true));
      }
    }
    for (int x = 1; x < gridWidth; x++) {
      for (int y = 0; y < gridHeight; y++) {
        if (vWalls[x][y]) walls.add(_WallRef(x, y, false));
      }
    }
    return walls;
  }

  List<List<Offset>> _convertToLineSegments() {
    var segments = <List<Offset>>[];
    for (int x = 0; x < gridWidth; x++) {
      for (int y = 0; y <= gridHeight; y++) {
        if (hWalls[x][y]) {
          segments.add([
            startOffset + Offset(x * cellSize, y * cellSize),
            startOffset + Offset((x + 1) * cellSize, y * cellSize),
          ]);
        }
      }
    }
    for (int x = 0; x <= gridWidth; x++) {
      for (int y = 0; y < gridHeight; y++) {
        if (vWalls[x][y]) {
          segments.add([
            startOffset + Offset(x * cellSize, y * cellSize),
            startOffset + Offset(x * cellSize, (y + 1) * cellSize),
          ]);
        }
      }
    }
    return segments;
  }
}