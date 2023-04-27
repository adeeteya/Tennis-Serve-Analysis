import 'package:image_picker/image_picker.dart';

class UserData {
  final int height;
  final bool isLeftHanded;

  UserData(this.height, this.isLeftHanded);

  UserData copyWith({int? height, bool? isLeftHanded, XFile? serveVideo}) {
    return UserData(
      height ?? this.height,
      isLeftHanded ?? this.isLeftHanded,
    );
  }
}
