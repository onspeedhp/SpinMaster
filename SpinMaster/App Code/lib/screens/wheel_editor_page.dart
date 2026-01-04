import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:wheeler/services/wheel_manage.dart';
import 'package:wheeler/model/spinner_segment_model.dart';

class WheelEditorPage extends StatefulWidget {
  final Wheel? wheelToEdit;

  const WheelEditorPage({super.key, this.wheelToEdit});

  @override
  State<WheelEditorPage> createState() => _WheelEditorPageState();
}

class _WheelEditorPageState extends State<WheelEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late List<SpinnerSegment> _segments;

  final List<Color> _presetColors = [
    Colors.purpleAccent,
    Colors.blueAccent,
    Colors.redAccent,
    Colors.amber,
    Colors.green,
    Colors.pinkAccent,
    Colors.teal,
    Colors.orange,
    Colors.indigoAccent,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.wheelToEdit?.name ?? '',
    );
    _segments =
        widget.wheelToEdit?.segments.toList() ??
        [
          SpinnerSegment(text: 'Yes', color: Colors.green),
          SpinnerSegment(text: 'No', color: Colors.redAccent),
          SpinnerSegment(text: 'Maybe', color: Colors.amber),
        ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addSegment() {
    setState(() {
      _segments.add(
        SpinnerSegment(
          text: 'Option ${_segments.length + 1}',
          color: _presetColors[_segments.length % _presetColors.length],
        ),
      );
    });
  }

  void _removeSegment(int index) {
    if (_segments.length > 2) {
      setState(() {
        _segments.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wheel must have at least 2 segments')),
      );
    }
  }

  void _saveWheel() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<WheelProvider>(context, listen: false);

      if (widget.wheelToEdit != null) {
        // Update existing
        final updatedWheel = widget.wheelToEdit!.copyWith(
          name: _nameController.text,
          segments: _segments,
        );
        provider.updateWheel(updatedWheel.id, updatedWheel);
      } else {
        // Create new
        final newWheel = Wheel(
          id: const Uuid().v4(),
          name: _nameController.text.isEmpty
              ? 'My Custom Wheel'
              : _nameController.text,
          segments: _segments,
          createdAt: DateTime.now(),
        );
        provider.addWheel(newWheel);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.wheelToEdit != null ? 'EDIT WHEEL' : 'CREATE WHEEL',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded, color: Color(0xFFF48FB1)),
            onPressed: _saveWheel,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Wheel Name Input
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Wheel Name',
                labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFF48FB1)),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SEGMENTS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addSegment,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Add Option'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFF48FB1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Segments List
            ..._segments.asMap().entries.map((entry) {
              final index = entry.key;
              final segment = entry.value;

              return Container(
                key: ValueKey('segment_${index}_${segment.color.value}'),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    // Color Picker (Simplified)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          // Cycle through colors
                          final currentIndex = _presetColors.indexOf(
                            segment.color,
                          );
                          final nextColor =
                              _presetColors[(currentIndex + 1) %
                                  _presetColors.length];
                          _segments[index] = segment.copyWith(color: nextColor);
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: segment.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Text Input
                    Expanded(
                      child: TextFormField(
                        initialValue: segment.text,
                        style: const TextStyle(color: Colors.white),
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText: 'Option Text',
                          hintStyle: const TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          suffixIcon: Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        onChanged: (value) {
                          _segments[index] = segment.copyWith(text: value);
                        },
                      ),
                    ),
                    // Remove Button
                    if (_segments.length > 2)
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white24,
                        ),
                        onPressed: () => _removeSegment(index),
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _saveWheel,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF48FB1),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'SAVE WHEEL',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
