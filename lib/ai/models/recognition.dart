import 'package:flutter/cupertino.dart';

/// Represents the recognition output from the model
class Recognition {
  /// Index of the result
  final int _id;

  /// Label of the result
  final String _label;

  /// Confidence [0.0, 1.0]
  final double _score;

  /// Location of bounding box rect
  /// YOLOv8 Segmentation Mask Coefficients
  final Rect _location;
  final List<double>? _maskCoeffs;
  
  /// A boolean grid representing the 80x80 prototype footprint scaled to this object's width/height
  final List<bool>? maskGrid;
  final int? maskWidth;
  final int? maskHeight;
  int missingFrames = 0;

  Recognition(this._id, this._label, this._score, this._location, {
    List<double>? maskCoeffs,
    this.maskGrid,
    this.maskWidth,
    this.maskHeight,
    this.missingFrames = 0,
  }) : _maskCoeffs = maskCoeffs;

  int get id => _id;

  String get label => _label;

  double get score => _score;

  Rect get location => _location;
  
  List<double>? get maskCoeffs => _maskCoeffs;

  /// Returns bounding box rectangle corresponding to the
  /// displayed image on screen
  ///
  /// This is the actual location where rectangle is rendered on
  /// the screen
  Rect get renderLocation {
    return Rect.fromCenter(center: const Offset(0, 0), width: 0, height: 0);
  }

  @override
  String toString() {
    return 'Recognition(id: $id, label: $label, score: $score, location: $location)';
  }
}
