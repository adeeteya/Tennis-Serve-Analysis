import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as image_lib;
import 'package:tennis_serve_analysis/controllers/user_controller.dart';
import 'package:tennis_serve_analysis/models/serve_result.dart';
import 'package:tennis_serve_analysis/utility/classifier.dart';
import 'package:tennis_serve_analysis/utility/isolate_utils.dart';
import 'package:tennis_serve_analysis/widgets/analyzing_loading.dart';
import 'package:tennis_serve_analysis/widgets/stat_tile.dart';
import 'package:tennis_serve_analysis/widgets/serve_visualizer.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final XFile pickedVideo;
  const ResultsScreen({Key? key, required this.pickedVideo}) : super(key: key);

  @override
  ConsumerState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  bool isLoading = true;
  double progressValue = 0;
  double videoDuration = 60.19;
  int numberOfImages = 0;
  String outputPath = "";
  late ServeResult serveResult;
  late final ServeResult selectedPlayerServeResult;

  late final Classifier classifier;
  late final IsolateUtils isolate;

  @override
  void initState() {
    initClassifier();
    getDuration();
    saveVideoInImages(File(widget.pickedVideo.path));
    serveResult = ref.read(userServeDataProvider);
    if (ref.read(userServeDataProvider).height < 180) {
      selectedPlayerServeResult = fabioFognini;
    } else if (ref.read(userServeDataProvider).height > 180 &&
        ref.read(userServeDataProvider).isLeftHanded) {
      selectedPlayerServeResult = rafaelNadal;
    } else {
      selectedPlayerServeResult = rogerFederer;
    }
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
      final returnCode = await session.getReturnCode();
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

  Future<List> inference(IsolateData isolateData) async {
    ReceivePort responsePort = ReceivePort();
    isolate.sendPort.send(isolateData..responsePort = responsePort.sendPort);
    var results = await responsePort.first;
    return results;
  }

  Future createIsolates() async {
    setState(() {
      isLoading = true;
    });
    image_lib.Image tmpImage;
    for (int i = 0; i < numberOfImages; i++) {
      tmpImage = image_lib.decodeJpg(File(imagePath(i + 1)).readAsBytesSync())!;
      var isolateData = IsolateData(tmpImage, classifier.interpreter.address);
      List inferenceResults = await inference(isolateData);
      serveResult.addInferenceFromFrame(inferenceResults);
      // print(inferenceResults); ///use this to get inference for players
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Serve Analysis Result"),
        // actions: [
        //   if (!isLoading)
        //     IconButton(
        //       onPressed: () async {
        //         await showDialog(
        //           context: context,
        //           builder: (context) =>
        //               StatefulBuilder(builder: (context, setState) {
        //             return AlertDialog(
        //               title: const Text("Change Reference Player"),
        //               content: Column(
        //                 mainAxisSize: MainAxisSize.min,
        //                 children: [
        //                   RadioListTile(
        //                     title: const Text("Roger Federer"),
        //                     value: 0,
        //                     groupValue: ref.watch(selectedPlayerServeResultProvider),
        //                     onChanged: (val) {
        //                       ref.read(selectedPlayerServeResultProvider.notifier).state =
        //                           val ?? 0;
        //                       setState(() {});
        //                     },
        //                   ),
        //                   RadioListTile(
        //                     title: const Text("Rafael Nadel"),
        //                     value: 1,
        //                     groupValue: ref.watch(selectedPlayerServeResultProvider),
        //                     onChanged: (val) {
        //                       ref.read(selectedPlayerServeResultProvider.notifier).state =
        //                           val ?? 1;
        //                       setState(() {});
        //                     },
        //                   ),
        //                   RadioListTile(
        //                     title: const Text("Fabio Fognini"),
        //                     value: 2,
        //                     groupValue: ref.watch(selectedPlayerServeResultProvider),
        //                     onChanged: (val) {
        //                       ref.read(selectedPlayerServeResultProvider.notifier).state =
        //                           val ?? 2;
        //                       setState(() {});
        //                     },
        //                   ),
        //                 ],
        //               ),
        //               actions: [
        //                 TextButton(
        //                   onPressed: () => Navigator.pop(context),
        //                   child: const Text("Ok"),
        //                 ),
        //               ],
        //             );
        //           }),
        //         );
        //       },
        //       icon: const Icon(Icons.change_circle),
        //     )
        // ],
      ),
      body: (isLoading)
          ? const AnalysisLoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const SizedBox(width: 20),
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: ColoredBox(color: Colors.red),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "User Serve",
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const SizedBox(width: 20),
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: ColoredBox(color: Colors.green),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "${selectedPlayerServeResult.playerName} Serve",
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        Stack(
                          children: [
                            UserServeVisualizer(
                              points: serveResult.completeInferenceList,
                            ),
                            UserServeVisualizer(
                              points: selectedPlayerServeResult
                                  .completeInferenceList,
                              isReference: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 15, 20, 5),
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
                    referenceAngle: selectedPlayerServeResult.maxRightKneeAngle,
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
                    referenceAngle: selectedPlayerServeResult.maxLeftElbowAngle,
                  ),
                  StatTile(
                    assetPath: "assets/images/knee.png",
                    statTitle: "Left Knee",
                    angle: serveResult.maxLeftKneeAngle,
                    referenceAngle: selectedPlayerServeResult.maxLeftKneeAngle,
                  ),
                ],
              ),
            ),
    );
  }
}
