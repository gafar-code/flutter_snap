abstract class CameraStatus {
  String get message;
}

class CameraStatusError extends CameraStatus {
  @override
  final String message;

  CameraStatusError(this.message);
}

class CameraStatusNotConnected extends CameraStatus {
  @override
  final String message;

  CameraStatusNotConnected(this.message);
}

class CameraStatusConnected extends CameraStatus {
  @override
  final String message;

  CameraStatusConnected(this.message);
}

class CameraStatusOpened extends CameraStatus {
  @override
  final String message;

  CameraStatusOpened(this.message);
}

class CameraStatusPaused extends CameraStatus {
  @override
  final String message;

  CameraStatusPaused(this.message);
}

class CameraStatusClosed extends CameraStatus {
  @override
  final String message;

  CameraStatusClosed(this.message);
}
