import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class UserServeVisualizer extends StatefulWidget {
  final List points;
  final bool isReference;
  const UserServeVisualizer({
    Key? key,
    required this.points,
    this.isReference = false,
  }) : super(key: key);

  @override
  State<UserServeVisualizer> createState() => _UserServeVisualizerState();
}

class _UserServeVisualizerState extends State<UserServeVisualizer> {
  int userIndex = 0;
  int referenceIndex = 0;
  late final Timer visualizerTimer;

  @override
  void initState() {
    //50ms because 20frames per second
    visualizerTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        if (userIndex == widget.points.length - 1) {
          userIndex = 0;
        } else {
          userIndex++;
        }
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    visualizerTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      willChange: true,
      isComplex: true,
      size: const Size(500, 400),
      painter: RenderLandmarks(widget.points[userIndex], widget.isReference),
    );
  }
}

class RenderLandmarks extends CustomPainter {
  final List inferenceList;
  final bool isReference;

  RenderLandmarks(this.inferenceList, this.isReference);

  final greenPoint = Paint()
    ..color = Colors.green
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 8;

  final greenEdge = Paint()
    ..color = Colors.lightGreen
    ..strokeWidth = 5;

  // Overlay Profile

  final redPoint = Paint()
    ..color = Colors.red
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 8;

  final redEdge = Paint()
    ..color = Colors.red.shade300
    ..strokeWidth = 5;

  List<Offset> pointsGreen = [];
  List<Offset> pointsRed = [];

  List edges = [
    [0, 1], // nose to left_eye
    [0, 2], // nose to right_eye
    [1, 3], // left_eye to left_ear
    [2, 4], // right_eye to right_ear
    [0, 5], // nose to left_shoulder
    [0, 6], // nose to right_shoulder
    [5, 7], // left_shoulder to left_elbow
    [7, 9], // left_elbow to left_wrist
    [6, 8], // right_shoulder to right_elbow
    [8, 10], // right_elbow to right_wrist
    [5, 6], // left_shoulder to right_shoulder
    [5, 11], // left_shoulder to left_hip
    [6, 12], // right_shoulder to right_hip
    [11, 12], // left_hip to right_hip
    [11, 13], // left_hip to left_knee
    [13, 15], // left_knee to left_ankle
    [12, 14], // right_hip to right_knee
    [14, 16] // right_knee to right_ankle
  ];

  @override
  void paint(Canvas canvas, Size size) {
    renderEdge(canvas);
    canvas.drawPoints(PointMode.points, pointsGreen, greenPoint);
    canvas.drawPoints(PointMode.points, pointsRed, redPoint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  void renderEdge(Canvas canvas) {
    for (List point in inferenceList) {
      if ((point[2] > 0.20)) {
        if (isReference) {
          pointsGreen
              .add(Offset(point[0].toDouble() - 70, point[1].toDouble() - 130));
        } else {
          pointsRed
              .add(Offset(point[0].toDouble() - 70, point[1].toDouble() - 130));
        }
      }
    }

    for (List<int> edge in edges) {
      double vertex1X = inferenceList[edge[0]][0].toDouble() - 70;
      double vertex1Y = inferenceList[edge[0]][1].toDouble() - 130;
      double vertex2X = inferenceList[edge[1]][0].toDouble() - 70;
      double vertex2Y = inferenceList[edge[1]][1].toDouble() - 130;
      canvas.drawLine(Offset(vertex1X, vertex1Y), Offset(vertex2X, vertex2Y),
          (isReference) ? greenEdge : redEdge);
    }
  }
}
