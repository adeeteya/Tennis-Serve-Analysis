import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tennis_serve_analysis/models/user_data.dart';

final userDataProvider =
    NotifierProvider<UserDataNotifier, UserData>(() => UserDataNotifier());

class UserDataNotifier extends Notifier<UserData> {
  @override
  UserData build() {
    return UserData(185, false);
  }

  void onHeightChanged(int newHeight) {
    state = state.copyWith(height: newHeight);
  }

  void onHandinessChange(bool isLeftHanded) {
    state = state.copyWith(isLeftHanded: isLeftHanded);
  }
}
