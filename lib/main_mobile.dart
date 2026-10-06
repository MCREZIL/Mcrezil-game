import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() => runApp(MaterialApp(home: Lobby(), debugShowCheckedModeBanner: false));

class Lobby extends StatefulWidget {
  @override
  State<Lobby> createState() => _LobbyState();
}

class _LobbyState extends State<Lobby> {
  final Strategy strategy = Strategy.P2P_CLUSTER;
  String myName = "MCREZIL-${DateTime.now().millisecondsSinceEpoch % 1000}";
  bool hosting = false;
  bool joining = false;
  List<String> players = [];
  String status = "Players connected: 0";

  @override
  void initState() {
    super.initState();
    _perms();
  }

  Future<void> _perms() async {
    await [Permission.bluetoothAdvertise, Permission.bluetoothConnect, Permission.bluetoothScan, Permission.location, Permission.nearbyWifiDevices, Permission.camera].request();
  }

  void host() async {
    setState(() { hosting = true; status = "Hosting as $myName"; });
    await Nearby().startAdvertising(myName, strategy,
      onConnectionInitiated: (id, info) {
        Nearby().acceptConnection(id, onPayLoadRecieved: (a,b){});
        setState(() { players.add(info.endpointName); status = "Players connected: ${players.length}"; });
      },
      onConnectionResult: (id, res) {},
      onDisconnected: (id) {},
    );
  }

  void join() async {
    setState(() { joining = true; status = "Scanning via WiFi + Bluetooth..."; });
    await Nearby().startDiscovery(myName, strategy,
      onEndpointFound: (id, name, sid) {
        Nearby().requestConnection(name, id,
          onConnectionInitiated: (id, info) => Nearby().acceptConnection(id, onPayLoadRecieved: (a,b){}),
          onConnectionResult: (id, res) {
            if(res == Status.CONNECTED) setState(() { status = "Connected to $name!"; joining = false; });
          },
          onDisconnected: (id) {});
      },
      onEndpointLost: (id) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("MCREZIL", style: TextStyle(color: Color(0xFF00FF88), fontSize: 48, fontWeight: FontWeight.bold)),
          Text("OFFLINE MULTIPLAYER", style: TextStyle(color: Colors.white54, letterSpacing: 2)),
          SizedBox(height: 30),
          if (!hosting && !joining) ...[
            ElevatedButton(onPressed: host, style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00FF88), minimumSize: Size(220,50)), child: Text("HOST GAME", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
            SizedBox(height: 12),
            ElevatedButton(onPressed: join, style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, minimumSize: Size(220,50)), child: Text("JOIN GAME", style: TextStyle(color: Colors.white))),
          ],
          if (hosting) ...[
            Container(color: Colors.white, padding: EdgeInsets.all(12), child: QrImageView(data: myName, size: 180)),
            SizedBox(height: 10),
            Text(myName, style: TextStyle(color: Colors.white)),
            Text("WiFi + Bluetooth Auto", style: TextStyle(color: Colors.white54, fontSize: 12)),
            SizedBox(height: 20),
            ElevatedButton(onPressed: (){Nearby().stopAdvertising(); setState((){hosting=false; status="Players connected: 0";});}, child: Text("STOP")),
          ],
          if (joining) ...[
            SizedBox(height: 150, width: 200, child: MobileScanner(onDetect: (c){ final v=c.barcodes.first.rawValue; if(v!=null) print(v); })),
            SizedBox(height: 10),
            Text("QR Scanner + WiFi Scan", style: TextStyle(color: Colors.white54)),
            SizedBox(height: 20),
            ElevatedButton(onPressed: (){Nearby().stopDiscovery(); setState((){joining=false;});}, child: Text("CANCEL")),
          ],
          SizedBox(height: 25),
          Text(status, style: TextStyle(color: Colors.white38)),
        ]),
      ),
    );
  }
}
