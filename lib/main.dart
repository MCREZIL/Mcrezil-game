import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const McrezilChase());

class McrezilChase extends StatelessWidget {
  const McrezilChase({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: const ChaseGame());
  }
}

class ChaseGame extends StatefulWidget {
  const ChaseGame({super.key});
  @override
  State<ChaseGame> createState() => _ChaseGameState();
}

class _ChaseGameState extends State<ChaseGame> {
  Offset player = const Offset(200, 400);
  Offset joystickDelta = Offset.zero; // -1 to 1
  double playerSpeed = 7.5; // <<< FAST NOW

  List<Offset> hunters = [const Offset(50, 50)];
  List<double> hunterSpeeds = [2.2];
  List<Offset> coins = [];
  Random rand = Random();
  int score = 0, best = 0;
  bool playing = false, gameOver = false;
  Timer? loop;
  Size screen = const Size(400, 700);

  void spawnCoins() {
    coins = List.generate(6, (_) => Offset(rand.nextDouble() * 320 + 20, rand.nextDouble() * 500 + 120));
  }

  void start() {
    setState(() {
      playing = true; gameOver = false;
      player = Offset(screen.width/2, screen.height/2);
      hunters = [const Offset(0, 0), Offset(screen.width, 0)];
      hunterSpeeds = [2.0, 2.1];
      score = 0; joystickDelta = Offset.zero;
      spawnCoins();
    });
    loop?.cancel();
    loop = Timer.periodic(const Duration(milliseconds: 16), (_) => update());
  }

  void update() {
    if (!playing) return;
    setState(() {
      // INSTANT MOVE
      player += joystickDelta * playerSpeed;
      player = Offset(player.dx.clamp(20, screen.width - 20), player.dy.clamp(90, screen.height - 20));

      for (int i = 0; i < hunters.length; i++) {
        Offset dir = player - hunters[i];
        double d = dir.distance;
        if (d > 2) hunters[i] += (dir / d) * hunterSpeeds[i];
        if ((hunters[i] - player).distance < 30) endGame();
      }

      coins.removeWhere((c) {
        if ((c - player).distance < 28) {
          score += 20;
          if (score % 60 == 0) {
            hunters.add(Offset(rand.nextDouble() * screen.width, 0));
            hunterSpeeds.add(2.0 + rand.nextDouble() * 1.2 + score/300);
          }
          return true;
        }
        return false;
      });
      if (coins.length < 4) coins.add(Offset(rand.nextDouble() * (screen.width-40) + 20, rand.nextDouble() * (screen.height-200) + 120));
      score++;
    });
  }

  void endGame() {
    loop?.cancel();
    setState(() { playing = false; gameOver = true; if (score > best) best = score; });
  }

  @override
  Widget build(BuildContext context) {
    screen = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1026),
      body: Stack(
        children: [
          // Coins
          for (var c in coins)
            Positioned(left: c.dx-14, top: c.dy-14, child: Container(width:28,height:28,decoration: BoxDecoration(color: Colors.amber, shape: BoxShape.circle, border: Border.all(color: Colors.white,width:2), boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.8), blurRadius:12)]), child: const Icon(Icons.star,size:16,color:Colors.black))),
          // Hunters
          for (var h in hunters)
            Positioned(left: h.dx-20, top: h.dy-20, child: Container(width:40,height:40,decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white,width:2)), child: const Icon(Icons.directions_run,color:Colors.white))),
          // Player
          Positioned(left: player.dx-22, top: player.dy-22, child: Container(width:44,height:44,decoration: BoxDecoration(color: const Color(0xFF00FF88), shape: BoxShape.circle, border: Border.all(color: Colors.white,width:3), boxShadow: const [BoxShadow(color: Color(0xFF00FF88), blurRadius: 20)]), child: const Icon(Icons.bolt,color:Colors.black))),

          // HUD
          Positioned(top:45,left:20,right:20,child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text("MCREZIL ${score}", style: const TextStyle(color: Color(0xFF00FF88), fontWeight: FontWeight.w900,fontSize:18)), Text("HUNTERS: ${hunters.length} BEST:$best", style: const TextStyle(fontSize:12))])),

          // FULL SCREEN DRAG = MOVE + JOYSTICK
          Positioned.fill(
            child: GestureDetector(
              onPanStart: (d) => updateJoystick(d.localPosition),
              onPanUpdate: (d) => updateJoystick(d.localPosition),
              onPanEnd: (_) => setState(()=> joystickDelta = Offset.zero),
            ),
          ),

          // Joystick base - now follows finger
          Positioned(left: 25, bottom: 25, child:
            Container(width:120,height:120,decoration: BoxDecoration(shape:BoxShape.circle,color:Colors.white.withOpacity(0.1),border:Border.all(color:Colors.white24)),
              child: Center(child: Transform.translate(offset: joystickDelta*35, child: Container(width:56,height:56,decoration: const BoxDecoration(shape:BoxShape.circle,color:Color(0xFF00FF88)), child: const Icon(Icons.navigation,color:Colors.black))))
            )
          ),

          if (!playing)
            Container(color: Colors.black.withOpacity(0.8), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children:[
              const Text("MCREZIL", style: TextStyle(fontSize:52,fontWeight:FontWeight.w900,color:Color(0xFF00FF88),letterSpacing:4)),
              Text(gameOver?"CAUGHT!":"CHASE", style: TextStyle(fontSize:32,letterSpacing:8,color: gameOver?Colors.red:Colors.white)),
              const SizedBox(height:12),
              Text("Score $score", style: const TextStyle(color: Colors.white70)),
              const SizedBox(height:24),
              ElevatedButton(onPressed: start, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF88),foregroundColor:Colors.black,padding: const EdgeInsets.symmetric(horizontal:60,vertical:18)), child: Text(gameOver?"RUN AGAIN":"START")),
              const SizedBox(height:16),
              const Text("Touch ANYWHERE & DRAG to run FAST!\nNow 3x faster touch", textAlign:TextAlign.center, style: TextStyle(color:Colors.white54,fontSize:13)),
            ]))),
        ],
      ),
    );
  }

  void updateJoystick(Offset touchPos) {
    // joystick center is at bottom-left
    Offset joyCenter = Offset(25 + 60, screen.height - (25 + 60));
    Offset diff = touchPos - joyCenter;
    double dist = diff.distance;
    double maxDist = 55;
    if (dist > maxDist) diff = (diff / dist) * maxDist;
    setState(() => joystickDelta = diff / maxDist); // -1 to 1 normalized
  }
}
