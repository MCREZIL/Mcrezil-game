import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: BuroraChaseLobby()));

enum Role { hunter, runner }

class Player {
  String id; String name; Role role; bool isHost; Offset pos;
  Player({required this.id, required this.name, this.role=Role.runner, this.isHost=false, Offset? pos}) : pos = pos?? Offset(Random().nextDouble()*300, Random().nextDouble()*600);
}

class BuroraChaseLobby extends StatefulWidget {
  const BuroraChaseLobby({super.key});
  @override State<BuroraChaseLobby> createState() => _BuroraChaseLobbyState();
}

class _BuroraChaseLobbyState extends State<BuroraChaseLobby> {
  List<Player> players = [Player(id:"host", name:"You (Host)", role:Role.hunter, isHost:true)];
  bool gameStarted = false;
  String roomCode = "BRC-${Random().nextInt(9000)+1000}";
  final Strategy strategy = Strategy.P2P_CLUSTER; // better for gaming (mesh) than STAR

  @override
  void initState() { super.initState(); _startHost(); }

  Future<void> _startHost() async {
    try {
      await Nearby().startAdvertising(
        "BURORA-Host", strategy,
        onConnectionInitiated: (id, info) {
          if(players.length >= 10) { Nearby().rejectConnection(id); return; }
          Nearby().acceptConnection(id, onPayLoadRecieved: (a,p){});
        },
        onConnectionResult: (id, status) {
          if(status==Status.CONNECTED){
            setState((){
              if(gameStarted){
                players.add(Player(id:id, name:"Runner ${players.length+1}", role:Role.runner));
              } else {
                players.add(Player(id:id, name:"Player ${players.length+1}", role:Role.runner));
              }
            });
          }
        },
        onDisconnected: (id) => setState(()=> players.removeWhere((p)=>p.id==id)),
      );
    } catch(e){ debugPrint("Nearby error $e"); }
  }

  void _setRole(int i, Role r){
    if(gameStarted) return;
    setState(()=> players[i].role=r);
  }

  void _startGame(){
    if(players.length<2) return;
    if(players.where((p)=>p.role==Role.hunter).isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text("Pick at least 1 Hunter!")));
      return;
    }
    setState(()=> gameStarted=true);
    // keep advertising! late joiners still work
    Nearby().sendBytesPayloadToAll("START_GAME");
    Navigator.push(context, MaterialPageRoute(builder: (_)=> BuroraMap(players: players, isHost:true)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F26),
      appBar: AppBar(backgroundColor: Colors.black, title: const Text("BURORA CHASE V7.6.4", style:TextStyle(color:Color(0xFF00FF88))), centerTitle:true),
      body: Column(children:[
        const SizedBox(height:10),
        Center(child: QrImageView(data:"BURORA://$roomCode", version: QrVersions.auto, size:140, backgroundColor: Colors.white)),
        const SizedBox(height:8),
        Text("Room: $roomCode • Bluetooth | WiFi Direct Ready", style:const TextStyle(color:Colors.amber, fontSize:12)),
        Text("OFFLINE 100% - No Internet Needed", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize:10)),
        const SizedBox(height:10),
        Expanded(child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2, childAspectRatio:1.2, crossAxisSpacing:10, mainAxisSpacing:10),
          itemCount:10,
          itemBuilder: (c,i){
            if(i>=players.length){
              return Card(color: Colors.white10, child: Center(child: TextButton(onPressed: (){}, child: const Text("+ Invite\nQR / Bluetooth", textAlign:TextAlign.center))));
            }
            final p=players[i];
            return Card(
              color: p.role==Role.hunter? Colors.red.withOpacity(0.15) : Colors.green.withOpacity(0.15),
              shape: RoundedRectangleBorder(side: BorderSide(color: p.role==Role.hunter? Colors.red: const Color(0xFF00FF88)), borderRadius: BorderRadius.circular(12)),
              child: Padding(padding: const EdgeInsets.all(8), child: Column(children:[
                Text(p.name, style: const TextStyle(color:Colors.amber, fontWeight:FontWeight.bold)),
                Text(p.isHost?"HOST":"", style: const TextStyle(color:Colors.white54, fontSize:10)),
                const Spacer(),
                Row(mainAxisAlignment:MainAxisAlignment.center, children:[
                  ChoiceChip(label: const Text("HUNTER", style:TextStyle(fontSize:10)), selected: p.role==Role.hunter, selectedColor: Colors.redAccent, onSelected: (_)=> _setRole(i, Role.hunter)),
                  const SizedBox(width:4),
                  ChoiceChip(label: const Text("RUNNER", style:TextStyle(fontSize:10)), selected: p.role==Role.runner, selectedColor: const Color(0xFF00FF88), onSelected: (_)=> _setRole(i, Role.runner)),
                ])
              ])),
            );
          },
        )),
        Padding(padding: const EdgeInsets.all(12), child: Column(children:[
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF88), minimumSize: const Size(double.infinity, 50)),
            onPressed: players.length>=2? _startGame : null,
            child: Text("START GAME (${players.length}/10) - Roles Locked After Start", style: const TextStyle(color:Colors.black, fontWeight:FontWeight.w900)),
          ),
          if(gameStarted) const Padding(padding: EdgeInsets.only(top:6), child: Text("Game Running - Late joiners become RUNNERS only", style:TextStyle(color:Colors.green, fontSize:11))),
        ])),
      ]),
    );
  }
}

