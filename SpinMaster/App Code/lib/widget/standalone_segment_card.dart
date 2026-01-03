import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../model/spinner_segment_model.dart'; // <-- Your model

class StandaloneSegmentCard extends StatefulWidget {
  final List<SpinnerSegment> segments;
  final Function(List<SpinnerSegment>) onSegmentsUpdated;

  const StandaloneSegmentCard({
    super.key,
    required this.segments,
    required this.onSegmentsUpdated,
  });

  @override
  State<StandaloneSegmentCard> createState() => _StandaloneSegmentCardState();
}

class _StandaloneSegmentCardState extends State<StandaloneSegmentCard> {
  final ImagePicker _picker = ImagePicker();

  Future<String?> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}';
        final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
        return savedImage.path;
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    return null;
  }

  void _showSegmentDialog({int? index, SpinnerSegment? segment}) {
    final bool isEditing = index != null && segment != null;

    final TextEditingController textController = TextEditingController(
      text: isEditing ? segment.text : '',
    );

    Color selectedColor = isEditing ? segment.color : Colors.blue;
    Color selectedTextColor = isEditing ? segment.textColor : Colors.black;
    Color selectedStrokeColor = isEditing ? segment.strokeColor : Colors.white;
    int selectedFontSize = isEditing ? segment.fontSize ?? 17 : 17;
    String? backgroundImagePath = isEditing ? segment.imagePath : null;
    String? centerImagePath = isEditing ? segment.centerImagePath : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Segment' : 'Add New Segment'),
              contentPadding: const EdgeInsets.all(20),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text Input
                      TextField(
                        controller: textController,
                        decoration: const InputDecoration(
                          labelText: 'Segment Text',
                          border: OutlineInputBorder(),
                        ),
                        maxLength: 50,
                      ),
                      const SizedBox(height: 16),

                      // Background Color
                      const Text('Background Color:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final Color? picked = await showDialog<Color>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Pick Background Color'),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  pickerColor: selectedColor,
                                  onColorChanged: (c) => selectedColor = c,
                                  enableAlpha: false,
                                  showLabel: false,
                                  paletteType: PaletteType.hsv,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, selectedColor),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                          if (picked != null) dialogSetState(() => selectedColor = picked);
                        },
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            shape: BoxShape.circle,
                            border: Border.all(width: 2, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Background Image
                      const Text('Background Image:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (backgroundImagePath != null)
                            CircleAvatar(radius: 20, backgroundImage: FileImage(File(backgroundImagePath!))),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(backgroundImagePath != null ? Icons.edit : Icons.image),
                            onPressed: () async {
                              final path = await _pickImage();
                              if (path != null) dialogSetState(() => backgroundImagePath = path);
                            },
                          ),
                          if (backgroundImagePath != null)
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => dialogSetState(() => backgroundImagePath = null),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Center Image
                      const Text('Center Image:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (centerImagePath != null)
                            CircleAvatar(radius: 20, backgroundImage: FileImage(File(centerImagePath!))),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(centerImagePath != null ? Icons.edit : Icons.image),
                            onPressed: () async {
                              final path = await _pickImage();
                              if (path != null) dialogSetState(() => centerImagePath = path);
                            },
                          ),
                          if (centerImagePath != null)
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => dialogSetState(() => centerImagePath = null),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Font Size
                      Text('Font Size: $selectedFontSize', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Slider(
                        value: selectedFontSize.toDouble(),
                        min: 12,
                        max: 25,
                        divisions: 13,
                        onChanged: (v) => dialogSetState(() => selectedFontSize = v.round()),
                      ),
                      const SizedBox(height: 16),

                      // Text Color
                      const Text('Text Color:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final Color? picked = await showDialog<Color>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Pick Text Color'),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  pickerColor: selectedTextColor,
                                  onColorChanged: (c) => selectedTextColor = c,
                                  enableAlpha: false,
                                  showLabel: false,
                                  paletteType: PaletteType.hsv,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, selectedTextColor),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                          if (picked != null) dialogSetState(() => selectedTextColor = picked);
                        },
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: selectedTextColor,
                            shape: BoxShape.circle,
                            border: Border.all(width: 2, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Stroke Color
                      const Text('Stroke Color:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final Color? picked = await showDialog<Color>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Pick Stroke Color'),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  pickerColor: selectedStrokeColor,
                                  onColorChanged: (c) => selectedStrokeColor = c,
                                  enableAlpha: false,
                                  showLabel: false,
                                  paletteType: PaletteType.hsv,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, selectedStrokeColor),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                          if (picked != null) dialogSetState(() => selectedStrokeColor = picked);
                        },
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: selectedStrokeColor,
                            shape: BoxShape.circle,
                            border: Border.all(width: 2, color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (textController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Segment text is required')),
                      );
                      return;
                    }

                    final newSegment = SpinnerSegment(
                      text: textController.text.trim(),
                      color: selectedColor,
                      imagePath: backgroundImagePath,
                      centerImagePath: centerImagePath,
                      fontSize: selectedFontSize,
                      textColor: selectedTextColor,
                      strokeColor: selectedStrokeColor,
                    );

                    final updated = List<SpinnerSegment>.from(widget.segments);
                    if (isEditing) {
                      updated[index] = newSegment;
                    } else {
                      updated.add(newSegment);
                    }

                    widget.onSegmentsUpdated(updated);
                    Navigator.pop(context);
                  },
                  child: Text(isEditing ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteSegment(int index) {
    if (widget.segments.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 2 segments are required')),
      );
      return;
    }
    final updated = List<SpinnerSegment>.from(widget.segments)..removeAt(index);
    widget.onSegmentsUpdated(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          // Segment List
          ...widget.segments.asMap().entries.map((entry) {
            final index = entry.key;
            final segment = entry.value;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: segment.color,
                radius: 16,
              ),
              title: Text(
                segment.text,
                style: TextStyle(
                  fontSize: segment.fontSize?.toDouble() ?? 17,
                  color: segment.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showSegmentDialog(index: index, segment: segment),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteSegment(index),
                  ),
                ],
              ),
            );
          }),

          // Add Button + Counter
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    if (widget.segments.length >= 12) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Maximum 12 segments allowed')),
                      );
                      return;
                    }
                    _showSegmentDialog();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Segment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                Text(
                  '${widget.segments.length}/12',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.segments.length > 12
                        ? Colors.red
                        : widget.segments.length < 2
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}