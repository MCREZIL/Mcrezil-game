// MCREZIL GAMES - OFFLINE CHASE V1.0 FINAL
// Same features you asked: Bluetooth + WiFi Direct + QR, 100% offline
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner:false, home: McrezilLobby()));

enum Role { hunter, runner }

class Player {
  String id; String name; Role role; bool isHost;
  Player({required this.id, required this.name, this.role=Role.runner, this.isHost=false});
}

class McrezilLobby extends StatefulWidget {
  const McrezilLobby({super.key});
  @override State<McrezilLobby> createState() => _McrezilLobbyState();
}

class _McrezilLobbyState extends State<McrezilLobby> {
  List<Player> players = [Player(id:"host", name:"You (Host)", role:Role.hunter, isHost:true)];
  bool started = false;
  String roomCode = "MCREZIL-${Random().nextInt(9000)+1000}";
  final Strategy strategy = Strategy.P2P_CLUSTER; // best for games

  @override
  void initState(){ super.initState(); _startHost(); }

  Future<void> _startHost() async {
    await Nearby().startAdvertising(
      "MCREZIL-Host", strategy,
      onConnectionInitiated: (id, info){
        if(players.length>=10){ Nearby().rejectConnection(id); return; }
        Nearby().acceptConnection(id, onPayLoadRecieved: (a,p){});
      },
      onConnectionResult: (id, status){
        if(status==Status.CONNECTED){
          setState((){
            if(started){
              players.add(Player(id:id, name:"Runner ${players.length+1}", role:Role.runner));
            } else {
              players.add(Player(id:id, name:"Player ${players.length+1}", role:Role.runner));
            }
          });
        }
      },
      onDisconnected: (id)=> setState(()=> players.removeWhere((p)=>p.id==id)),
    );
  }

  void _start(){
    if(players.length<2) return;
    if(players.where((p)=>p.role==Role.hunter).isEmpty) return;
    setState(()=> started=true);
    Nearby().sendBytesPayloadToAll("START");
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFF0B1026),
      body: Column(children:[
        const SizedBox(height:40),
        Center(child: QrImageView(data:"MCREZIL://$roomCode", size:130, backgroundColor: Colors.white)),
        const SizedBox(height:10),
        Text("MCREZIL GAMES • Room $roomCode", style:const TextStyle(color:Color(0xFF00FF88), fontWeight:FontWeight.w900)),
        const Text("Bluetooth + WiFi Direct • 100% Offline", style:TextStyle(color:Colors.amber, fontSize:11)),
        const SizedBox(height:10),
        Expanded(child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2, childAspectRatio:1.3),
          itemCount:10,
          itemBuilder: (c,i){
            if(i>=players.length) return const Card(color:Colors.white10, child: Center(child: Text("+ Invite Player")));
            var p=players[i];
            return Card(color: p.role==Role.hunter? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
              child: Column(mainAxisAlignment:MainAxisAlignment.center, children:[
                Text(p.name, style:const TextStyle(color:Colors.white, fontWeight:FontWeight.bold)),
                const SizedBox(height:6),
                Row(mainAxisAlignment:MainAxisAlignment.center, children:[
                  ChoiceChip(label:const Text("HUNTER", style:TextStyle(fontSize:9)), selected:p.role==Role.hunter, onSelected: started? null : (_)=> setState(()=> p.role=Role.hunter)),
                  const SizedBox(width:4),
                  ChoiceChip(label:const Text("RUNNER", style:TextStyle(fontSize:9)), selected:p.role==Role.runner, onSelected: started? null : (_)=> setState(()=> p.role=Role.runner)),
                ])
              ]),
            );
          },
        )),
        Padding(padding: const EdgeInsets.all(12), child:
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF88), minimumSize: const Size(double.infinity, 55)),
            onPressed: _start,
            child: Text("START MCREZIL GAME (${players.length}/10)", style: const TextStyle(color:Colors.black, fontWeight:FontWeight.w900)),
          )
        ),
        if(started) const Text("Game Started! Late joiners = Runners only", style:TextStyle(color:Colors.green, fontSize:11)),
        const SizedBox(height:10),
      ]),
    );
  }
}
