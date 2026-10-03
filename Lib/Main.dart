// MCREZIL GAME LABS v3.2.1 FINAL - Host chooses Hunters BEFORE start
import 'package:flutter/material.dart';
void main()=>runApp(MaterialApp(home:Lobby(),debugShowCheckedModeBanner:false,theme:ThemeData.dark()));

class Player{String name;bool isHunter=false;bool isHost=false;Player(this.name);}
class Lobby extends StatefulWidget{ @override _L createState()=>_L();}
class _L extends State<Lobby>{
 List<Player> p=[Player("MCREZIL (Host)")..isHost=true, Player("Player 2")];
 add(){if(p.length<10) setState(()=>p.add(Player("Player ${p.length+1}")));}
 start(){if(p.length>=2) Navigator.push(context, MaterialPageRoute(builder:(_)=>Scaffold(body:Center(child:Text("GAME STARTED WITH ${p.length} - MCREZIL MAP"))))); }
 @override Widget build(BuildContext c){
  return Scaffold(appBar: AppBar(title:Text("MCREZIL LABS v3.2.1 ${p.length}/10"),backgroundColor:Colors.black),
  body:Column(children:[
    Padding(padding:EdgeInsets.all(8),child:Text("Host chooses Hunters BEFORE start | Late joiners = Runners",style:TextStyle(color:Colors.amber))),
    Expanded(child:ListView.builder(itemCount:p.length,itemBuilder:(_,i)=>ListTile(title:Text(p[i].name + (p[i].isHost?" (HOST)":"")), subtitle:Text(p[i].isHunter?"HUNTER":"RUNNER"), trailing: i==0?null:Switch(value:p[i].isHunter,onChanged:(v)=>setState(()=>p[i].isHunter=v),activeColor:Colors.red),))),
    ElevatedButton(onPressed:add, child:Text("ADD PLAYER (Simulate Bluetooth/WiFi/QR Join)")), 
    ElevatedButton(onPressed:start, child:Text("START GAME WITH ${p.length}/10"),style:ElevatedButton.styleFrom(backgroundColor:Colors.white,foregroundColor:Colors.black,minimumSize:Size(300,50))),
    SizedBox(height:10)
  ]));
 }
}
