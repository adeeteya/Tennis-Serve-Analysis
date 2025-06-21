import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class InferencePoint {
  final Offset point;
  final double confidence;

  InferencePoint(this.point, this.confidence);
  factory InferencePoint.fromList(List inferenceList) {
    return InferencePoint(
      Offset(
        (inferenceList[0] as int).toDouble(),
        (inferenceList[1] as int).toDouble(),
      ),
      inferenceList[2],
    );
  }

  List toList() {
    return [point.dx, point.dy, confidence];
  }
}

class ServeResult {
  final String playerName;
  final String? playerPhotoAssetPath;
  final int height; //in cm
  final bool isLeftHanded;

  double minWidth = 2000;
  double minHeight = 2000;
  double maxHeight = 0;

  final List<double> leftShoulderAngles = [];
  final List<double> leftKneeAngles = [];
  final List<double> leftElbowAngles = [];
  final List<double> rightShoulderAngles = [];
  final List<double> rightKneeAngles = [];
  final List<double> rightElbowAngles = [];

  final List<InferencePoint> nosePoints = [];
  final List<InferencePoint> leftEyePoints = [];
  final List<InferencePoint> rightEyePoints = [];
  final List<InferencePoint> leftEarPoints = [];
  final List<InferencePoint> rightEarPoints = [];
  final List<InferencePoint> leftShoulderPoints = [];
  final List<InferencePoint> rightShoulderPoints = [];
  final List<InferencePoint> leftElbowPoints = [];
  final List<InferencePoint> rightElbowPoints = [];
  final List<InferencePoint> leftWristPoints = [];
  final List<InferencePoint> rightWristPoints = [];
  final List<InferencePoint> leftHipPoints = [];
  final List<InferencePoint> rightHipPoints = [];
  final List<InferencePoint> leftKneePoints = [];
  final List<InferencePoint> rightKneePoints = [];
  final List<InferencePoint> leftAnklePoints = [];
  final List<InferencePoint> rightAnklePoints = [];

  ServeResult(
    this.playerName,
    this.height,
    this.isLeftHanded, {
    this.playerPhotoAssetPath,
  });

  ServeResult copyWith({String? playerName, int? height, bool? isLeftHanded}) {
    return ServeResult(
      playerName ?? this.playerName,
      height ?? this.height,
      isLeftHanded ?? this.isLeftHanded,
    );
  }

  double getAngle(Offset pointA, Offset pointB, Offset pointC) {
    final double radians =
        atan2(pointC.dy - pointB.dy, pointC.dx - pointB.dx) -
        atan2(pointA.dy - pointB.dy, pointA.dx - pointB.dx);
    double angle = (radians * 180 / pi).abs();

    if (angle > 180) {
      angle = 360 - angle;
    }
    return angle;
  }

  double get averageLeftShoulderAngle => leftShoulderAngles.average;
  double get averageLeftKneeAngle => leftKneeAngles.average;
  double get averageLeftElbowAngle => leftElbowAngles.average;
  double get averageRightShoulderAngle => rightShoulderAngles.average;
  double get averageRightKneeAngle => rightKneeAngles.average;
  double get averageRightElbowAngle => rightElbowAngles.average;

  double get maxLeftShoulderAngle => leftShoulderAngles.max;
  double get maxLeftKneeAngle => leftKneeAngles.max;
  double get maxLeftElbowAngle => leftElbowAngles.max;
  double get maxRightShoulderAngle => rightShoulderAngles.max;
  double get maxRightKneeAngle => rightKneeAngles.max;
  double get maxRightElbowAngle => rightElbowAngles.max;

  double get minLeftShoulderAngle => leftShoulderAngles.min;
  double get minLeftKneeAngle => leftKneeAngles.min;
  double get minLeftElbowAngle => leftElbowAngles.min;
  double get minRightShoulderAngle => rightShoulderAngles.min;
  double get minRightKneeAngle => rightKneeAngles.min;
  double get minRightElbowAngle => rightElbowAngles.min;

  List get completeInferenceList => [
    for (int i = 0; i < nosePoints.length; i++)
      [
        nosePoints[i].toList(),
        leftEyePoints[i].toList(),
        rightEyePoints[i].toList(),
        leftEarPoints[i].toList(),
        rightEarPoints[i].toList(),
        leftShoulderPoints[i].toList(),
        rightShoulderPoints[i].toList(),
        leftElbowPoints[i].toList(),
        rightElbowPoints[i].toList(),
        leftWristPoints[i].toList(),
        rightWristPoints[i].toList(),
        leftHipPoints[i].toList(),
        rightHipPoints[i].toList(),
        leftKneePoints[i].toList(),
        rightKneePoints[i].toList(),
        leftAnklePoints[i].toList(),
        rightAnklePoints[i].toList(),
      ],
  ];

