// fullScreenWheel.dart
import 'package:flutter/material.dart';
import 'package:wheeler/model/spinner_segment_model.dart';
import 'package:wheeler/widget/wheel_card.dart';

class FullScreenWheelPage extends StatelessWidget {
  final List<SpinnerSegment> segments;
  final String wheelName;
  final Function(String result, Color color)? onSpinComplete; // Add this

  const FullScreenWheelPage({
    super.key,
    required this.segments,
    required this.wheelName,
    this.onSpinComplete, // Optional callback
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.blue[800]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(onPressed: (){
              Navigator.pop(context);
            }, icon: Icon(Icons.close,color: Colors.red,size: 25,)),
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: Center(
          child: WheelCard(
            segments: segments,
            wheelName: wheelName,
            isFullScreen: true,
            onSpinComplete: (result, color) {
              // Forward the result to parent (HomePage)
              onSpinComplete?.call(result, color);
            },
          ),
        ),
      ),
    );
  }
}