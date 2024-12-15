import 'package:flutter/material.dart';
import 'package:flutter_snap/camera_windows/camera_windows_controller.dart';
import 'package:flutter_snap/camera_windows/camera_windows_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  CameraWindowsController? _camC;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                        onPressed: (){}, child: const Text("Open")),
                    ElevatedButton(
                        onPressed: (){}, child: const Text("Stop")),
                    ElevatedButton(
                        onPressed:(){}, child: const Text("Pause")),
                    ElevatedButton(
                        onPressed: (){},
                        child: const Text("Capture "),),

                    // late Future<void> Function() openCam;
                    // late void Function() retry;
                    // late void Function() pause;
                    // late void Function() stop;
                    // late void Function() resume;
                    // late void Function() capture;
                    // late void Function(String)? onScan;
                  ],
                ),
              ),
              CameraWindowsWidget(
                onCameraInitialized:(c) => _camC = c,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
