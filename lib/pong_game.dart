import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'nearby_manager.dart';

class PongGame extends StatefulWidget {
  final NearbyManager nearbyManager;
  final bool isHost;

  const PongGame({super.key, required this.nearbyManager, required this.isHost});

  @override
  State<PongGame> createState() => _PongGameState();
}

class _PongGameState extends State<PongGame> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  
  // Game State
  double ballX = 0.5;
  double ballY = 0.5;
  double ballVX = 0.005;
  double ballVY = 0.007;
  
  double myPaddleX = 0.5;
  double opponentPaddleX = 0.5;
  
  int myScore = 0;
  int opponentScore = 0;

  DateTime _lastSent = DateTime.now();
  final int _sendIntervalMs = 30; // ~33 FPS network rate

  final double paddleWidth = 0.2;
  final double paddleHeight = 0.02;
  final double ballSize = 0.02;

  @override
  void initState() {
    super.initState();
    widget.nearbyManager.onDataReceived = _handleNetworkData;

    _ticker = createTicker(_tick);
    _ticker.start();
  }

  void _handleNetworkData(String data) {
    final Map<String, dynamic> msg = jsonDecode(data);
    
    if (widget.isHost) {
      // Host receives paddle position from client
      if (msg['type'] == 'paddle') {
        setState(() {
          opponentPaddleX = msg['x'];
        });
      }
    } else {
      // Client receives full state from host
      if (msg['type'] == 'state') {
        setState(() {
          ballX = msg['bx'];
          ballY = 1.0 - msg['by']; // Invert Y for client view
          opponentPaddleX = msg['px'];
          myScore = msg['os']; // Host's score is my opponent score
          opponentScore = msg['ms']; // Host's opponent score is my score
        });
      }
    }
  }

  void _tick(Duration elapsed) {
    if (widget.isHost) {
      _updateHostLogic();
      if (DateTime.now().difference(_lastSent).inMilliseconds > _sendIntervalMs) {
        _sendStateToClient();
        _lastSent = DateTime.now();
      }
    } else {
      if (DateTime.now().difference(_lastSent).inMilliseconds > _sendIntervalMs) {
        _sendPaddleToHost();
        _lastSent = DateTime.now();
      }
    }
  }

  void _updateHostLogic() {
    setState(() {
      ballX += ballVX;
      ballY += ballVY;

      // Wall bounce (X)
      if (ballX <= 0 || ballX >= 1.0) ballVX = -ballVX;

      // Paddle collision (My Paddle - Bottom)
      if (ballY >= 1.0 - paddleHeight - ballSize) {
        if (ballX >= myPaddleX - paddleWidth / 2 && ballX <= myPaddleX + paddleWidth / 2) {
          ballVY = -ballVY.abs();
          // Add some spin based on where it hit the paddle
          ballVX += (ballX - myPaddleX) * 0.05;
        } else if (ballY >= 1.1) {
          // Goal for opponent
          opponentScore++;
          _resetBall();
        }
      }

      // Paddle collision (Opponent Paddle - Top)
      if (ballY <= paddleHeight + ballSize) {
        if (ballX >= opponentPaddleX - paddleWidth / 2 && ballX <= opponentPaddleX + paddleWidth / 2) {
          ballVY = ballVY.abs();
          ballVX += (ballX - opponentPaddleX) * 0.05;
        } else if (ballY <= -0.1) {
          // Goal for me
          myScore++;
          _resetBall();
        }
      }
    });
  }

  void _resetBall() {
    ballX = 0.5;
    ballY = 0.5;
    ballVX = (Random().nextBool() ? 1 : -1) * (0.003 + Random().nextDouble() * 0.004);
    ballVY = (Random().nextBool() ? 1 : -1) * (0.005 + Random().nextDouble() * 0.003);
  }

  void _sendStateToClient() {
    final msg = jsonEncode({
      'type': 'state',
      'bx': ballX,
      'by': ballY,
      'px': myPaddleX,
      'ms': myScore,
      'os': opponentScore,
    });
    widget.nearbyManager.sendData(msg);
  }

  void _sendPaddleToHost() {
    final msg = jsonEncode({
      'type': 'paddle',
      'x': myPaddleX,
    });
    widget.nearbyManager.sendData(msg);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            myPaddleX = (details.localPosition.dx / MediaQuery.of(context).size.width).clamp(paddleWidth / 2, 1.0 - paddleWidth / 2);
          });
        },
        child: Stack(
          children: [
            CustomPaint(
              size: Size.infinite,
              painter: PongPainter(
                ballX: ballX,
                ballY: ballY,
                myPaddleX: myPaddleX,
                opponentPaddleX: opponentPaddleX,
                paddleWidth: paddleWidth,
                paddleHeight: paddleHeight,
                ballSize: ballSize,
              ),
            ),
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "$opponentScore - $myScore",
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PongPainter extends CustomPainter {
  final double ballX, ballY, myPaddleX, opponentPaddleX;
  final double paddleWidth, paddleHeight, ballSize;

  PongPainter({
    required this.ballX,
    required this.ballY,
    required this.myPaddleX,
    required this.opponentPaddleX,
    required this.paddleWidth,
    required this.paddleHeight,
    required this.ballSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    // Ball
    canvas.drawCircle(Offset(ballX * size.width, ballY * size.height), ballSize * size.width, paint);

    // My Paddle (Bottom)
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(myPaddleX * size.width, (1.0 - paddleHeight / 2) * size.height),
        width: paddleWidth * size.width,
        height: paddleHeight * size.height,
      ),
      paint,
    );

    // Opponent Paddle (Top)
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(opponentPaddleX * size.width, (paddleHeight / 2) * size.height),
        width: paddleWidth * size.width,
        height: paddleHeight * size.height,
      ),
      paint,
    );

    // Center Line
    paint.color = Colors.white24;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
