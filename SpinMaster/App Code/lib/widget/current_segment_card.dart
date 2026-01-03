import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wheeler/utils/ui_utils.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:wheeler/model/spinner_segment_model.dart';

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
    Color selectedColor = isEditing ? segment.color : Colors.blue;
    Color selectedTextColor = isEditing ? segment.textColor : Colors.black;
    Color selectedStrokeColor = isEditing ? segment.strokeColor : Colors.white;
    int selectedFontSize = isEditing ? segment.fontSize!.round() : 17;
    String? backgroundImagePath = isEditing ? segment.imagePath : null;
    String? centerImagePath = isEditing ? segment.centerImagePath : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Segment' : 'Add New Segment'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text Input
                    TextField(
                      controller: textController,
                      decoration: InputDecoration(labelText: 'Segment Text'),
                      maxLength: 50,
                    ),
                    SizedBox(height: 16),

                    // Background Color Picker (Gradient-based)
                    Text(
                      'Background Color:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final Color? pickedColor = await showDialog<Color>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Pick a color'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: selectedColor,
                                onColorChanged: (color) =>
                                    selectedColor = color,
                                colorPickerWidth: 300,
                                pickerAreaHeightPercent: 0.7,
                                enableAlpha: false,
                                displayThumbColor: true,
                                showLabel: false,
                                paletteType: PaletteType.hsv,
                                pickerAreaBorderRadius: BorderRadius.circular(
                                  12,
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(selectedColor),
                                child: Text('OK'),
                              ),
                            ],
                          ),
                        );
                        if (pickedColor != null) {
                          dialogSetState(() => selectedColor = pickedColor);
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Background Image Picker (CircleAvatar if image is selected)
                    Text(
                      'Background Image:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        if (backgroundImagePath != null)
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: FileImage(
                              File(backgroundImagePath!),
                            ),
                          ),
                        IconButton(
                          icon: Icon(Icons.image, size: 24),
                          onPressed: () async {
                            final newImagePath = await _pickImage();
                            if (newImagePath != null) {
                              dialogSetState(
                                () => backgroundImagePath = newImagePath,
                              );
                            }
                          },
                        ),
                        if (backgroundImagePath != null)
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.red,
                            ),
                            onPressed: () => dialogSetState(
                              () => backgroundImagePath = null,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Center Image Picker (CircleAvatar if image is selected)
                    Text(
                      'Center Image:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        if (centerImagePath != null)
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: FileImage(File(centerImagePath!)),
                          ),
                        IconButton(
                          icon: Icon(
                            centerImagePath != null ? Icons.edit : Icons.image,
                            size: 24,
                          ),
                          onPressed: () async {
                            final newImagePath = await _pickImage();
                            if (newImagePath != null) {
                              dialogSetState(
                                () => centerImagePath = newImagePath,
                              );
                            }
                          },
                        ),
                        if (centerImagePath != null)
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                dialogSetState(() => centerImagePath = null),
                          ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Font Size Slider
                    Text(
                      'Font Size: ${selectedFontSize.round()}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: selectedFontSize.roundToDouble(),
                      min: 12,
                      max: 25,
                      onChanged: (value) => dialogSetState(
                        () => selectedFontSize = value.round(),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Text Color Picker (Gradient-based)
                    Text(
                      'Text Color:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final Color? pickedColor = await showDialog<Color>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Pick a color'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: selectedTextColor,
                                onColorChanged: (color) =>
                                    selectedTextColor = color,
                                colorPickerWidth: 300,
                                pickerAreaHeightPercent: 0.7,
                                enableAlpha: false,
                                displayThumbColor: true,
                                showLabel: false,
                                paletteType: PaletteType.hsv,
                                pickerAreaBorderRadius: BorderRadius.circular(
                                  12,
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(
                                  context,
                                ).pop(selectedTextColor),
                                child: Text('OK'),
                              ),
                            ],
                          ),
                        );
                        if (pickedColor != null) {
                          dialogSetState(() => selectedTextColor = pickedColor);
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selectedTextColor,
                          shape: BoxShape.circle,
                          border: Border.all(),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Stroke Color Picker (Gradient-based)
                    Text(
                      'Stroke Color:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final Color? pickedColor = await showDialog<Color>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Pick a color'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: selectedStrokeColor,
                                onColorChanged: (color) =>
                                    selectedStrokeColor = color,
                                colorPickerWidth: 300,
                                pickerAreaHeightPercent: 0.7,
                                enableAlpha: false,
                                displayThumbColor: true,
                                showLabel: false,
                                paletteType: PaletteType.hsv,
                                pickerAreaBorderRadius: BorderRadius.circular(
                                  12,
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(
                                  context,
                                ).pop(selectedStrokeColor),
                                child: Text('OK'),
                              ),
                            ],
                          ),
                        );
                        if (pickedColor != null) {
                          dialogSetState(
                            () => selectedStrokeColor = pickedColor,
                          );
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selectedStrokeColor,
                          shape: BoxShape.circle,
                          border: Border.all(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final updatedSegments = List<SpinnerSegment>.from(
                      widget.currentWheel.segments,
                    );
                    if (isEditing) {
                      updatedSegments[index] = SpinnerSegment(
                        text: textController.text,
                        color: selectedColor,
                        imagePath: backgroundImagePath,
                        centerImagePath: centerImagePath,
                        fontSize: selectedFontSize,
                        textColor: selectedTextColor,
                        strokeColor: selectedStrokeColor,
                      );
                    } else {
                      updatedSegments.add(
                        SpinnerSegment(
                          text: textController.text,
                          color: selectedColor,
                          imagePath: backgroundImagePath,
                          centerImagePath: centerImagePath,
                          fontSize: selectedFontSize,
                          textColor: selectedTextColor,
                          strokeColor: selectedStrokeColor,
                        ),
                      );
                    }
                    widget.onSegmentsUpdated(updatedSegments);
                    Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ...widget.currentWheel.segments.asMap().entries.map((entry) {
            int index = entry.key;
            SpinnerSegment segment = entry.value;
            return ListTile(
              title: Text(segment.text),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue.shade800),
                    onPressed: () =>
                        _showSegmentDialog(index: index, segment: segment),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.blue.shade800),
                    onPressed: () {
                      if (widget.currentWheel.segments.length <= 2) {
                        UIUtils.showMessageDialog(
                          context,
                          title: 'Required',
                          message: 'At least 2 segments are required',
                          isError: true,
                        );
                        return; // abort deletion
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
            );
          }),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
                  child: const Text('Add Segment'),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    '${widget.currentWheel.segments.length}/12 segments',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
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
