import 'package:flutter/material.dart';
import 'dart:math';
import 'package:wheeler/widget/wheel_card.dart';
import 'package:provider/provider.dart';
import 'package:wheeler/services/wheel_manage.dart';
import 'package:wheeler/model/spinner_segment_model.dart';

class CustomWheelPlayPage extends StatefulWidget {
  final Wheel wheel;

  const CustomWheelPlayPage({super.key, required this.wheel});

  @override
  State<CustomWheelPlayPage> createState() => _CustomWheelPlayPageState();
}

class _CustomWheelPlayPageState extends State<CustomWheelPlayPage> {
  // Simulate a network delay and return a random index
  Future<int?> _handleSpinRequest() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    // Return random index
    return Random().nextInt(widget.wheel.segments.length);
  }

  void _onSpinComplete(String result, Color color) {
    setState(() {
      // Create updated history list
      final updatedHistory = List<String>.from(widget.wheel.history)
        ..insert(0, result);

      // Keep only last 20
      if (updatedHistory.length > 20) {
        updatedHistory.removeLast();
      }

      // Update wheel via provider
      final provider = Provider.of<WheelProvider>(context, listen: false);
      final updatedWheel = widget.wheel.copyWith(history: updatedHistory);
      provider.updateWheel(widget.wheel.id, updatedWheel);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get live wheel data from provider to show history updates
    final wheel =
        Provider.of<WheelProvider>(context).getWheelById(widget.wheel.id) ??
        widget.wheel;

    return Scaffold(
      backgroundColor: const Color(0xFF16213e), // Matching home background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.wheel.name.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Wheel Section
            Expanded(
              flex: 5,
              child: Center(
                child: WheelCard(
                  wheelName: wheel.name,
                  segments: wheel.segments,
                  onSpinRequest: _handleSpinRequest,
                  onSpinComplete: _onSpinComplete,
                  isFullScreen: false,
                ),
              ),
            ),

            // History Section
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1a2e),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        'SESSION HISTORY',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: wheel.history.isEmpty
                          ? Center(
                              child: Text(
                                'Spin the wheel to see results!',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: wheel.history.length,
                              itemBuilder: (context, index) {
                                final result = wheel.history[index];
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '#${wheel.history.length - index}',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          result,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF48FB1),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
