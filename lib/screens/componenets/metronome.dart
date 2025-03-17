import 'dart:async';
import 'dart:html';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class MetronomeApp extends StatefulWidget {
  
  final int input1;
  final int input2;

  MetronomeApp({required this.input1, required this.input2});

  @override
  _MetronomeAppState createState() => _MetronomeAppState();
}

class _MetronomeAppState extends State<MetronomeApp> {
  Timer? _timer;
  int bpm = 100; // Beats per minute
  bool isPlaying = false;
  final AudioElement beep = AudioElement('assets/assets/sounds/beat.mp3');
  bool isPlaying2 = false;
  bool isMuted = false;

  void startMetronome() {
    if (isPlaying) return;
    isPlaying = true;
    int interval = (60000 / bpm).round(); // Convert BPM to milliseconds
    _timer = Timer.periodic(Duration(milliseconds: interval), (timer) {
      if (!isMuted) {
        beep.play();
      }
    });
  }

  void stopMetronome() {
    _timer?.cancel();
    isPlaying = false;
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    bpm = widget.input1 + 2;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
          child: Container(
            padding: EdgeInsets.all(20),
            //height: 200,
            //width: 200,
            child: Column(
              spacing: 12,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  spacing: 8,
                  mainAxisSize:  MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Metronome",style: TextStyle(fontWeight: FontWeight.w800,fontSize:16),),
                    SizedBox(width: 20,),
                    InkWell(
                  onTap: () {
                    setState(() {
                      isMuted = !isMuted;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isMuted ? Colors.red : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(width: 1, color: Colors.black),
                    ),
                    child: HugeIcon(
                      icon: isMuted
                          ? HugeIcons.strokeRoundedVolumeOff
                          : HugeIcons.strokeRoundedVolumeUp,
                      color: isMuted ? Colors.white : Colors.black,
                      size: 19,
                    ),
                  ),
                ),
                    InkWell(onTap: (){
                      if(isPlaying2==false){
                        startMetronome();
                        setState(() {
                          isPlaying2 = true;
                        });
                      }
                      else if(isPlaying2==true){
                        stopMetronome();
                        setState(() {
                          isPlaying2 = false;
                        });
                      }
                    },
                    
                    child: Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: isPlaying2? Colors.black: Colors.white,
                        borderRadius: BorderRadius.circular(10)
                        ,border: Border.all(width: 1,color: Colors.black)
                
                      ),
                      child: HugeIcon(icon: isPlaying2?  HugeIcons.strokeRoundedPause: HugeIcons.strokeRoundedPlay, color: isPlaying2? Colors.white: Colors.black,size: 19,))),
                    
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 170,
                      child: Slider(
                      thumbColor: Colors.black,
                      activeColor: Colors.black,
                        value: bpm.toDouble(),
                        min: widget.input1.toDouble(),
                        max: widget.input2.toDouble(),
                        divisions: widget.input2 - widget.input1,
                        label: '$bpm BPM',
                        onChanged: (value) {
                          setState(() {
                            bpm = value.toInt();
                          });
                        },
                      ),
                    ),
                    Text('$bpm\nBPM', style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),textAlign: TextAlign.center,),
                  ],
                ),
                
              ],
            ),
          ),
        );
      
    
  }
}
