import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wheeler/utils/ui_utils.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:wheeler/model/spinner_segment_model.dart';

/// Widget for managing current wheel segments with premium styling
class CurrentSegmentCard extends StatefulWidget {
  final Wheel currentWheel;
  final Function(List<SpinnerSegment>) onSegmentsUpdated;

  const CurrentSegmentCard({
    super.key,
    required this.currentWheel,
    required this.onSegmentsUpdated,
  });

  @override
  _CurrentSegmentCardState createState() => _CurrentSegmentCardState();
}

class _CurrentSegmentCardState extends State<CurrentSegmentCard> {
  final ImagePicker _picker = ImagePicker();

  Future<String?> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}';
        final savedImage = await File(
          pickedFile.path,
        ).copy('${appDir.path}/$fileName');
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
    Color selectedColor = isEditing ? segment.color : const Color(0xFFF48FB1);
    Color selectedTextColor = isEditing ? segment.textColor : Colors.white;
    Color selectedStrokeColor = isEditing ? segment.strokeColor : Colors.black;
    int selectedFontSize = isEditing ? segment.fontSize!.round() : 17;
    String? backgroundImagePath = isEditing ? segment.imagePath : null;
    String? centerImagePath = isEditing ? segment.centerImagePath : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF16213e),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                isEditing ? 'Edit Segment' : 'Add New Segment',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Theme(
                data: ThemeData.dark(),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text Input
                      TextField(
                        controller: textController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Segment Text',
                          labelStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFF48FB1)),
                          ),
                        ),
                        maxLength: 50,
                      ),
                      const SizedBox(height: 16),

                      // Color Pickers
                      _buildColorOption(
                        'Background Color',
                        selectedColor,
                        (color) => dialogSetState(() => selectedColor = color),
                      ),
                      const SizedBox(height: 16),

                      // Image Pickers
                      _buildImageOption(
                        'Background Image',
                        backgroundImagePath,
                        () async {
                          final path = await _pickImage();
                          if (path != null)
                            dialogSetState(() => backgroundImagePath = path);
                        },
                        () => dialogSetState(() => backgroundImagePath = null),
                      ),
                      const SizedBox(height: 16),
                      _buildImageOption(
                        'Center Icon/Image',
                        centerImagePath,
                        () async {
                          final path = await _pickImage();
                          if (path != null)
                            dialogSetState(() => centerImagePath = path);
                        },
                        () => dialogSetState(() => centerImagePath = null),
                      ),
                      const SizedBox(height: 16),

                      // Font Size Slider
                      Text(
                        'Font Size: ${selectedFontSize.round()}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Slider(
                        value: selectedFontSize.roundToDouble(),
                        min: 12,
                        max: 25,
                        activeColor: const Color(0xFFF48FB1),
                        inactiveColor: Colors.white12,
                        onChanged: (value) => dialogSetState(
                          () => selectedFontSize = value.round(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildColorOption(
                        'Text Color',
                        selectedTextColor,
                        (color) =>
                            dialogSetState(() => selectedTextColor = color),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'CANCEL',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final updatedSegments = List<SpinnerSegment>.from(
                      widget.currentWheel.segments,
                    );
                    final newSegment = SpinnerSegment(
                      text: textController.text,
                      color: selectedColor,
                      imagePath: backgroundImagePath,
                      centerImagePath: centerImagePath,
                      fontSize: selectedFontSize,
                      textColor: selectedTextColor,
                      strokeColor: selectedStrokeColor,
                    );
                    if (isEditing) {
                      updatedSegments[index] = newSegment;
                    } else {
                      updatedSegments.add(newSegment);
                    }
                    widget.onSegmentsUpdated(updatedSegments);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF48FB1),
                    foregroundColor: Colors.black,
                  ),
                  child: Text(isEditing ? 'SAVE' : 'ADD'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildColorOption(
    String label,
    Color color,
    Function(Color) onPicked,
  ) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () async {
            Color pickerColor = color;
            final Color? pickedColor = await showDialog<Color>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF1a1a2e),
                title: const Text(
                  'Pick a color',
                  style: TextStyle(color: Colors.white),
                ),
                content: SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: pickerColor,
                    onColorChanged: (c) => pickerColor = c,
                    enableAlpha: false,
                    showLabel: false,
                    paletteType: PaletteType.hsv,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(pickerColor),
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Color(0xFFF48FB1)),
                    ),
                  ),
                ],
              ),
            );
            if (pickedColor != null) onPicked(pickedColor);
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageOption(
    String label,
    String? currentPath,
    VoidCallback onPick,
    VoidCallback onClear,
  ) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (currentPath != null)
          Container(
            margin: const EdgeInsets.only(right: 8),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: FileImage(File(currentPath)),
                fit: BoxFit.cover,
              ),
            ),
          ),
        IconButton(
          icon: Icon(
            currentPath != null
                ? Icons.edit_rounded
                : Icons.add_a_photo_rounded,
            color: const Color(0xFFF48FB1),
            size: 20,
          ),
          onPressed: onPick,
        ),
        if (currentPath != null)
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.redAccent,
              size: 20,
            ),
            onPressed: onClear,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213e).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFFF48FB1),
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text(
                  'WHEEL SEGMENTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.currentWheel.segments.length}/12',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          ...widget.currentWheel.segments.asMap().entries.map((entry) {
            int index = entry.key;
            SpinnerSegment segment = entry.value;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: segment.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                title: Text(
                  segment.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white38,
                        size: 18,
                      ),
                      onPressed: () =>
                          _showSegmentDialog(index: index, segment: segment),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_rounded,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      onPressed: () {
                        if (widget.currentWheel.segments.length <= 2) {
                          UIUtils.showMessageDialog(
                            context,
                            title: 'Required',
                            message: 'At least 2 segments are required',
                            isError: true,
                          );
                          return;
                        }
                        final updatedSegments = List<SpinnerSegment>.from(
                          widget.currentWheel.segments,
                        );
                        updatedSegments.removeAt(index);
                        widget.onSegmentsUpdated(updatedSegments);
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF48FB1),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (widget.currentWheel.segments.length >= 12) {
                    UIUtils.showMessageDialog(
                      context,
                      title: 'Limit reached',
                      message: 'Maximum 12 segments allowed',
                      isError: true,
                    );
                  } else {
                    _showSegmentDialog();
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'ADD NEW SEGMENT',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
