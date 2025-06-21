import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tennis_serve_analysis/screens/results_screen.dart';
import 'package:video_player/video_player.dart';

class PreviewScreen extends StatefulWidget {
  final XFile pickedVideo;
  const PreviewScreen({super.key, required this.pickedVideo});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final VideoPlayerController _videoPlayerController;
  bool _isPlaying = false;
  double _playbackSpeed = 0.5;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _videoPlayerController = VideoPlayerController.file(
      File(widget.pickedVideo.path),
    );
    unawaited(_initializeVideoPlayer());
    super.initState();
  }

  Future<void> _initializeVideoPlayer() async {
    await _videoPlayerController.initialize();
    await _videoPlayerController.setLooping(true);
    await _videoPlayerController.setPlaybackSpeed(0.5);
    setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    unawaited(_videoPlayerController.dispose());
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      setState(() {
        _isPlaying = false;
      });
      await _videoPlayerController.pause();
    } else {
      setState(() {
        _isPlaying = true;
      });
      await _videoPlayerController.play();
    }
  }

  Widget _playBackSpeedButton(String speedString) {
    final double newSpeed = double.parse(speedString);
    return FloatingActionButton(
      heroTag: "${speedString}x Button",
      tooltip: "${speedString}x Speed",
      onPressed: () async {
        setState(() {
          _playbackSpeed = newSpeed;
        });
        await _videoPlayerController.setPlaybackSpeed(newSpeed);
        await _animationController.reverse();
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
            onPressed: () async {
              await Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder:
                      (context) =>
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
        tooltip: _isPlaying ? "Pause" : "Play",
        onPressed: _togglePlayback,
        child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoPlayerController.value.size.width,
                height: _videoPlayerController.value.size.height,
                child: VideoPlayer(_videoPlayerController),
              ),
            ),
          ),
          Flow(
            delegate: ColumnMenuFlowDelegate(_animationController),
            clipBehavior: Clip.none,
            children: [
              FloatingActionButton(
                heroTag: "Playback Speed Button",
                tooltip: "Playback Speed",
                elevation: 0,
                onPressed: () {
                  if (_animationController.isCompleted) {
                    _animationController.reverse();
                  } else {
                    _animationController.forward();
                  }
                },
                child: Text(
                  "${(_playbackSpeed == 1)
                      ? "1"
                      : (_playbackSpeed == 1.5 || _playbackSpeed == 0.5)
                      ? _playbackSpeed.toStringAsFixed(1)
                      : _playbackSpeed.toStringAsFixed(2)}x",
                ),
              ),
              _playBackSpeedButton("1.5"),
              _playBackSpeedButton("1"),
              _playBackSpeedButton("0.75"),
              _playBackSpeedButton("0.5"),
              _playBackSpeedButton("0.25"),
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
        transform: Matrix4.translationValues(margin, dy, -10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant FlowDelegate oldDelegate) => false;
}
