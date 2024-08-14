import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// // REAL Motor Right Down
// // left: 630,
// // top: 350,
// // size: const Size(65, 125), // Adjust size as needed
// class DistanceSensorPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..color = Colors.blue;
//     // Customize color
//     final path = Path();
//     path.moveTo(0, 0);
//     path.lineTo(size.width, 0);
//     path.lineTo(size.width, size.height);
//     path.lineTo(0, size.height);
//     path.close();
//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

// // REAL Speaker
// // left: 540,
// // top: 460,
// // size: const Size(145, 140), // Adjust size as needed
// class DistanceSensorPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..color = Colors.blue;
//     // Customize color
//     final path = Path();
//     path.moveTo(0, 0);
//     path.lineTo(size.width, 0);
//     path.lineTo(size.width, size.height);
//     path.lineTo(0, size.height);
//     path.close();
//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

// REAL Compass
// left: 310,
// top: 500,
// size: const Size(175, 100), // Adjust size as needed
// class DistanceSensorPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..color = Colors.blue;
//     // Customize color
//     final path = Path();
//     path.moveTo(0, 0);
//     path.lineTo(size.width, 0);
//     path.lineTo(size.width, size.height);
//     path.lineTo(0, size.height);
//     path.close();
//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

// // REAL LED
// // left: 100,
// // top: 480,
// // size: const Size(165, 110), // Adjust size as needed
// class DistanceSensorPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..color = Colors.blue;
//     // Customize color
//     final path = Path();
//     path.moveTo(0, 0);
//     path.lineTo(size.width, 0);
//     path.lineTo(size.width, size.height);
//     path.lineTo(0, size.height);
//     path.close();
//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

// // REAL Motor Left Down
// // left: 100,
// // top: 325,
// // size: const Size(65, 125), // Adjust size as needed
// class DistanceSensorPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..color = Colors.blue;
//     // Customize color
//     final path = Path();
//     path.moveTo(0, 0);
//     path.lineTo(size.width, 0);
//     path.lineTo(size.width, size.height);
//     path.lineTo(0, size.height);
//     path.close();
//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

class GeneralSensorPainter extends CustomPainter {
  double xDiff = 20;
  double yDiff = 4;
  Path path = Path();
  Paint painter = Paint();
  Color myColor = Colors.red.withOpacity(0.5);
  final List<Offset> polygonPath = [];
  final List<double> positionDiff = [];

