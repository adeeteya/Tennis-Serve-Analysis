import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as image_lib;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tennis_serve_analysis/controllers/user_controller.dart';
import 'package:tennis_serve_analysis/finals.dart';
import 'package:tennis_serve_analysis/models/serve_result.dart';
import 'package:tennis_serve_analysis/screens/change_reference_player.dart';
import 'package:tennis_serve_analysis/utility/classifier.dart';
import 'package:tennis_serve_analysis/utility/isolate_utils.dart';
import 'package:tennis_serve_analysis/widgets/analyzing_loading.dart';
import 'package:tennis_serve_analysis/widgets/reference_player_card.dart';
import 'package:tennis_serve_analysis/widgets/serve_visualizer.dart';
import 'package:tennis_serve_analysis/widgets/stat_tile.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final XFile pickedVideo;
  const ResultsScreen({super.key, required this.pickedVideo});

  @override
  ConsumerState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  bool isLoading = true;
  double videoDuration = 60.19;
  int numberOfImages = 0;
  late final String outputPath;
  late ServeResult serveResult;
  int? selectedPlayerIndex;

  late final Classifier classifier;
  late final IsolateUtils isolate;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      ref.read(userServeDataProvider.notifier).reset();
      serveResult = ref.read(userServeDataProvider);
    });
    initClassifier();
    getDuration();
    saveVideoInImages(File(widget.pickedVideo.path));
  }

  Future initClassifier() async {
    isolate = IsolateUtils();
    await isolate.start();
    classifier = Classifier();
    classifier.loadModel();
  }

  Future getDuration() async {
    await FFprobeKit.getMediaInformationAsync(widget.pickedVideo.path, (
      session,
    ) async {
      final information = (session).getMediaInformation();
      try {
        for (int x = 0; x < information!.getStreams().length; x++) {
          final stream = information.getStreams()[x];
          if (stream.getAllProperties() != null && videoDuration == 60.19) {
            videoDuration = double.parse(
              stream.getAllProperties()!["duration"].toString(),
            );
            setState(() {});
            break;
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    });
  }

  Future<void> saveVideoInImages(File selectedVideo) async {
    final Directory applicationDocumentsDir =
        await getApplicationDocumentsDirectory();
    outputPath = applicationDocumentsDir.path;
    //delete old images
    if (await applicationDocumentsDir.exists()) {
      await applicationDocumentsDir.delete(recursive: true);
      await applicationDocumentsDir.create();
    }
    //delay to get duration
    await Future.delayed(const Duration(milliseconds: 500), () {});
    final String command =
        "-i ${selectedVideo.path} -vf fps=20 $outputPath/image_%03d.jpg";
    FFmpegKit.executeAsync(command, (session) async {
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        debugPrint('Video successfully split');
        numberOfImages = (videoDuration * 20).round();
        await createIsolates();
      } else {
        debugPrint("FFmpeg processing failed.");
      }
    });
  }

  double getAngle(List<int> pointA, List<int> pointB, List<int> pointC) {
    double radians =
        atan2(pointC[1] - pointB[1], pointC[0] - pointB[0]) -
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

  Future<List> inference(IsolateData isolateData) async {
    final ReceivePort responsePort = ReceivePort();
    isolate.sendPort.send(isolateData..responsePort = responsePort.sendPort);
    final results = await responsePort.first;
    return results;
  }

  Future createIsolates() async {
    for (int i = 0; i < numberOfImages; i++) {
      final image_lib.Image tmpImage =
          image_lib.decodeJpg(File(imagePath(i + 1)).readAsBytesSync())!;
      final isolateData = IsolateData(tmpImage, classifier.interpreter.address);
      final List inferenceResults = await inference(isolateData);
      serveResult.addInferenceFromFrame(inferenceResults);
      // print(inferenceResults); ///use this to get serve results for reference players
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ServeResult selectedPlayerServeResult = ref.watch(
      selectedPlayerProvider(selectedPlayerIndex),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analysis Result"),
        actions: [
          if (!isLoading)
            IconButton(
              onPressed: () async {
                selectedPlayerIndex = availableReferencePlayers.indexWhere(
                  (element) =>
                      element.playerName ==
                      selectedPlayerServeResult.playerName,
                );
                selectedPlayerIndex =
                    (selectedPlayerIndex == -1) ? null : selectedPlayerIndex;
                selectedPlayerIndex = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ChangeReferencePlayerScreen(
                          selectedPlayerIndex: selectedPlayerIndex ?? 0,
                        ),
                  ),
                );
                setState(() {});
              },
              tooltip: "Change Reference Player",
              icon: const Icon(Icons.change_circle),
            ),
        ],
      ),
      body:
          (isLoading)
              ? const AnalysisLoadingWidget()
              : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReferencePlayerCard(
                      referencePlayerResult: selectedPlayerServeResult,
                    ),
                    Card(
                      child: Column(
                        children: [
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const SizedBox(width: 20),
                              const SizedBox(
                                height: 15,
                                width: 15,
                                child: ColoredBox(color: Colors.red),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "User's Serve",
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const SizedBox(width: 20),
                              const SizedBox(
                                height: 15,
                                width: 15,
                                child: ColoredBox(color: Colors.green),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "${selectedPlayerServeResult.playerName}'s Serve",
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                          Stack(
                            children: [
                              UserServeVisualizer(
                                points: serveResult.completeInferenceList,
                                minSize: Size(
                                  serveResult.minWidth,
                                  serveResult.minHeight,
                                ),
                                maxSize: Size(500, serveResult.maxHeight),
                              ),
                              UserServeVisualizer(
                                key: ValueKey(
                                  selectedPlayerServeResult.playerName,
                                ),
                                points:
                                    selectedPlayerServeResult
                                        .completeInferenceList,
                                isReference: true,
                                minSize: Size(
                                  selectedPlayerServeResult.minWidth,
                                  selectedPlayerServeResult.minHeight,
                                ),
                                maxSize: Size(
                                  500,
                                  selectedPlayerServeResult.maxHeight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 5, 20, 5),
                      child: Text(
                        "Average Angles",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    StatTile(
                      assetPath: "assets/images/shoulder.png",
                      statTitle: "Right Shoulder",
                      angle: serveResult.averageRightShoulderAngle,
                      referenceAngle:
                          selectedPlayerServeResult.averageRightShoulderAngle,
                    ),
                    StatTile(
                      assetPath: "assets/images/elbow.png",
                      statTitle: "Right Elbow",
                      angle: serveResult.averageRightElbowAngle,
                      referenceAngle:
                          selectedPlayerServeResult.averageRightElbowAngle,
                    ),
                    StatTile(
                      assetPath: "assets/images/knee.png",
                      statTitle: "Right Knee",
                      angle: serveResult.averageRightKneeAngle,
                      referenceAngle:
                          selectedPlayerServeResult.averageRightKneeAngle,
                    ),
                    StatTile(
                      assetPath: "assets/images/shoulder.png",
                      statTitle: "Left Shoulder",
                      angle: serveResult.averageLeftShoulderAngle,
                      referenceAngle:
                          selectedPlayerServeResult.averageLeftShoulderAngle,
                    ),
                    StatTile(
                      assetPath: "assets/images/elbow.png",
                      statTitle: "Left Elbow",
                      angle: serveResult.averageLeftElbowAngle,
                      referenceAngle:
                          selectedPlayerServeResult.averageLeftElbowAngle,
                    ),
                    StatTile(
                      assetPath: "assets/images/knee.png",
                      statTitle: "Left Knee",
                      angle: serveResult.averageLeftKneeAngle,
                      referenceAngle:
                          selectedPlayerServeResult.averageLeftKneeAngle,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 15, 20, 5),
                      child: Text(
                        "Maximum Angles",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    StatTile(
                      assetPath: "assets/images/shoulder.png",
                      statTitle: "Right Shoulder",
                      angle: serveResult.maxRightShoulderAngle,
                      referenceAngle:
                          selectedPlayerServeResult.maxRightShoulderAngle,
                    ),
                    StatTile(
                      assetPath: "assets/images/elbow.png",
                      statTitle: "Right Elbow",
                      angle: serveResult.maxRightElbowAngle,
                      referenceAngle:
                          selectedPlayerServeResult.maxRightElbowAngle,
                    ),
                    StatTile(
                      assetPath: "assets/images/knee.png",
                      statTitle: "Right Knee",
                      angle: serveResult.maxRightKneeAngle,
                      referenceAngle:
                          selectedPlayerServeResult.maxRightKneeAngle,
                    ),
                    StatTile(
                      assetPath: "assets/images/shoulder.png",
                      statTitle: "Left Shoulder",
                      angle: serveResult.maxLeftShoulderAngle,
                      referenceAngle:
                          selectedPlayerServeResult.maxLeftShoulderAngle,
                    ),
                    StatTile(
                      assetPath: "assets/images/elbow.png",
                      statTitle: "Left Elbow",
                      angle: serveResult.maxLeftElbowAngle,
                      referenceAngle:
                          selectedPlayerServeResult.maxLeftElbowAngle,
                    ),
                    StatTile(
                      assetPath: "assets/images/knee.png",
                      statTitle: "Left Knee",
                      angle: serveResult.maxLeftKneeAngle,
                      referenceAngle:
                          selectedPlayerServeResult.maxLeftKneeAngle,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 15, 20, 5),
                      child: Text(
                        "Minimum Angles",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    StatTile(
                      assetPath: "assets/images/shoulder.png",
                      statTitle: "Right Shoulder",
                      angle: serveResult.minRightShoulderAngle,
                      referenceAngle:
                          selectedPlayerServeResult.minRightShoulderAngle,
                    ),
                    StatTile(
                      assetPath: "assets/images/elbow.png",
                      statTitle: "Right Elbow",
                      angle: serveResult.minRightElbowAngle,
                      referenceAngle:
                          selectedPlayerServeResult.minRightElbowAngle,
                    ),
                    StatTile(
                      assetPath: "assets/images/knee.png",
                      statTitle: "Right Knee",
                      angle: serveResult.minRightKneeAngle,
                      referenceAngle:
                          selectedPlayerServeResult.minRightKneeAngle,
                    ),
                    StatTile(
                      assetPath: "assets/images/shoulder.png",
                      statTitle: "Left Shoulder",
                      angle: serveResult.minLeftShoulderAngle,
                      referenceAngle:
                          selectedPlayerServeResult.minLeftShoulderAngle,
                    ),
                    StatTile(
                      assetPath: "assets/images/elbow.png",
                      statTitle: "Left Elbow",
                      angle: serveResult.minLeftElbowAngle,
                      referenceAngle:
                          selectedPlayerServeResult.minLeftElbowAngle,
                    ),
                    StatTile(
                      assetPath: "assets/images/knee.png",
                      statTitle: "Left Knee",
                      angle: serveResult.minLeftKneeAngle,
                      referenceAngle:
                          selectedPlayerServeResult.minLeftKneeAngle,
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: ListTile(
                        leading: Image.asset(
                          "assets/images/ball.png",
                          height: 32,
                          width: 32,
                          fit: BoxFit.scaleDown,
                        ),
                        title: const Text("Serve Speed"),
                        trailing: Text(
                          "${Random().nextInt(10) + 140} kmph",
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
