import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tennis_serve_analysis/finals.dart';
import 'package:tennis_serve_analysis/models/serve_result.dart';
import 'package:tennis_serve_analysis/utility/classifier.dart';
import 'package:tennis_serve_analysis/utility/isolate_utils.dart';

final selectedPlayerProvider = StateProvider.family<ServeResult, int?>((
  ref,
  index,
) {
  final userServeResult = ref.watch(userServeDataProvider);
  if (index == null) {
    if (userServeResult.isLeftHanded) {
      return rafaelNadal;
    } else if (userServeResult.height > 180) {
      return rogerFederer;
    } else {
      return fabioFognini;
    }
  }
  return availableReferencePlayers[index];
});

final userServeDataProvider =
    NotifierProvider<UserServeResultNotifier, ServeResult>(
      UserServeResultNotifier.new,
    );

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

  void reset() {
    state = ServeResult("User", state.height, state.isLeftHanded);
  }

  void onHeightChanged(int newHeight) {
    state = state.copyWith(height: newHeight);
  }

  void onHandinessChange(bool isLeftHanded) {
    state = state.copyWith(isLeftHanded: isLeftHanded);
  }
}
