import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const McrezilChase());
class McrezilChase extends StatelessWidget {
  const McrezilChase({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(debugShowCheckedModeBanner:false, home: ChaseGame());
}

class ChaseGame extends StatefulWidget {
  const ChaseGame({super.key});
  @override
  State<ChaseGame> createState() => _ChaseGameState();
}

class _ChaseGameState extends State<ChaseGame> {
  Offset player = const Offset(200,400);
  Offset stick = Offset.zero; // joystick -1 to 1
  double playerSpeed = 9.0; // YOU FAST
  double sprint = 1.0;

  List<Offset> hunters = [];
  List<double> hSpeed = [];
  List<Offset> coins = [];
  Random rand = Random();
  int score=0,best=0;
  bool playing=false, gameOver=false;
  Timer? loop;
  Size screen = const Size(400,700);

  void start(){
    setState((){
      playing=true; gameOver=false; score=0; stick=Offset.zero;
      player=Offset(screen.width/2, screen.height/2);
      hunters=[Offset(20,20), Offset(screen.width-20,20)];
      hSpeed=[1.1, 1.2]; // HUNTERS VERY SLOW NOW
      coins=List.generate(7, (_)=> Offset(rand.nextDouble()* (screen.width-40)+20, rand.nextDouble()*(screen.height-200)+100));
    });
    loop?.cancel();
    loop=Timer.periodic(const Duration(milliseconds:16), (_)=> tick());
  }
  void tick(){
    if(!playing) return;
    setState((){
      player += stick * playerSpeed * sprint;
      player=Offset(player.dx.clamp(22, screen.width-22), player.dy.clamp(90, screen.height-22));

      for(int i=0;i<hunters.length;i++){
        Offset d = player - hunters[i];
        double dist = d.distance;
        if(dist>1) hunters[i] += (d/dist) * hSpeed[i];
        if(dist < 32) { end(); return; }
      }
      coins.removeWhere((c){
        if((c-player).distance < 28){ score+=25; return true; }
        return false;
      });
      if(coins.length<5) coins.add(Offset(rand.nextDouble()*(screen.width-40)+20, rand.nextDouble()*(screen.height-200)+100));
      if(score%120==0 && score!=0 && hunters.length<8){
        hunters.add(Offset(rand.nextDouble()*screen.width, 0));
        hSpeed.add(1.0 + rand.nextDouble()*0.6); // stays slow
      }
      score++;
    });
  }
  void end(){
    loop?.cancel();
    setState((){ playing=false; gameOver=true; if(score>best) best=score; });
  }

  @override
  Widget build(BuildContext context){
    screen=MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1026),
      body: Stack(children:[
        // coins
        for(var c in coins) Positioned(left:c.dx-14,top:c.dy-14,child:Container(width:28,height:28,decoration:BoxDecoration(color:Colors.amber,shape:BoxShape.circle,border:Border.all(color:Colors.white,width:2)),child:const Icon(Icons.star,size:16,color:Colors.black))),
        // hunters - slower visual
        for(var h in hunters) Positioned(left:h.dx-18,top:h.dy-18,child:Container(width:36,height:36,decoration:BoxDecoration(color:Colors.redAccent.withOpacity(0.9),borderRadius:BorderRadius.circular(8),border:Border.all(color:Colors.white70,width:2)),child:const Icon(Icons.directions_run,color:Colors.white,size:20))),
        // player - FAST
        Positioned(left:player.dx-22,top:player.dy-22,child:Container(width:44,height:44,decoration:BoxDecoration(color:const Color(0xFF00FF88),shape:BoxShape.circle,border:Border.all(color:Colors.white,width:3),boxShadow: const [BoxShadow(color:Color(0xFF00FF88),blurRadius:20)]),child:Icon(Icons.bolt,color:Colors.black, size: sprint>1?28:22))),

        // HUD
        Positioned(top:40,left:15,right:15,child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
          Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text("MCREZIL CHASE",style:TextStyle(color:Color(0xFF00FF88),fontWeight:FontWeight.w900,letterSpacing:2)),Text("SCORE $score BEST $best",style:const TextStyle(fontWeight:FontWeight.bold,fontSize:13))]),
          Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),decoration:BoxDecoration(color:Colors.white10,borderRadius:BorderRadius.circular(20)),child:Text("HUNTERS:${hunters.length}",style:const TextStyle(fontSize:11)))
        ])),

        // NEW WORKING JOYSTICK - left side
        Positioned(left:20,bottom:30,child: GestureDetector(
          onPanStart: (d){ _updateStick(d.localPosition); },
          onPanUpdate: (d){ _updateStick(d.localPosition); },
          onPanEnd: (_){ setState(()=> stick=Offset.zero); },
          child: Container(width:130,height:130,decoration:BoxDecoration(shape:BoxShape.circle,color:Colors.white.withOpacity(0.08),border:Border.all(color:Colors.white24,width:2)),
            child: Center(child: AnimatedContainer(duration:const Duration(milliseconds:50), transform: Matrix4.translationValues(stick.dx*40, stick.dy*40, 0),
              width:60,height:60,decoration:const BoxDecoration(shape:BoxShape.circle,color:Color(0xFF00FF88)), child:const Icon(Icons.gamepad,color:Colors.black),
            )),
          ),
        )),

        // SPRINT BUTTON - right side
        Positioned(right:20,bottom:40,child: GestureDetector(
          onTapDown: (_)=> setState(()=> sprint=1.8),
          onTapUp: (_)=> setState(()=> sprint=1.0),
          onTapCancel: ()=> setState(()=> sprint=1.0),
          child: Container(width:90,height:90,decoration:BoxDecoration(shape:BoxShape.circle,color: sprint>1?Colors.orange:Colors.white12,border:Border.all(color:Colors.white24,width:2)),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.flash_on,color:sprint>1?Colors.black:Colors.white),Text(sprint>1?"SPRINT!":"HOLD\nSPRINT",textAlign:TextAlign.center,style:TextStyle(fontSize:10,fontWeight:FontWeight.bold,color:sprint>1?Colors.black:Colors.white))]),
          ),
        )),

        if(!playing) Container(color:Colors.black.withOpacity(0.82),child:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
          const Text("MCREZIL",style:TextStyle(fontSize:54,fontWeight:FontWeight.w900,color:Color(0xFF00FF88),letterSpacing:5)),
          Text(gameOver?"CAUGHT!":"CHASE",style:TextStyle(fontSize:30,letterSpacing:8,fontWeight:FontWeight.bold,color:gameOver?Colors.redAccent:Colors.white)),
          const SizedBox(height:8),
          Text("You scored $score",style:const TextStyle(color:Colors.white70)),
          const SizedBox(height:28),
          ElevatedButton(onPressed:start,style:ElevatedButton.styleFrom(backgroundColor:const Color(0xFF00FF88),foregroundColor:Colors.black,padding:const EdgeInsets.symmetric(horizontal:60,vertical:18)),child:Text(gameOver?"RUN AGAIN":"PLAY",style:const TextStyle(fontWeight:FontWeight.w900))),
          const SizedBox(height:18),
          const Text("LEFT pad = move (works now!)\nRIGHT button = HOLD to SPRINT\nYou are 4x faster than hunters!",textAlign:TextAlign.center,style:TextStyle(color:Colors.white54,fontSize:13)),
        ]))),
      ]),
    );
  }
  void _updateStick(Offset local){
    // local is inside 130x130 box, center at 65,65
    Offset center = const Offset(65,65);
    Offset diff = local - center;
    double max = 50;
    double dist = diff.distance;
    if(dist>max) diff = (diff/dist)*max;
    setState(()=> stick = diff / max); // -1 to 1
  }
}
