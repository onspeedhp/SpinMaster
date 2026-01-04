import 'package:flutter/material.dart';

class SpinnerSegment {
  final String text;
  final Color color;
  final String? imagePath;
  final String? centerImagePath;
  final String? iconUrl;
  final int? fontSize;
  final Color textColor;
  final Color strokeColor;
  final bool disabled;

  SpinnerSegment({
    required this.text,
    required this.color,
    this.imagePath,
    this.centerImagePath,
    this.iconUrl,
    this.fontSize = 17,
    this.textColor = Colors.black,
    this.strokeColor = Colors.white,
    this.disabled = false,
  });

  SpinnerSegment copyWith({
    String? text,
    Color? color,
    String? imagePath,
    String? centerImagePath,
    String? iconUrl,
    int? fontSize, // ← Fixed: int? not double?
    Color? textColor,
    Color? strokeColor,
    bool? disabled,
  }) {
    return SpinnerSegment(
      text: text ?? this.text,
      color: color ?? this.color,
      imagePath: imagePath ?? this.imagePath,
      centerImagePath: centerImagePath ?? this.centerImagePath,
      iconUrl: iconUrl ?? this.iconUrl,
      fontSize: fontSize ?? this.fontSize, // ← Now safe
      textColor: textColor ?? this.textColor,
      strokeColor: strokeColor ?? this.strokeColor,
      disabled: disabled ?? this.disabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'color': color.value,
      'imagePath': imagePath,
      'centerImagePath': centerImagePath,
      'iconUrl': iconUrl,
      'fontSize': fontSize,
      'textColor': textColor.value,
      'strokeColor': strokeColor.value,
      'disabled': disabled,
    };
  }

  factory SpinnerSegment.fromJson(Map<String, dynamic> json) {
    return SpinnerSegment(
      text: json['text'] as String,
      color: Color(json['color'] as int),
      imagePath: json['imagePath'] as String?,
      centerImagePath: json['centerImagePath'] as String?,
      iconUrl: json['iconUrl'] as String?,
      fontSize: (json['fontSize'] as num?)?.toInt(),
      textColor: Color(json['textColor'] as int? ?? Colors.black.value),
      strokeColor: Color(json['strokeColor'] as int? ?? Colors.white.value),
      disabled: json['disabled'] as bool? ?? false,
    );
  }
}

class Wheel {
  final String id;
  final String name;
  final List<SpinnerSegment> segments;
  final List<String> history;
  final DateTime createdAt;

  Wheel({
    required this.id,
    required this.name,
    required this.segments,
    this.history = const [],
    required this.createdAt,
  });

  Wheel copyWith({
    String? id,
    String? name,
    List<SpinnerSegment>? segments,
    List<String>? history,
    DateTime? createdAt,
  }) {
    return Wheel(
      id: id ?? this.id,
      name: name ?? this.name,
      segments: segments ?? this.segments,
      history: history ?? this.history,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'segments': segments.map((segment) => segment.toJson()).toList(),
      'history': history,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Wheel.fromJson(Map<String, dynamic> json) {
    return Wheel(
      id: json['id'],
      name: json['name'],
      segments: (json['segments'] as List)
          .map((segment) => SpinnerSegment.fromJson(segment))
          .toList(),
      history:
          (json['history'] as List?)?.map((e) => e as String).toList() ?? [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }
}
