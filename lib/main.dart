import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const BreakoutApp());
}

class BreakoutApp extends StatelessWidget {
  const BreakoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Breakout Game',
      theme: ThemeData.dark(),
      home: const BreakoutGame(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BreakoutGame extends StatefulWidget {
  const BreakoutGame({super.key});

  @override
  State<BreakoutGame> createState() => _BreakoutGameState();
}

class _BreakoutGameState extends State<BreakoutGame>
    with TickerProviderStateMixin {
  late AnimationController _gameController;

  // Game state
  bool gameStarted = false;
  bool gameOver = false;
  int score = 0;
  int lives = 3;

  // Game objects
  Offset ballPosition = const Offset(200, 600);
  Offset ballVelocity = const Offset(0, 0);
  double paddleX = 100;
  List<List<bool>> bricks = [];

  // Game dimensions
  static const double ballRadius = 8.0;
  static const double paddleWidth = 80.0;
  static const double paddleHeight = 12.0;
  static const double brickWidth = 60.0;
  static const double brickHeight = 20.0;
  static const int brickRows = 6;
  static const int brickCols = 6;
  static const double ballSpeed = 350.0;

  Size gameSize = const Size(400, 800);

  @override
  void initState() {
    super.initState();
    _gameController = AnimationController(
      duration: const Duration(milliseconds: 16), // ~60 FPS
      vsync: this,
    )..addListener(_updateGame);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _initializeGame();
      });
      _startGameLoop();
    });
  }

  void _initializeGame() {
    gameSize = MediaQuery.of(context).size;
    paddleX = gameSize.width / 2 - paddleWidth / 2;
    // Position ball on top center of paddle
    ballPosition = Offset(
      paddleX + paddleWidth / 2,
      gameSize.height - 60 - ballRadius - 2,
    );
    ballVelocity = const Offset(0, 0);

    // Initialize bricks
    bricks = List.generate(
      brickRows,
      (row) => List.generate(brickCols, (col) => true),
    );
  }

  void _startGameLoop() {
    _gameController.repeat();
  }

  void _updateGame() {
    if (!gameStarted || gameOver) return;

    setState(() {
      // Update ball position
      ballPosition = Offset(
        ballPosition.dx + ballVelocity.dx * 0.016,
        ballPosition.dy + ballVelocity.dy * 0.016,
      );

      // Ball collision with walls
      if (ballPosition.dx <= ballRadius ||
          ballPosition.dx >= gameSize.width - ballRadius) {
        ballVelocity = Offset(-ballVelocity.dx, ballVelocity.dy);
        ballPosition = Offset(
          ballPosition.dx <= ballRadius
              ? ballRadius
              : gameSize.width - ballRadius,
          ballPosition.dy,
        );
      }

      // Ball collision with top
      if (ballPosition.dy <= ballRadius) {
        ballVelocity = Offset(ballVelocity.dx, -ballVelocity.dy);
        ballPosition = Offset(ballPosition.dx, ballRadius);
      }

      // Ball collision with paddle
      if (_checkPaddleCollision()) {
        ballVelocity = Offset(ballVelocity.dx, -ballVelocity.dy.abs());

        // Add angle based on where ball hits paddle
        double paddleCenter = paddleX + paddleWidth / 2;
        double difference = ballPosition.dx - paddleCenter;
        ballVelocity = Offset(
          ballVelocity.dx + difference * 3,
          ballVelocity.dy,
        );

        // Limit velocity
        ballVelocity = Offset(
          ballVelocity.dx.clamp(-ballSpeed, ballSpeed),
          ballVelocity.dy,
        );
      }

      // Ball collision with bricks
      _checkBrickCollisions();

      // Ball goes off bottom
      if (ballPosition.dy >= gameSize.height) {
        _loseLife();
      }
    });
  }

  bool _checkPaddleCollision() {
    double paddleY = gameSize.height - 60;
    return ballPosition.dx >= paddleX - ballRadius &&
        ballPosition.dx <= paddleX + paddleWidth + ballRadius &&
        ballPosition.dy >= paddleY - ballRadius &&
        ballPosition.dy <= paddleY + paddleHeight + ballRadius;
  }

  void _checkBrickCollisions() {
    double startX =
        (gameSize.width - (brickCols * brickWidth + (brickCols - 1) * 5)) / 2;
    double startY = 80;

    for (int row = 0; row < brickRows; row++) {
      for (int col = 0; col < brickCols; col++) {
        if (!bricks[row][col]) continue;

        double brickX = startX + col * (brickWidth + 5);
        double brickY = startY + row * (brickHeight + 5);

        if (ballPosition.dx >= brickX - ballRadius &&
            ballPosition.dx <= brickX + brickWidth + ballRadius &&
            ballPosition.dy >= brickY - ballRadius &&
            ballPosition.dy <= brickY + brickHeight + ballRadius) {
          bricks[row][col] = false;
          ballVelocity = Offset(ballVelocity.dx, -ballVelocity.dy);
          score += 10;

          // Check if all bricks destroyed
          if (_allBricksDestroyed()) {
            _nextLevel();
          }
          return;
        }
      }
    }
  }

  bool _allBricksDestroyed() {
    for (var row in bricks) {
      for (var brick in row) {
        if (brick) return false;
      }
    }
    return true;
  }

  void _nextLevel() {
    // Reset bricks
    bricks = List.generate(
      brickRows,
      (row) => List.generate(brickCols, (col) => true),
    );
    _resetBall();
  }

  void _loseLife() {
    lives--;
    if (lives <= 0) {
      gameOver = true;
    } else {
      _resetBall();
    }
  }

  void _resetBall() {
    // Position ball on top center of paddle
    ballPosition = Offset(
      paddleX + paddleWidth / 2,
      gameSize.height - 60 - ballRadius - 2,
    );
    ballVelocity = const Offset(0, 0);
    gameStarted = false;
  }

  void _startGame() {
    if (!gameStarted && !gameOver) {
      setState(() {
        gameStarted = true;
        ballVelocity = Offset(
          (Random().nextBool() ? 1 : -1) * ballSpeed * 0.6,
          -ballSpeed,
        );
      });
    }
  }

  void _restartGame() {
    setState(() {
      gameStarted = false;
      gameOver = false;
      score = 0;
      lives = 3;
    });
    _initializeGame();
  }

  void _movePaddle(Offset tapPosition) {
    setState(() {
      paddleX = (tapPosition.dx - paddleWidth / 2).clamp(
        0,
        gameSize.width - paddleWidth,
      );

      // If game hasn't started, move ball with paddle
      if (!gameStarted) {
        ballPosition = Offset(
          paddleX + paddleWidth / 2,
          gameSize.height - 60 - ballRadius - 2,
        );
      }
    });
  }

  @override
  void dispose() {
    _gameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF222222),
      body: SafeArea(
        child: GestureDetector(
          onTapDown: (details) {
            if (!gameStarted && !gameOver) {
              _startGame();
            } else if (!gameOver) {
              _movePaddle(details.localPosition);
            }
          },
          onPanUpdate: (details) {
            if (!gameOver) {
              _movePaddle(details.localPosition);
            }
          },
          child: Stack(
            children: [
              // Game canvas
              CustomPaint(
                size: Size.infinite,
                painter: GamePainter(
                  ballPosition: ballPosition,
                  paddleX: paddleX,
                  bricks: bricks,
                  gameSize: gameSize,
                ),
              ),

              // UI overlay
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score: $score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Lives: $lives',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Instructions/Game Over overlay
              if (!gameStarted && !gameOver)
                const Center(
                  child: Text(
                    'Tap to start!\nDrag to move paddle',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              if (gameOver)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Game Over!',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _restartGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                        child: const Text(
                          'Restart Game',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class GamePainter extends CustomPainter {
  final Offset ballPosition;
  final double paddleX;
  final List<List<bool>> bricks;
  final Size gameSize;

  GamePainter({
    required this.ballPosition,
    required this.paddleX,
    required this.bricks,
    required this.gameSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final ballPaint = Paint()..color = Colors.white;
    final paddlePaint = Paint()..color = Colors.white;

    // Draw ball
    canvas.drawCircle(ballPosition, _BreakoutGameState.ballRadius, ballPaint);

    // Draw paddle
    final paddleRect = Rect.fromLTWH(
      paddleX,
      gameSize.height - 60,
      _BreakoutGameState.paddleWidth,
      _BreakoutGameState.paddleHeight,
    );
    canvas.drawRect(paddleRect, paddlePaint);

    // Draw bricks
    double startX =
        (gameSize.width -
            (_BreakoutGameState.brickCols * _BreakoutGameState.brickWidth +
                (_BreakoutGameState.brickCols - 1) * 5)) /
        2;
    double startY = 80;

    for (int row = 0; row < _BreakoutGameState.brickRows; row++) {
      for (int col = 0; col < _BreakoutGameState.brickCols; col++) {
        if (bricks.isEmpty) return;
        if (!bricks[row][col]) continue;

        final brickPaint = Paint()..color = _getBrickColor(row);
        final brickRect = Rect.fromLTWH(
          startX + col * (_BreakoutGameState.brickWidth + 5),
          startY + row * (_BreakoutGameState.brickHeight + 5),
          _BreakoutGameState.brickWidth,
          _BreakoutGameState.brickHeight,
        );
        canvas.drawRect(brickRect, brickPaint);
      }
    }
  }

  Color _getBrickColor(int row) {
    switch (row) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.yellow;
      case 3:
        return Colors.green;
      case 4:
        return Colors.blue;
      case 5:
        return Colors.purple;
      default:
        return Colors.white;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
