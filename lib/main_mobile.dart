import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() => runApp(MaterialApp(home: McrezilLobby(), debugShowCheckedModeBanner: false));

class McrezilLobby extends StatefulWidget {
  @override
  State<McrezilLobby> createState() => _McrezilLobbyState();
}

class _McrezilLobbyState extends State<McrezilLobby> {
  final Strategy strategy = Strategy.P2P_CLUSTER;
  String myName = "MCREZIL-${DateTime.now().millisecondsSinceEpoch % 1000}";
  bool isHosting = false;
  bool isJoining = false;
  List<String> connected = [];
  String status = "Players connected: 0";
  bool showQr = false;

  @override
  void initState() {
    super.initState();
    _askPerms();
  }

  Future<void> _askPerms() async {
    await [
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
      Permission.nearbyWifiDevices,
    ].request();
  }

  void hostGame() async {
    setState(() { isHosting = true; showQr = true; status = "Hosting as $myName..."; });
    try {
      bool a = await Nearby().startAdvertising(
        myName,
        strategy,
        onConnectionInitiated: (id, info) {
          Nearby().acceptConnection(id, onPayLoadRecieved: (ep, payload) {});
          setState(() { connected.add(info.endpointName); status = "Players connected: ${connected.length}"; });
        },
        onConnectionResult: (id, result) {
          if (result == Status.CONNECTED) {
            setState(() { status = "Player joined! Total: ${connected.length}"; });
          }
        },
        onDisconnected: (id) {
          setState(() { status = "Player left"; });
        },
      );
      print("Advertising: $a");
    } catch (e) {
      setState(() { status = "Error: $e"; });
    }
  }

  void joinGame() {
    setState(() { isJoining = true; status = "Scanning for hosts..."; });
    Nearby().startDiscovery(
      myName,
      strategy,
      onEndpointFound: (id, name, serviceId) {
        print("Found $name");
        Nearby().requestConnection(name, id, onConnectionInitiated: (id, info) {
          Nearby().acceptConnection(id, onPayLoadRecieved: (a,b){});
        }, onConnectionResult: (id, res) {
          setState(() { status = res == Status.CONNECTED ? "Connected to $name!" : "Failed to connect"; isJoining = false; });
        }, onDisconnected: (id) {
          setState(() { status = "Disconnected"; });
        });
      },
      onEndpointLost: (id) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("MCREZIL", style: TextStyle(color: Color(0xFF00FF88), fontSize: 48, fontWeight: FontWeight.bold)),
            Text("OFFLINE MULTIPLAYER", style: TextStyle(color: Colors.white54, letterSpacing: 2)),
            SizedBox(height: 40),
            
            if (!showQr && !isJoining) ...[
              ElevatedButton(
                onPressed: hostGame,
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00FF88), minimumSize: Size(220,50)),
                child: Text("HOST GAME", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: joinGame,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, minimumSize: Size(220,50)),
                child: Text("JOIN GAME", style: TextStyle(color: Colors.white)),
              ),
            ],

            if (showQr) ...[
              Container(color: Colors.white, padding: EdgeInsets.all(10), child: QrImageView(data: myName, size: 200)),
              SizedBox(height: 10),
              Text(myName, style: TextStyle(color: Colors.white)),
              Text("WiFi + Bluetooth ON", style: TextStyle(color: Colors.white54, fontSize: 12)),
              SizedBox(height: 20),
              ElevatedButton(onPressed: (){ Nearby().stopAdvertising(); setState((){showQr=false; isHosting=false;}); }, child: Text("STOP HOSTING")),
            ],

            if (isJoining && !showQr) ...[
              SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF00FF88))),
              SizedBox(height: 10),
              Text("Looking for hosts via WiFi Direct...", style: TextStyle(color: Colors.white54)),
              SizedBox(height: 20),
              Container(height: 200, width: 200, child: MobileScanner(onDetect: (capture){
                final code = capture.barcodes.first.rawValue;
                if(code!=null){ print("Scanned $code"); }
              })),
              SizedBox(height: 20),
              ElevatedButton(onPressed: (){ Nearby().stopDiscovery(); setState((){isJoining=false;}); }, child: Text("CANCEL")),
            ],

            SizedBox(height: 30),
            Text(status, style: TextStyle(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}
