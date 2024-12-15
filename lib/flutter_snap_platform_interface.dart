import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_snap_method_channel.dart';

abstract class FlutterSnapPlatform extends PlatformInterface {
  /// Constructs a FlutterSnapPlatform.
  FlutterSnapPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterSnapPlatform _instance = MethodChannelFlutterSnap();

  /// The default instance of [FlutterSnapPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterSnap].
  static FlutterSnapPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterSnapPlatform] when
  /// they register themselves.
  static set instance(FlutterSnapPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
