import 'package:flutter/material.dart';

void main() => runApp(McrezilApp());

class McrezilApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MCREZIL GAME LABS',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> players = ["Host (You)"];
  String gameCode = "MCREZIL-321";
  bool gameStarted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MCREZIL v3.2.1'), backgroundColor: Colors.orange[900]),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              color: Colors.grey[900],
              child: Text('GAME CODE: $gameCode\nPackage: com.mcrezil.gamelabs\nOffline: Bluetooth + WiFi Direct', style: TextStyle(fontFamily: 'monospace')),
            ),
            SizedBox(height: 20),
            Text('Players (${players.length}/10):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
           ...players.map((p) => ListTile(title: Text(p), leading: Icon(Icons.person))),
            Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: EdgeInsets.all(16)),
              onPressed: () => setState(() {
                if(players.length < 10) players.add("Runner ${players.length + 1}");
              }),
              child: Text('ADD RUNNER (Simulate QR Join)', style: TextStyle(fontSize: 18)),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: EdgeInsets.all(16)),
              onPressed: () => setState(() => gameStarted = true),
              child: Text(gameStarted? 'GAME STARTED! CHASING...' : 'START CHASE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            if(gameStarted) Padding(
              padding: EdgeInsets.only(top:10),
              child: Text('Rules: 2 Hunters, 8 Runners. Host picked BEFORE start. Late joiners = Runners auto.', textAlign: TextAlign.center, style: TextStyle(color: Colors.yellow)),
            )
          ],
        ),
      ),
    );
  }
}
