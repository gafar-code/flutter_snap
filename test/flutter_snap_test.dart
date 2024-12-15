import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_snap/flutter_snap.dart';
import 'package:flutter_snap/flutter_snap_platform_interface.dart';
import 'package:flutter_snap/flutter_snap_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterSnapPlatform
    with MockPlatformInterfaceMixin
    implements FlutterSnapPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterSnapPlatform initialPlatform = FlutterSnapPlatform.instance;

  test('$MethodChannelFlutterSnap is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterSnap>());
  });

  test('getPlatformVersion', () async {
    FlutterSnap flutterSnapPlugin = FlutterSnap();
    MockFlutterSnapPlatform fakePlatform = MockFlutterSnapPlatform();
    FlutterSnapPlatform.instance = fakePlatform;

    expect(await flutterSnapPlugin.getPlatformVersion(), '42');
  });
}