  GeneralSensorPainter(
      {List<Offset>? polygonPath, List<double>? positionDiff}) {
    painter.color = myColor;
    if (positionDiff != null) {
      xDiff = positionDiff[0];
      yDiff = positionDiff[1];
    }
    int idx = 0;
    if (polygonPath != null) {
      for (Offset pos in polygonPath) {
        if (idx == 0) {
          path.moveTo(pos.dx - xDiff, pos.dy - yDiff);
        } else {
          path.lineTo(pos.dx - xDiff, pos.dy - yDiff);
        }
        idx++;
      }
      path.close();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(path, painter);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// REAL DISTANCE SENSOR PAINTER
// "left": 150.0,
// "top": 5.0,
// "offset": const Offset(300, 170),
// "size": const Size(95, 125),
// "zoneArea": [-1, -1],
class DistanceSensorPainter extends GeneralSensorPainter {
  double xDiff = 20;
  double yDiff = 4;
  Path path = Path();
  Paint painter = Paint();

  DistanceSensorPainter() {
    // Customize color
    painter.color = myColor;
  }

  @override
  void paint(Canvas canvas, Size size) {
    path = Path();
    path.moveTo(63 - xDiff, 3 - yDiff);
    path.lineTo(107 - xDiff, 4 - yDiff);
    path.lineTo(102 - xDiff, 111 - yDiff);
    path.lineTo(123 - xDiff, 111 - yDiff);
    path.lineTo(98 - xDiff, 139 - yDiff);

    path.lineTo(22 - xDiff, 122 - yDiff);
    path.lineTo(24 - xDiff, 43 - yDiff);
    path.lineTo(60 - xDiff, 44 - yDiff);
    path.lineTo(63 - xDiff, 3 - yDiff);
    path.close();

    canvas.drawPath(path, painter);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// REAL CAMERA
// "left": 350.0,
// "top": 0.0,
// "offset": const Offset(310, 140),
// size: const Size(175, 100), // Adjust size as needed
class CameraSensorPainter extends GeneralSensorPainter {
  double xDiff = 216;
  double yDiff = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = myColor;
    // Customize color
    final path = Path();
    path.moveTo(218 - xDiff, 8 - yDiff);
    path.lineTo(384 - xDiff, 8 - yDiff);
    path.lineTo(384 - xDiff, 55 - yDiff);
    path.lineTo(309 - xDiff, 100 - yDiff);
    path.lineTo(271 - xDiff, 96 - yDiff);

    path.lineTo(218 - xDiff, 63 - yDiff);
    path.lineTo(218 - xDiff, 8 - yDiff);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// REAL Microphone
// left: 550,
// top: 0,
// size: const Size(130, 160), // Adjust size as needed
class MicrophoneSensorPainter extends GeneralSensorPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blue;
    // Customize color
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, 0);
    path.lineTo(size.width / 2, size.height / 2);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// REAL Motor Left UP
// "left": 140.0,
// "top": 200.0,
// "offset": const Offset(240, 220),
// "size": const Size(65, 125),
class MotorLeftForwardSensorPainter extends GeneralSensorPainter {
  double xDiff = 0;
  double yDiff = 200;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.transparent;
    // Customize color
    final path = Path();
    path.moveTo(12 - xDiff, 205 - yDiff);
    path.lineTo(37 - xDiff, 200 - yDiff);
    path.lineTo(68 - xDiff, 225 - yDiff);
    path.lineTo(56 - xDiff, 322 - yDiff);

    path.lineTo(3 - xDiff, 323 - yDiff);
    path.lineTo(12 - xDiff, 205 - yDiff);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// REAL Motor Right UP
// "left": 665.0,
// "top": 200.0,
// "offset": const Offset(525, 240),
// "size": const Size(65, 125),
class MotorRightForwardSensorPainter extends GeneralSensorPainter {
  double xDiff = 529;
  double yDiff = 200;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.red;
    // Customize color
    final path = Path();
    path.moveTo(531 - xDiff, 229 - yDiff);
    path.lineTo(564 - xDiff, 200 - yDiff);
    path.lineTo(589 - xDiff, 200 - yDiff);
    path.lineTo(596 - xDiff, 323 - yDiff);
    path.lineTo(544 - xDiff, 321 - yDiff);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// REAL Motor Left UP
// "left": 140.0,
// "top": 200.0,
// "offset": const Offset(240, 220),
// "size": const Size(65, 125),
class MotorLeftBackwardSensorPainter extends GeneralSensorPainter {
  double xDiff = 0;
  double yDiff = 322;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.transparent;
    // Customize color
    final path = Path();
    path.moveTo(3 - xDiff, 323 - yDiff);
    path.lineTo(56 - xDiff, 322 - yDiff);
    path.lineTo(68 - xDiff, 416 - yDiff);
    path.lineTo(40 - xDiff, 450 - yDiff);

    path.lineTo(11 - xDiff, 447 - yDiff);
    path.lineTo(3 - xDiff, 323 - yDiff);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// REAL Motor Right UP
// "left": 665.0,
// "top": 200.0,
// "offset": const Offset(525, 240),
// "size": const Size(65, 125),
class MotorRightBackwardSensorPainter extends GeneralSensorPainter {
  double xDiff = 521;
  double yDiff = 323;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.red;
    // Customize color
    final path = Path();
    path.moveTo(544 - xDiff, 321 - yDiff);
    path.lineTo(596 - xDiff, 323 - yDiff);
    path.lineTo(581 - xDiff, 444 - yDiff);
    path.lineTo(554 - xDiff, 448 - yDiff);
    path.lineTo(521 - xDiff, 442 - yDiff);
    path.lineTo(544 - xDiff, 321 - yDiff);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Distance Gap !!! important
// "left": 130.0,
// "top": 0.0,

List<List<Offset>> sensorPolygonPaths = [
  [
    const Offset(63, 3),
    const Offset(107, 4),
    const Offset(102, 111),
    const Offset(123, 111),
    const Offset(98, 139),
    const Offset(22, 122),
    const Offset(24, 43),
    const Offset(60, 44),
    const Offset(63, 3),
  ], // Distance
  [
    const Offset(218, 8),
    const Offset(384, 8),
    const Offset(384, 55),
    const Offset(309, 100),
    const Offset(271, 96),
    const Offset(218, 63),
    const Offset(218, 8),
  ], // left camera
  [
    const Offset(0, 0),
    const Offset(0, 0),
  ], // right camera
  [
    const Offset(12, 205),
    const Offset(37, 200),
    const Offset(68, 225),
    const Offset(56, 322),
    const Offset(3, 323),
    const Offset(12, 205),
  ], // left motor up
  [
    const Offset(531, 229),
    const Offset(564, 200),
    const Offset(589, 200),
    const Offset(596, 323),
    const Offset(544, 321),
  ], // right motor up

  [
    const Offset(3, 323),
    const Offset(56, 322),
    const Offset(68, 416),
    const Offset(40, 450),
    const Offset(11, 447),
    const Offset(3, 323),
  ], // left motor down
  [
    const Offset(544, 321),
    const Offset(596, 323),
    const Offset(581, 444),
    const Offset(554, 448),
    const Offset(521, 442),
    const Offset(544, 321),
  ], // right motor down
  [
    const Offset(453, 47),
    const Offset(487, 16),
    const Offset(547, 21),
    const Offset(585, 148),
    const Offset(523, 174),
    const Offset(508, 131),
    const Offset(550, 143),
    const Offset(550, 112),
    const Offset(453, 47),
  ], // microphone
  [
    const Offset(432, 518),
    const Offset(465, 500),
    const Offset(461, 535),
    const Offset(535, 481),
    const Offset(568, 518),
    const Offset(563, 580),
    const Offset(457, 563),
    const Offset(432, 518),
  ], // speaker
  [
    const Offset(163, 69),
    const Offset(218, 63),
    const Offset(271, 96),
    const Offset(309, 100),
    const Offset(384, 55),
    const Offset(451, 72),
    const Offset(508, 131),
    const Offset(523, 174),
    const Offset(531, 229),
    const Offset(544, 321),
    const Offset(521, 422),
    const Offset(465, 500),
    const Offset(432, 518),
    const Offset(378, 534),
    const Offset(302, 495),
    const Offset(229, 533),
    const Offset(172, 529),
    const Offset(134, 527),
    const Offset(69, 459),
    const Offset(68, 416),
    const Offset(56, 322),
    const Offset(68, 225),
    const Offset(98, 139),
    const Offset(123, 111),
  ], // core brain
];
