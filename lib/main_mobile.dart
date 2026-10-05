import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'dart:typed_data';
import 'dart:math';

void main() => runApp(MobileApp());

class MobileApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: Lobby());
  }
}

class Lobby extends StatefulWidget {
  @override
  _LobbyState createState() => _LobbyState();
}

class _LobbyState extends State<Lobby> {
  final Nearby nearby = Nearby();
  List<String> endpoints = [];
  bool isHost = false;

  void startHost() async {
    setState(() => isHost = true);
    try {
      await nearby.startAdvertising(
        "MCREZIL-HOST",
        Strategy.P2P_STAR,
        onConnectionInitiated: (id, info) {
          nearby.acceptConnection(id,
            onPayLoadRecieved: (eid, payload) {},
            onPayloadTransferUpdate: (eid, update) {},
          );
          setState(() => endpoints.add(id));
        },
        onConnectionResult: (id, status) {},
        onDisconnected: (id) {},
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hosting... waiting for players")));
    } catch (e) {
      print(e);
    }
  }

  void startJoin() async {
    try {
      await nearby.startDiscovery(
        "MCREZIL-HOST",
        Strategy.P2P_STAR,
        onEndpointFound: (id, name, service) {
          nearby.requestConnection(name, id,
            onConnectionInitiated: (id, info) {
              nearby.acceptConnection(id,
                onPayLoadRecieved: (eid, payload) {
                  if(payload.type == PayloadType.BYTES){
                    String msg = String.fromCharCodes(payload.bytes!);
                    if(msg == "START") Navigator.push(context, MaterialPageRoute(builder: (_) => McrezilChase(isHost: false, nearby: nearby, endpoints: [id])));
                  }
                },
                onPayloadTransferUpdate: (eid, update) {},
              );
            },
            onConnectionResult: (id, status) {
              if(status == Status.CONNECTED) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connected to Host!")));
            },
            onDisconnected: (id) {},
          );
        },
        onEndpointLost: (id) {},
      );
    } catch (e) { print(e); }
  }

  void sendStartToAll() {
    for (var id in endpoints) {
      nearby.sendBytesPayload(id, Uint8List.fromList("START".codeUnits));
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => McrezilChase(isHost: true, nearby: nearby, endpoints: endpoints)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("MCREZIL", style: TextStyle(color: Color(0xFF00FF88), fontSize: 50, fontWeight: FontWeight.bold)),
          Text("OFFLINE MULTIPLAYER", style: TextStyle(color: Colors.white54, letterSpacing: 3)),
          SizedBox(height: 40),
          ElevatedButton(onPressed: startHost, style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00FF88), minimumSize: Size(200, 50)), child: Text("HOST GAME", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
          SizedBox(height: 20),
          ElevatedButton(onPressed: startJoin, style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, minimumSize: Size(200, 50)), child: Text("JOIN GAME", style: TextStyle(color: Colors.white))),
          SizedBox(height: 20),
          if(isHost && endpoints.isNotEmpty) ElevatedButton(onPressed: sendStartToAll, child: Text("START MATCH (${endpoints.length} players)")),
          SizedBox(height: 30),
          Text("Players connected: ${endpoints.length}", style: TextStyle(color: Colors.white38)),
        ]),
      ),
    );
  }
}

// YOUR CHASE GAME - simplified for APK
class McrezilChase extends StatefulWidget {
  final bool isHost;
  final Nearby nearby;
  final List<String> endpoints;
  McrezilChase({required this.isHost, required this.nearby, required this.endpoints});
  @override
  _McrezilChaseState createState() => _McrezilChaseState();
}

class _McrezilChaseState extends State<McrezilChase> with SingleTickerProviderStateMixin {
  double px = 0.5, py = 0.8;
  List<Map<String,double>> hunters = [];
  int score = 0;
  late AnimationController ctrl;

  @override
  void initState(){
    super.initState();
    hunters = List.generate(3, (_)=> {'x': Random().nextDouble(), 'y': Random().nextDouble()*0.5});
    ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: 16))..addListener((){
      setState((){
        for(var h in hunters){
          double dx = px - h['x']!, dy = py - h['y']!;
          double d = sqrt(dx*dx + dy*dy);
          if(d < 0.08) { ctrl.stop(); return; }
          h['x'] = h['x']! + dx/d * 0.003;
          h['y'] = h['y']! + dy/d * 0.003;
        }
        score++;
      });
    })..repeat();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onPanUpdate: (d){ setState((){ px = (px + d.delta.dx / 300).clamp(0.0, 1.0); py = (py + d.delta.dy / 300).clamp(0.0, 1.0); }); },
        child: Stack(children:[
          CustomPaint(size: Size.infinite, painter: GamePainter(px, py, hunters)),
          Positioned(top: 50, left: 20, child: Text("Score: $score", style: TextStyle(color: Colors.white))),
        ]),
      ),
    );
  }
}

class GamePainter extends CustomPainter {
  final double px, py;
  final List<Map<String,double>> hunters;
  GamePainter(this.px, this.py, this.hunters);
  @override
  void paint(Canvas c, Size s){
    c.drawCircle(Offset(px*s.width, py*s.height), 14, Paint()..color = Color(0xFF00FF88));
    for(var h in hunters) c.drawCircle(Offset(h['x']!*s.width, h['y']!*s.height), 11, Paint()..color = Colors.red);
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => true;
}
