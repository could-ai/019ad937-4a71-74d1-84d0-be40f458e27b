import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  int _score = 0;
  int _highScore = 0;
  bool _isSwinging = true;
  bool _gameOver = false;
  
  late AnimationController _controller;
  late Animation<double> _animation;

  // Player and rope positions
  double _playerAngle = 0;
  final double _ropeLength = 150;
  final Offset _ropeAnchor = const Offset(0, -150);
  Offset _playerPos = const Offset(0, 0);

  // Target rope
  double _targetRopeX = 150;
  final double _targetRopeY = 0;
  final double _successZone = 20;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = Tween<double>(begin: -pi / 4, end: pi / 4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut)
    )..addListener(() {
        setState(() {
          _playerAngle = _animation.value;
          _playerPos = Offset(
            _ropeAnchor.dx + sin(_playerAngle) * _ropeLength,
            _ropeAnchor.dy + cos(_playerAngle) * _ropeLength,
          );
        });
      });

    _controller.repeat(reverse: true);
    _startGame();
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _gameOver = false;
      _isSwinging = true;
      _targetRopeX = 150 + Random().nextDouble() * 50;
      _controller.repeat(reverse: true);
    });
  }

  void _jump() {
    if (!_isSwinging) return;

    _controller.stop();
    setState(() {
      _isSwinging = false;
    });

    // Simple jump simulation
    final jumpSuccess = (_playerPos.dx - _targetRopeX).abs() < _successZone && _playerAngle > 0.3;

    if (jumpSuccess) {
      setState(() {
        _score++;
        _targetRopeX = 150 + Random().nextDouble() * 50;
        _isSwinging = true;
      });
      _controller.repeat(reverse: true);
    } else {
      _endGame();
    }
  }

  void _endGame() {
    setState(() {
      _gameOver = true;
      if (_score > _highScore) {
        _highScore = _score;
      }
    });
    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('انتهت اللعبة'),
          content: Text('النتيجة: $_score\nأعلى نتيجة: $_highScore'),
          actions: <Widget>[
            TextButton(
              child: const Text('إعادة اللعب'),
              onPressed: () {
                Navigator.of(context).pop();
                _startGame();
              },
            ),
            TextButton(
              child: const Text('القائمة الرئيسية'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context); // Go back to main menu
              },
            ),
          ],
        );
      },
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: GestureDetector(
        onTap: _jump,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/jungle_background.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Score Display
              Positioned(
                top: 50,
                child: Text(
                  'النتيجة: $_score',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              
              // Game elements
              Transform.translate(
                offset: Offset(screenSize.width / 2, screenSize.height / 2),
                child: CustomPaint(
                  painter: GamePainter(_playerPos, _ropeAnchor, _targetRopeX, _targetRopeY, _successZone),
                  size: Size.infinite,
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
  final Offset playerPos;
  final Offset ropeAnchor;
  final double targetRopeX;
  final double targetRopeY;
  final double successZone;

  GamePainter(this.playerPos, this.ropeAnchor, this.targetRopeX, this.targetRopeY, this.successZone);

  @override
  void paint(Canvas canvas, Size size) {
    final ropePaint = Paint()
      ..color = Colors.brown[800]!
      ..strokeWidth = 4;
    
    final playerPaint = Paint()..color = Colors.redAccent;
    final targetPaint = Paint()..color = Colors.green;
    final zonePaint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw current rope
    canvas.drawLine(ropeAnchor, playerPos, ropePaint);

    // Draw player (Tarzan)
    canvas.drawCircle(playerPos, 20, playerPaint);

    // Draw target rope
    canvas.drawLine(Offset(targetRopeX, -150), Offset(targetRopeX, 50), ropePaint);
    canvas.drawRect(Rect.fromCircle(center: Offset(targetRopeX, 0), radius: 10), targetPaint);
    
    // Draw success zone for timing
    canvas.drawRect(Rect.fromCenter(center: Offset(targetRopeX, 0), width: successZone * 2, height: 50), zonePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
