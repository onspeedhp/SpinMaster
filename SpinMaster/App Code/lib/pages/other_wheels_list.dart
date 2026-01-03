import 'package:flutter/material.dart';
import '../screens/other_wheel_page.dart';
import '../data/wheel_data.dart';

class OtherWheels extends StatelessWidget {
  const OtherWheels({super.key});

  final List<String> items = const [
    "Dogs name generator",
    "Cat name generator",
    "Truth or Dare",
    "Wheel of Names",
    "Random number generator",
    "Yes or No",
    "Random Song",
    "Random place generator",
    "Random food generator",
    "Games generator",
    "What to do in quarantine",
    "Dog Breed selector",
    "Random letter generator",
    "Random color picker",
    "Random team generator",
    "Random name picker",
    "Love me or Loves me Not",
    "What should I do Today",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue[800],
        title: const Text("Custom Wheels"),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Card(
            color: Colors.grey[100],
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[800],
                child: Text(
                  "${index + 1}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(items[index]),
              onTap: () {
                // Navigate to the selected wheel
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OtherWheelPage(
                      wheelName: items[index],
                      // For Dog and Cat name generators, we'll use the predefined segments
                      // For other wheels, we'll use the wheelSegments map or default segments
                      initialSegments: wheelSegments[items[index]] ?? defaultSegments,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}