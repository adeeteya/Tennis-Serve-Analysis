import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tennis_serve_analysis/models/serve_result.dart';
import 'package:tennis_serve_analysis/utility/classifier.dart';
import 'package:tennis_serve_analysis/utility/isolate_utils.dart';

final selectedPlayerProvider = StateProvider<int>((ref) => 0);

final userServeDataProvider =
    NotifierProvider<UserServeResultNotifier, ServeResult>(
        () => UserServeResultNotifier());

class UserServeResultNotifier extends Notifier<ServeResult> {
  double videoDuration = 60.19;
  int numberOfImages = 0;
  String outputPath = "";
  late final Classifier classifier;
  late final IsolateUtils isolate;

  @override
  ServeResult build() {
    return ServeResult("User", 185, false);
  }

  void onHeightChanged(int newHeight) {
    state = state.copyWith(height: newHeight);
  }

  void onHandinessChange(bool isLeftHanded) {
    state = state.copyWith(isLeftHanded: isLeftHanded);
  }
}
