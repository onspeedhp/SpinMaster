import 'package:flutter/material.dart';
import 'package:wheeler/model/spinner_segment_model.dart';

class EditSegmentDialog extends StatelessWidget {
  final List<SpinnerSegment> segments;
  final Function(List<SpinnerSegment>) onSegmentsUpdated;

  const EditSegmentDialog({
    super.key,
    required this.segments,
    required this.onSegmentsUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Segments'),
      content: Text('Segment editing is now done directly in the main screen.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('OK'),
        ),
      ],
    );
  }
}