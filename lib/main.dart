import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const McrezilChase());

class McrezilChase extends StatelessWidget {
  const McrezilChase({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MCREZIL CHASE',
      theme: ThemeData.dark(),
      home: const ChaseGame(),
    );
  }
}

class ChaseGame extends StatefulWidget {
  const ChaseGame({super.key});
  @override
  State<ChaseGame> createState() => _ChaseGameState();
}

class _ChaseGameState extends State<ChaseGame> {
  // Player
  Offset player = const Offset(150, 300);
  Offset moveDir = Offset.zero;
  double playerSpeed = 4.5;

  // Hunters
  List<Offset> hunters = [const Offset(50, 50), const Offset(300, 100)];
  List<double> hunterSpeeds = [1.8, 2.0];

  // Coins
  List<Offset> coins = [];
  Random rand = Random();

  int score = 0;
  int best = 0;
  bool playing = false;
  bool gameOver = false;
  Timer? loop;
  Size screen = const Size(400, 700);

  @override
  void initState() {
    super.initState();
    spawnCoins();
  }

  void spawnCoins() {
    coins = List.generate(5, (_) => Offset(
      rand.nextDouble() * 300 + 20,
      rand.nextDouble() * 500 + 100,
    ));
  }

  void start() {
    setState(() {
      playing = true;
      gameOver = false;
      player = Offset(screen.width/2, screen.height/2);
      hunters = [const Offset(0, 0), Offset(screen.width, 0)];
      hunterSpeeds = [1.8, 2.0];
      score = 0;
      spawnCoins();
    });
    loop?.cancel();
    loop = Timer.periodic(const Duration(milliseconds: 16), (_) => update());
  }

  void update() {
    if (!playing) return;
    setState(() {
      // Move player by joystick
      player += moveDir * playerSpeed;
      player = Offset(
        player.dx.clamp(15, screen.width - 15),
        player.dy.clamp(80, screen.height - 15),
      );

      // Hunters chase player
      for (int i = 0; i < hunters.length; i++) {
        Offset dir = player - hunters[i];
        double dist = dir.distance;
        if (dist > 1) {
          dir /= dist;
          hunters[i] += dir * hunterSpeeds[i];
        }
        // Collision with player
        if ((hunters[i] - player).distance < 28) {
          endGame();
          return;
        }
      }

      // Collect coins
      coins.removeWhere((c) {
        if ((c - player).distance < 25) {
          score += 10;
          // add hunter every 50 points
          if (score % 50 == 0) {
            hunters.add(Offset(rand.nextDouble() * screen.width, 0));
            hunterSpeeds.add(1.5 + rand.nextDouble() * 1.5 + score / 200);
          }
          return true;
        }
        return false;
      });
      if (coins.length < 3) {
        coins.add(Offset(rand.nextDouble() * (screen.width-40) + 20, rand.nextDouble() * (screen.height-150) + 100));
      }

      score++; // survival points
    });
  }

  void endGame() {
    loop?.cancel();
    setState(() {
      playing = false;
      gameOver = true;
      if (score > best) best = score;
    });
  }

  @override
  Widget build(BuildContext context) {
    screen = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1026),
      body: Stack(
        children: [
          // Grid bg
          CustomPaint(size: screen, painter: GridPainter()),

          // Coins
          for (var c in coins)
            Positioned(
              left: c.dx - 12, top: c.dy - 12,
              child: Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.8), blurRadius: 12)],
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.star, size: 16, color: Colors.black),
              ),
            ),

          // Hunters
          for (int i = 0; i < hunters.length; i++)
            Positioned(
              left: hunters[i].dx - 18, top: hunters[i].dy - 18,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.red, blurRadius: 10)],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 22),
              ),
            ),

          // Player
          Positioned(
            left: player.dx - 20, top: player.dy - 20,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF00FF88),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [BoxShadow(color: Color(0xFF00FF88), blurRadius: 20)],
              ),
              child: const Icon(Icons.bolt, color: Colors.black),
            ),
          ),

          // HUD
          Positioned(
            top: 40, left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("MCREZIL CHASE", style: TextStyle(color: Color(0xFF00FF88), fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
                  Text("SCORE: $score BEST: $best", style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
                  child: Text("HUNTERS: ${hunters.length}", style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

          // Joystick Area
          Positioned.fill(
            child: GestureDetector(
              onPanUpdate: (d) {
                setState(() {
                  moveDir = d.delta / 10;
                  moveDir = Offset(moveDir.dx.clamp(-1, 1), moveDir.dy.clamp(-1, 1));
                });
              },
              onPanEnd: (_) => setState(() => moveDir = Offset.zero),
            ),
          ),

          // Joystick visual
          Positioned(
            left: 30, bottom: 30,
            child: Container(
              width: 110, height: 110,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08), border: Border.all(color: Colors.white24)),
              child: Center(
                child: Transform.translate(
                  offset: moveDir * 25,
                  child: Container(
                    width: 50, height: 50,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00FF88)),
                    child: const Icon(Icons.open_with, color: Colors.black),
                  ),
                ),
              ),
            ),
          ),

          // Menu
          if (!playing)
            Container(
              color: Colors.black.withOpacity(0.75),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text("MCREZIL", style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Color(0xFF00FF88), letterSpacing: 4)),
                  Text(gameOver? "CAUGHT!" : "CHASE", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: gameOver? Colors.redAccent : Colors.white, letterSpacing: 8)),
                  const SizedBox(height: 10),
                  Text(gameOver? "Score: $score" : "You vs Hunters", style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: start,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF88), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18)),
                    child: Text(gameOver? "RUN AGAIN" : "START CHASE", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                  const SizedBox(height: 20),
                  const Text("DRAG bottom-left circle to RUN\nCollect stars, avoid red hunters!", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.05)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 30) canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += 30) canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