  void addInferenceFromFrame(List inferenceFrameResult) {
    final InferencePoint nosePoint = InferencePoint.fromList(
      inferenceFrameResult[0],
    );
    final InferencePoint leftEyePoint = InferencePoint.fromList(
      inferenceFrameResult[1],
    );
    final InferencePoint rightEyePoint = InferencePoint.fromList(
      inferenceFrameResult[2],
    );
    final InferencePoint leftEarPoint = InferencePoint.fromList(
      inferenceFrameResult[3],
    );
    final InferencePoint rightEarPoint = InferencePoint.fromList(
      inferenceFrameResult[4],
    );
    final InferencePoint leftShoulderPoint = InferencePoint.fromList(
      inferenceFrameResult[5],
    );
    final InferencePoint rightShoulderPoint = InferencePoint.fromList(
      inferenceFrameResult[6],
    );
    final InferencePoint leftElbowPoint = InferencePoint.fromList(
      inferenceFrameResult[7],
    );
    final InferencePoint rightElbowPoint = InferencePoint.fromList(
      inferenceFrameResult[8],
    );
    final InferencePoint leftWristPoint = InferencePoint.fromList(
      inferenceFrameResult[9],
    );
    final InferencePoint rightWristPoint = InferencePoint.fromList(
      inferenceFrameResult[10],
    );
    final InferencePoint leftHipPoint = InferencePoint.fromList(
      inferenceFrameResult[11],
    );
    final InferencePoint rightHipPoint = InferencePoint.fromList(
      inferenceFrameResult[12],
    );
    final InferencePoint leftKneePoint = InferencePoint.fromList(
      inferenceFrameResult[13],
    );
    final InferencePoint rightKneePoint = InferencePoint.fromList(
      inferenceFrameResult[14],
    );
    final InferencePoint leftAnklePoint = InferencePoint.fromList(
      inferenceFrameResult[15],
    );
    final InferencePoint rightAnklePoint = InferencePoint.fromList(
      inferenceFrameResult[16],
    );

    nosePoints.add(nosePoint);
    leftEyePoints.add(leftEyePoint);
    rightEyePoints.add(rightEyePoint);
    leftEarPoints.add(leftEarPoint);
    rightEarPoints.add(rightEarPoint);
    leftShoulderPoints.add(leftShoulderPoint);
    rightShoulderPoints.add(rightShoulderPoint);
    leftElbowPoints.add(leftElbowPoint);
    rightElbowPoints.add(rightElbowPoint);
    leftWristPoints.add(leftWristPoint);
    rightWristPoints.add(rightWristPoint);
    leftHipPoints.add(leftHipPoint);
    rightHipPoints.add(rightHipPoint);
    leftKneePoints.add(leftKneePoint);
    rightKneePoints.add(rightKneePoint);
    leftAnklePoints.add(leftAnklePoint);
    rightAnklePoints.add(rightAnklePoint);

    leftKneeAngles.add(
      getAngle(leftHipPoint.point, leftKneePoint.point, leftAnklePoint.point),
    );
    leftElbowAngles.add(
      getAngle(
        leftWristPoint.point,
        leftElbowPoint.point,
        leftShoulderPoint.point,
      ),
    );
    leftShoulderAngles.add(
      getAngle(
        leftElbowPoint.point,
        leftShoulderPoint.point,
        leftHipPoint.point,
      ),
    );
    rightKneeAngles.add(
      getAngle(
        rightHipPoint.point,
        rightKneePoint.point,
        rightAnklePoint.point,
      ),
    );
    rightElbowAngles.add(
      getAngle(
        rightWristPoint.point,
        rightElbowPoint.point,
        rightShoulderPoint.point,
      ),
    );
    rightShoulderAngles.add(
      getAngle(
        rightElbowPoint.point,
        rightShoulderPoint.point,
        rightHipPoint.point,
      ),
    );

    final List<double> pointHeights = [
      nosePoint.point.dy,
      leftEyePoint.point.dy,
      rightEyePoint.point.dy,
      leftEarPoint.point.dy,
      rightEarPoint.point.dy,
      leftShoulderPoint.point.dy,
      rightShoulderPoint.point.dy,
      leftElbowPoint.point.dy,
      rightElbowPoint.point.dy,
      leftWristPoint.point.dy,
      rightWristPoint.point.dy,
      leftHipPoint.point.dy,
      rightHipPoint.point.dy,
      leftKneePoint.point.dy,
      rightKneePoint.point.dy,
      leftAnklePoint.point.dy,
      rightAnklePoint.point.dy,
    ];
    final List<double> pointWidths = [
      nosePoint.point.dx,
      leftEyePoint.point.dx,
      rightEyePoint.point.dx,
      leftEarPoint.point.dx,
      rightEarPoint.point.dx,
      leftShoulderPoint.point.dx,
      rightShoulderPoint.point.dx,
      leftElbowPoint.point.dx,
      rightElbowPoint.point.dx,
      leftWristPoint.point.dx,
      rightWristPoint.point.dx,
      leftHipPoint.point.dx,
      rightHipPoint.point.dx,
      leftKneePoint.point.dx,
      rightKneePoint.point.dx,
      leftAnklePoint.point.dx,
      rightAnklePoint.point.dx,
    ];

    if (pointWidths.min < minWidth) {
      minWidth = pointWidths.min;
    }
    if (pointHeights.min < minHeight) {
      minHeight = pointHeights.min;
    }
    if (pointHeights.max > maxHeight) {
      maxHeight = pointHeights.max;
    }
  }

  String heightInFeetAndInches() {
    final double heightInFeet = height * 0.032808399; //1cm = 0.032808399inches
    final double heightInRemainingInches =
        (heightInFeet - heightInFeet.floor()) * 12;
    return "${heightInFeet.floor()}ft ${heightInRemainingInches.round()}in";
  }

  factory ServeResult.fromCompleteInferenceList(
    String playerName,
    int height,
    bool isLeftHanded,
    String imageAssetPath,
    List completeExtractedInferenceList,
  ) {
    final ServeResult newServeResult = ServeResult(
      playerName,
      height,
      isLeftHanded,
      playerPhotoAssetPath: imageAssetPath,
    );
    for (final inferenceList in completeExtractedInferenceList) {
      newServeResult.addInferenceFromFrame(inferenceList);
    }
    return newServeResult;
  }
}
