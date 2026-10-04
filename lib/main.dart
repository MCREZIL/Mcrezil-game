import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const McrezilGame());

class McrezilGame extends StatelessWidget {
  const McrezilGame({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MCREZIL GAME',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const double playerSize = 50;
  double playerY = 0;
  double velocity = 0;
  double gravity = 0.6;
  double jumpForce = -12;
  int score = 0;
  int bestScore = 0;
  bool isPlaying = false;
  bool isGameOver = false;
  List<double> obstaclesX = [400, 700, 1000];
  List<double> obstaclesY = [];
  Timer? gameTimer;
  final Random rand = Random();

  @override
  void initState() {
    super.initState();
    obstaclesY = List.generate(3, (_) => rand.nextDouble() * 200 - 100);
  }

  void startGame() {
    setState(() {
      isPlaying = true;
      isGameOver = false;
      playerY = 0;
      velocity = 0;
      score = 0;
      obstaclesX = [400, 700, 1000];
      obstaclesY = List.generate(3, (_) => rand.nextDouble() * 200 - 100);
    });
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      setState(() {
        velocity += gravity * 0.1;
        playerY += velocity;

        for (int i = 0; i < obstaclesX.length; i++) {
          obstaclesX[i] -= 5;
          if (obstaclesX[i] < -60) {
            obstaclesX[i] = 400;
            obstaclesY[i] = rand.nextDouble() * 200 - 100;
            score++;
          }
          // collision
          if (obstaclesX[i] > 20 && obstaclesX[i] < 90 &&
              (playerY - obstaclesY[i]).abs() < 45) {
            gameOver();
          }
        }
        if (playerY > 250 || playerY < -300) gameOver();
      });
    });
  }

  void gameOver() {
    gameTimer?.cancel();
    setState(() {
      isPlaying = false;
      isGameOver = true;
      if (score > bestScore) bestScore = score;
    });
  }

  void jump() {
    if (!isPlaying) {
      startGame();
    } else {
      setState(() => velocity = jumpForce);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: jump,
      child: Scaffold(
        body: Stack(
          children: [
            // Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A0E21), Color(0xFF1D1E33)],
                ),
              ),
            ),
            // Score
            Positioned(
              top: 50, left: 0, right: 0,
              child: Column(
                children: [
                  const Text("MCREZIL", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4, color: Color(0xFF00FF88))),
                  const SizedBox(height: 8),
                  Text("SCORE: $score", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text("BEST: $bestScore", style: const TextStyle(color: Colors.white54)),
                ],
              ),
            ),
            // Player
            AnimatedBuilder(
              animation: Listenable.merge([]),
              builder: (_, __) => Align(
                alignment: Alignment(0, playerY / 300),
                child: Container(
                  width: playerSize, height: playerSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF88),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Color(0xFF00FF88), blurRadius: 20)],
                  ),
                  child: const Icon(Icons.bolt, color: Colors.black, size: 30),
                ),
              ),
            ),
            // Obstacles
            for (int i = 0; i < obstaclesX.length; i++)
              Positioned(
                left: obstaclesX[i],
                top: MediaQuery.of(context).size.height / 2 + obstaclesY[i],
                child: Container(
                  width: 40, height: 80,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            // Start / Game Over overlay
            if (!isPlaying)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isGameOver)...[
                        const Text("GAME OVER", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                        const SizedBox(height: 10),
                        Text("Score: $score", style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 30),
                      ] else...[
                        const Text("MCREZIL", style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(0xFF00FF88))),
                        const Text("TAP TO DODGE", style: TextStyle(fontSize: 18, letterSpacing: 3)),
                        const SizedBox(height: 30),
                      ],
                      ElevatedButton(
                        onPressed: startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF88),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        child: Text(isGameOver? "PLAY AGAIN" : "PLAY NOW"),
                      ),
                      const SizedBox(height: 20),
                      const Text("Tap anywhere to JUMP", style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
