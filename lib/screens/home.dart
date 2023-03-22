import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tennis_serve_analysis/screens/preview_screen.dart';
import 'package:video_player/video_player.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final VideoPlayerController _backgroundVideoController;

  @override
  void initState() {
    _backgroundVideoController =
        VideoPlayerController.asset("assets/videos/Background_Video.mp4")
          ..initialize().then((_) {
            setState(() {});
            _backgroundVideoController.setLooping(true);
            _backgroundVideoController.play();
          });
    super.initState();
  }

  @override
  void dispose() {
    _backgroundVideoController.dispose();
    super.dispose();
  }

  void uploadVideo() async {
    final ImagePicker picker = ImagePicker();
    await picker.pickVideo(source: ImageSource.gallery).then((pickedVideo) {
      if (pickedVideo != null) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PreviewScreen(pickedVideo: pickedVideo)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Opacity(
            opacity: 0.7,
            child: VideoPlayer(_backgroundVideoController),
          ),
          SafeArea(
            minimum: const EdgeInsets.only(top: 50, bottom: 25),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Text(
                    "Tennis Serve Analyzer",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: uploadVideo,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Upload Serve Video"),
                  ),
                  const Spacer(),
                  Text(
                    "Upload a video of your serve in side serving angle at normal speed. Preferably in landscape",
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
