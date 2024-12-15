// ignore_for_file: depend_on_referenced_packages

class CameraWindowsController {
  late Future<void> Function() openCam;
  late void Function() retry;
  late void Function() pause;
  late void Function() stop;
  late void Function() resume;
  late void Function() capture;
  late void Function(String)? onScan;

  CameraWindowsController({this.onScan});
}
