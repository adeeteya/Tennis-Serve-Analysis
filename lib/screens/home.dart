import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tennis_serve_analysis/screens/preview_screen.dart';
import 'package:tennis_serve_analysis/widgets/handiness_picker.dart';
import 'package:tennis_serve_analysis/widgets/height_picker.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  Future uploadVideo(BuildContext context) async {
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
      appBar: AppBar(
        title: const Text("Tennis Serve Analyzer"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          children: [
            const Expanded(child: HeightPicker()),
            Row(
              children: [
                const HandinessPicker(),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.indigo,
                      minimumSize: const Size(30, 100),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Instructions"),
                          content: const Text(
                              "1. Record Video in Normal Speed\n2. Record Video in Landscape Mode\n3. Ensure that there is adequate lighting\n4. Make Sure that the Central Service Line is visible and at the extreme left/right end of the video"),
                          actions: [
                            TextButton.icon(
                              onPressed: () {
                                uploadVideo(context);
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.upload),
                              label: const Text("UPLOAD"),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text(
                      "Upload Serve Video",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
