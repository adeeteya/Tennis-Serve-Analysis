import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tennis_serve_analysis/screens/results_screen.dart';
import 'package:video_player/video_player.dart';

class PreviewScreen extends StatefulWidget {
  final XFile pickedVideo;
  const PreviewScreen({Key? key, required this.pickedVideo}) : super(key: key);

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final VideoPlayerController _videoPlayerController;
  bool isPlaying = false;
  double playbackSpeed = 0.5;

  @override
  void initState() {
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _videoPlayerController =
        VideoPlayerController.file(File(widget.pickedVideo.path))
          ..initialize().then((_) {
            setState(() {});
            _videoPlayerController.setLooping(true);
            _videoPlayerController.setPlaybackSpeed(0.5);
          });
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _videoPlayerController.dispose();
    super.dispose();
  }

  void togglePlayback() {
    if (isPlaying) {
      setState(() {
        isPlaying = false;
      });
      _videoPlayerController.pause();
    } else {
      setState(() {
        isPlaying = true;
      });
      _videoPlayerController.play();
    }
  }

  Widget playBackSpeedButton(String speedString) {
    double newSpeed = double.parse(speedString);
    return FloatingActionButton(
      heroTag: "${speedString}x Button",
      onPressed: () {
        setState(() {
          playbackSpeed = newSpeed;
        });
        _videoPlayerController.setPlaybackSpeed(newSpeed);
        _animationController.reverse();
      },
      child: Text("${speedString}x"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Preview Serve"),
        actions: [
          IconButton(
            tooltip: "Continue",
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) =>
                      ResultsScreen(pickedVideo: widget.pickedVideo),
                ),
              );
            },
            icon: const Icon(Icons.start),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "Playback Button",
        onPressed: togglePlayback,
        child: Icon((isPlaying) ? Icons.pause : Icons.play_arrow),
      ),
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _videoPlayerController.value.aspectRatio,
              child: VideoPlayer(_videoPlayerController),
            ),
          ),
          Flow(
            delegate: ColumnMenuFlowDelegate(_animationController),
            clipBehavior: Clip.none,
            children: [
              FloatingActionButton(
                heroTag: "Playback Speed Button",
                elevation: 0,
                onPressed: () {
                  if (_animationController.isCompleted) {
                    _animationController.reverse();
                  } else {
                    _animationController.forward();
                  }
                },
                child: Text(
                    "${(playbackSpeed == 1) ? "1" : (playbackSpeed == 1.5 || playbackSpeed == 0.5) ? playbackSpeed.toStringAsFixed(1) : playbackSpeed.toStringAsFixed(2)}x"),
              ),
              playBackSpeedButton("1.5"),
              playBackSpeedButton("1"),
              playBackSpeedButton("0.75"),
              playBackSpeedButton("0.5"),
              playBackSpeedButton("0.25"),
            ],
          ),
        ],
      ),
    );
  }
}

class ColumnMenuFlowDelegate extends FlowDelegate {
  final Animation<double> controller;

  ColumnMenuFlowDelegate(this.controller) : super(repaint: controller);
  @override
  void paintChildren(FlowPaintingContext context) {
    const double margin = 16;
    final yStart = context.size.height - 56 - margin;
    for (int i = context.childCount - 1; i >= 0; i--) {
      final childHeight = context.getChildSize(i)?.height ?? 56;
      final childYPosition = (childHeight + margin) * i;
      final dy = yStart - childYPosition * controller.value;
      context.paintChild(
        i,
        transform: Matrix4.translationValues(
          margin,
          dy,
          -10,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant FlowDelegate oldDelegate) => false;
}
