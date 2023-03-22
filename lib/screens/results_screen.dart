import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as image_lib;
import 'package:tennis_serve_analysis/utility/classifier.dart';
import 'package:tennis_serve_analysis/utility/isolate_utils.dart';

class ResultsScreen extends StatefulWidget {
  final XFile pickedVideo;
  const ResultsScreen({Key? key, required this.pickedVideo}) : super(key: key);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool isLoading = true;
  double progressValue = 0;
  double videoDuration = 60.19;
  int numberOfImages = 0;
  String outputPath = "";

  late final Classifier classifier;
  late final IsolateUtils isolate;

  @override
  void initState() {
    initClassifier();
    getDuration();
    saveVideoInImages(File(widget.pickedVideo.path));
    super.initState();
  }

  Future initClassifier() async {
    isolate = IsolateUtils();
    await isolate.start();
    classifier = Classifier();
    classifier.loadModel();
  }

  Future getDuration() async {
    await FFprobeKit.getMediaInformationAsync(
      widget.pickedVideo.path,
      (session) async {
        final information = (session).getMediaInformation();
        try {
          for (int x = 0; x < information!.getStreams().length; x++) {
            final stream = information.getStreams()[x];
            if (stream.getAllProperties() != null && videoDuration == 60.19) {
              videoDuration = double.parse(
                  stream.getAllProperties()!["duration"].toString());
              setState(() {});
              break;
            }
          }
        } catch (e) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      },
    );
  }

  double getFFmpegProgress(String ffmpegLogs, num videoDurationInSec) {
    final regex = RegExp("(?<=time=)[\\d:.]*");
    final match = regex.firstMatch(ffmpegLogs);
    if (match != null) {
      final matchSplit = match.group(0).toString().split(":");
      if (videoDurationInSec != 0) {
        final progress = (int.parse(matchSplit[0]) * 3600 +
                int.parse(matchSplit[1]) * 60 +
                double.parse(matchSplit[2])) /
            videoDurationInSec;
        double showProgress = (progress * 100);
        return showProgress;
      }
    }
    return 0;
  }

  Future<void> saveVideoInImages(File selectedVideo) async {
    //delay to get duration
    await Future.delayed(const Duration(milliseconds: 500), () {});
    outputPath = (await getApplicationDocumentsDirectory()).path;
    String command =
        "-i ${selectedVideo.path} -vf fps=20 $outputPath/image_%03d.jpg";
    FFmpegKit.executeAsync(command, (session) async {
      final state =
          FFmpegKitConfig.sessionStateToString(await session.getState());
      final returnCode = await session.getReturnCode();
      debugPrint("FFmpeg process exited with state $state and rc $returnCode");
      if (ReturnCode.isSuccess(returnCode)) {
        debugPrint('Video successfuly split');
        numberOfImages = (videoDuration * 20).round();
        await createIsolates();
      } else {
        debugPrint("FFmpeg processing failed.");
      }
    }, (logs) {
      final progress = getFFmpegProgress(logs.getMessage(), videoDuration);
      if (progress != 0) {
        setState(() {
          progressValue = progress;
        });
      }
    });
  }

  String imagePath(int index) {
    if (index < 10) {
      return "$outputPath/image_00$index.jpg";
    } else if (index >= 10 && index <= 99) {
      return "$outputPath/image_0$index.jpg";
    } else {
      return "$outputPath/image_$index.jpg";
    }
  }

  double getAngle(List<int> pointA, List<int> pointB, List<int> pointC) {
    double radians = atan2(pointC[1] - pointB[1], pointC[0] - pointB[0]) -
        atan2(pointA[1] - pointB[1], pointA[0] - pointB[0]);
    double angle = (radians * 180 / pi).abs();

    if (angle > 180) {
      angle = 360 - angle;
    }

    return angle;
  }