class BuroraMap extends StatefulWidget {
  final List<Player> players; final bool isHost;
  const BuroraMap({super.key, required this.players, required this.isHost});
  @override State<BuroraMap> createState() => _BuroraMapState();
}

class _BuroraMapState extends State<BuroraMap> {
  late List<Player> players;
  Offset myPos = const Offset(150,300);
  Offset stick = Offset.zero;

  @override
  void initState(){ super.initState(); players=widget.players; }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F26),
      body: Stack(children:[
        // players dots
        for(var p in players)
          Positioned(left: (p.isHost? myPos.dx : p.pos.dx)-18, top: (p.isHost? myPos.dy : p.pos.dy)-18,
            child: Container(width:36,height:36,decoration:BoxDecoration(color: p.role==Role.hunter? Colors.redAccent : const Color(0xFF00FF88), shape:BoxShape.circle, border:Border.all(color:Colors.white,width:2)),
              child: Icon(p.role==Role.hunter? Icons.person : Icons.bolt, size:18, color: p.role==Role.hunter? Colors.white : Colors.black))),
        // joystick
        Positioned(left:20,bottom:20,child: Container(width:130,height:130,decoration:BoxDecoration(shape:BoxShape.circle,color:Colors.white10,border:Border.all(color:Colors.white24)),
          child: GestureDetector(
            onPanUpdate:(d){
              var center=const Offset(65,65);
              var diff=d.localPosition-center;
              if(diff.distance>50) diff=(diff/diff.distance)*50;
              setState((){
                stick=diff/50;
                myPos+=stick*6;
              });
              // check catch
              for(var other in players){
                if(other.isHost) continue;
                if(widget.players.first.role==Role.hunter && (myPos-other.pos).distance<30){
                  // caught
                }
              }
            },
            onPanEnd:(_)=> setState(()=> stick=Offset.zero),
            child: Center(child: Transform.translate(offset: stick*40, child: Container(width:55,height:55,decoration: const BoxDecoration(shape:BoxShape.circle,color:Color(0xFF00FF88)), child: const Icon(Icons.gamepad))))),
        ),
        Positioned(top:40,left:20, child: Text("BURORA MAP - ${players.where((p)=>p.role==Role.hunter).length} Hunters vs ${players.where((p)=>p.role==Role.runner).length} Runners", style: const TextStyle(color:Colors.white, fontWeight:FontWeight.bold))),
      ]),
    );
  }
        }
