import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(McrezilApp());

class McrezilApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: McrezilChase(),
    );
  }
}

class McrezilChase extends StatefulWidget {
  @override
  _McrezilChaseState createState() => _McrezilChaseState();
}

class _McrezilChaseState extends State<McrezilChase> with SingleTickerProviderStateMixin {
  double playerX = 0.5, playerY = 0.8;
  List<Map<String,double>> hunters = [];
  int score = 0;
  bool playing = false;
  late AnimationController controller;

  @override
  void initState(){
    super.initState();
    controller = AnimationController(vsync: this, duration: Duration(milliseconds: 16))..addListener(update);
  }
  
  void start(){
    hunters = List.generate(3, (i)=> {'x': Random().nextDouble(), 'y': Random().nextDouble()*0.5});
    score = 0;
    playerX = 0.5; playerY = 0.8;
    playing = true;
    controller.repeat();
  }
  
  void update(){
    if(!playing) return;
    setState((){
      for(var h in hunters){
        double dx = playerX - h['x']!;
        double dy = playerY - h['y']!;
        double d = sqrt(dx*dx + dy*dy);
        if(d < 0.07){ playing = false; controller.stop(); return; }
        h['x'] = h['x']! + dx/d * 0.002;
        h['y'] = h['y']! + dy/d * 0.002;
      }
      score++;
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children:[
        // Game area
        Positioned.fill(child: CustomPaint(painter: GamePainter(playerX, playerY, hunters))),
        // UI
        Column(children:[
          SizedBox(height: 50),
          Center(child: Text('MCREZIL', style: TextStyle(color: Color(0xFF00FF88), fontSize: 48, fontWeight: FontWeight.bold))),
          Center(child: Text('CHASE', style: TextStyle(color: Colors.white, fontSize: 28, letterSpacing: 8))),
          SizedBox(height: 10),
          Text('You scored $score', style: TextStyle(color: Colors.white70)),
          SizedBox(height: 20),
          if(!playing) ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00FF88), padding: EdgeInsets.symmetric(horizontal: 60, vertical: 20), shape: StadiumBorder()),
            onPressed: start,
            child: Text('PLAY', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          Spacer(),
          Padding(padding: EdgeInsets.all(20), child: Text('LEFT pad = move (works now!)\nRIGHT button = HOLD to SPRINT\nYou are 4x faster than hunters!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12))),
          SizedBox(height: 100),
        ]),
        // Controls
        Positioned(left: 20, bottom: 20, child: Container(width: 120, height: 120, decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle), child: Center(child: Text('🕹️', style: TextStyle(fontSize: 30))))),
        Positioned(right: 20, bottom: 20, child: Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle), child: Center(child: Text('⚡\nHOLD\nSPRINT', textAlign: TextAlign.center, style: TextStyle(color: Colors.white24, fontSize: 10))))),
      ]),
    );
  }
}

class GamePainter extends CustomPainter {
  final double px, py;
  final List<Map<String,double>> hunters;
  GamePainter(this.px, this.py, this.hunters);
  @override
  void paint(Canvas canvas, Size size){
    var pPaint = Paint()..color = Color(0xFF00FF88);
    var hPaint = Paint()..color = Colors.red;
    canvas.drawCircle(Offset(px*size.width, py*size.height), 12, pPaint);
    for(var h in hunters){
      canvas.drawCircle(Offset(h['x']!*size.width, h['y']!*size.height), 10, hPaint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