  Future createIsolates() async {
    setState(() {
      isLoading = true;
    });
    image_lib.Image tmpImage;
    for (int i = 0; i < numberOfImages; i++) {
      tmpImage = image_lib.decodeJpg(File(imagePath(i + 1)).readAsBytesSync())!;
      var isolateData = IsolateData(tmpImage, classifier.interpreter.address);
      List<dynamic> inferenceResults = await inference(isolateData);
      List<int> pointA = [inferenceResults[7][0], inferenceResults[7][1]];
      List<int> pointB = [inferenceResults[5][0], inferenceResults[5][1]];
      List<int> pointC = [inferenceResults[11][0], inferenceResults[11][1]];
      double testAngle = getAngle(pointA, pointB, pointC);
      debugPrint("test_angle=$testAngle");
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<List<dynamic>> inference(IsolateData isolateData) async {
    ReceivePort responsePort = ReceivePort();
    isolate.sendPort.send(isolateData..responsePort = responsePort.sendPort);
    var results = await responsePort.first;
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Results Screen"),
      ),
      body: (isLoading)
          ? Center(
              child: Column(
                children: [
                  const Spacer(),
                  Lottie.asset("assets/lottie/racquet-loading.json"),
                  const SizedBox(height: 30),
                  const Text(
                    "Analyzing Serve",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(
                    flex: 2,
                  ),
                ],
              ),
            )
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.5,
              ),
              itemCount: numberOfImages,
              itemBuilder: (context, index) => Image.file(
                File(imagePath(index + 1)),
                fit: BoxFit.cover,
              ),
            ),
    );
  }
}

class RenderLandmarks extends CustomPainter {
  late List<dynamic> inferenceList;
  late PointMode pointMode;
  late List<dynamic> selectedLandmarks;

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
    ..color = Colors.orange
    ..strokeWidth = 5;

  List<Offset> pointsGreen = [];
  List<Offset> pointsRed = [];

  List<dynamic> edges = [
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

  RenderLandmarks(List<dynamic> inferences, List<dynamic> included) {
    inferenceList = inferences;
    selectedLandmarks = included;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // for (List<int> edge in edges) {
    //   double vertex1X = inferenceList[edge[0]][0].toDouble() - 70;
    //   double vertex1Y = inferenceList[edge[0]][1].toDouble() - 30;
    //   double vertex2X = inferenceList[edge[1]][0].toDouble() - 70;
    //   double vertex2Y = inferenceList[edge[1]][1].toDouble() - 30;
    //   canvas.drawLine(
    //       Offset(vertex1X, vertex1Y), Offset(vertex2X, vertex2Y), edge_paint);
    // }

    for (var limb in selectedLandmarks) {
      renderEdge(canvas, limb[0], limb[1]);
    }
    canvas.drawPoints(PointMode.points, pointsGreen, greenPoint);
    canvas.drawPoints(PointMode.points, pointsRed, redPoint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  void renderEdge(Canvas canvas, List<int> included, bool isCorrect) {
    for (List<dynamic> point in inferenceList) {
      if ((point[2] > 0.40) & included.contains(inferenceList.indexOf(point))) {
        isCorrect
            ? pointsGreen
                .add(Offset(point[0].toDouble() - 70, point[1].toDouble() - 30))
            : pointsRed.add(
                Offset(point[0].toDouble() - 70, point[1].toDouble() - 30));
      }
    }

    for (List<int> edge in edges) {
      if (included.contains(edge[0]) & included.contains(edge[1])) {
        double vertex1X = inferenceList[edge[0]][0].toDouble() - 70;
        double vertex1Y = inferenceList[edge[0]][1].toDouble() - 30;
        double vertex2X = inferenceList[edge[1]][0].toDouble() - 70;
        double vertex2Y = inferenceList[edge[1]][1].toDouble() - 30;
        canvas.drawLine(Offset(vertex1X, vertex1Y), Offset(vertex2X, vertex2Y),
            isCorrect ? greenEdge : redEdge);
      }
    }
  }
}
