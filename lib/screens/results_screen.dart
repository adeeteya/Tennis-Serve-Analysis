import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
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
import 'package:tennis_serve_analysis/widgets/serve_visualizer.dart';

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
  double avgShoulderAngle = 0;
  double avgKneeAngle = 0;
  double avgElbowAngle = 0;
  List completeInferenceResults = [];

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

  Future<void> saveVideoInImages(File selectedVideo) async {
    //delay to get duration
    await Future.delayed(const Duration(milliseconds: 500), () {});
    outputPath = (await getTemporaryDirectory()).path;
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
    });
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

  String imagePath(int index) {
    if (index < 10) {
      return "$outputPath/image_00$index.jpg";
    } else if (index >= 10 && index <= 99) {
      return "$outputPath/image_0$index.jpg";
    } else {
      return "$outputPath/image_$index.jpg";
    }
  }

  Future createIsolates() async {
    setState(() {
      isLoading = true;
    });
    image_lib.Image tmpImage;
    double shoulderAngleSum = 0;
    double kneeAngleSum = 0;
    double elbowAngleSum = 0;
    for (int i = 0; i < numberOfImages; i++) {
      tmpImage = image_lib.decodeJpg(File(imagePath(i + 1)).readAsBytesSync())!;
      var isolateData = IsolateData(tmpImage, classifier.interpreter.address);
      List inferenceResults = await inference(isolateData);
      List<int> shoulder = [inferenceResults[6][0], inferenceResults[6][1]];
      List<int> elbow = [inferenceResults[8][0], inferenceResults[8][1]];
      List<int> wrist = [inferenceResults[10][0], inferenceResults[10][1]];
      List<int> hip = [inferenceResults[12][0], inferenceResults[12][1]];
      List<int> knee = [inferenceResults[14][0], inferenceResults[14][1]];
      List<int> ankle = [inferenceResults[16][0], inferenceResults[16][1]];
      double shoulderAngle = getAngle(elbow, shoulder, hip);
      double kneeAngle = getAngle(hip, knee, ankle);
      double elbowAngle = getAngle(wrist, elbow, shoulder);
      shoulderAngleSum += shoulderAngle;
      kneeAngleSum += kneeAngle;
      elbowAngleSum += elbowAngle;
      completeInferenceResults.add(inferenceResults);
    }
    setState(() {
      avgShoulderAngle = shoulderAngleSum / numberOfImages;
      avgKneeAngle = kneeAngleSum / numberOfImages;
      avgElbowAngle = elbowAngleSum / numberOfImages;
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
        title: const Text("Serve Analysis Result"),
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
          : SingleChildScrollView(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    UserServeVisualizer(points: completeInferenceResults),
                    const Divider(height: 20),
                    Text(
                      "Average Knee Angle= ${avgKneeAngle.toStringAsFixed(2)}°",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Average Elbow Angle= ${avgElbowAngle.toStringAsFixed(2)}°",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Average Shoulder Angle= ${avgShoulderAngle.toStringAsFixed(2)}°",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class ImageVisualizer extends StatefulWidget {
  final String outputPath;
  final int numberOfImages;
  const ImageVisualizer(
      {Key? key, required this.outputPath, required this.numberOfImages})
      : super(key: key);

  @override
  State<ImageVisualizer> createState() => _ImageVisualizerState();
}

class _ImageVisualizerState extends State<ImageVisualizer> {
  int currentIndex = 0;
  late final Timer timer;

  String imagePath(int index) {
    if (index < 10) {
      return "${widget.outputPath}/image_00$index.jpg";
    } else if (index >= 10 && index <= 99) {
      return "${widget.outputPath}/image_0$index.jpg";
    } else {
      return "${widget.outputPath}/image_$index.jpg";
    }
  }

  @override
  void initState() {
    //50ms because 20frames per second
    timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        if (currentIndex == widget.numberOfImages - 1) {
          currentIndex = 0;
        } else {
          currentIndex++;
        }
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(imagePath(currentIndex)),
      fit: BoxFit.cover,
    );
  }
}
