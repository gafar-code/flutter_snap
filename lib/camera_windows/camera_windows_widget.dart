// ignore_for_file: depend_on_referenced_packages, override_on_non_overriding_member

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gradient_text/flutter_gradient_text.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mobkit_dashed_border/mobkit_dashed_border.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_zxing/flutter_zxing.dart';

import 'camera_windows_controller.dart';
import 'camera_windows_status.dart';

class CameraWindowsWidget extends StatefulWidget {
  final void Function(CameraWindowsController) onCameraInitialized;
  final CameraType type;
  final Widget? loadingWidget;
  final Widget? connectedWiget;
  final Widget? notConnectedWidget;
  final Widget? errorWidget;
  final Widget? Function(Widget preview)? pausedWidget;
  final Widget? Function(Widget preview)? openedWidget;
  final Widget? closedWidget;
  final Function(File)? onCapture;
  final Widget? overlayWidget;
  const CameraWindowsWidget(
      {super.key,
      required this.onCameraInitialized,
      this.type = CameraType.selfie,
      this.connectedWiget,
      this.notConnectedWidget,
      this.errorWidget,
      this.pausedWidget,
      this.openedWidget,
      this.loadingWidget,
      this.closedWidget,
      this.onCapture,
      this.overlayWidget});

  @override
  State<CameraWindowsWidget> createState() => _CameraWindowsWidgetState();
}

class _CameraWindowsWidgetState extends State<CameraWindowsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late CameraWindowsController _camC;

  late CameraStatus _status;
  int countTakePhoto = 4;
  Timer? _timer;
  double _opacity = 0.0;
  var cameraType = CameraType.init;

  String cameraLogInfo = 'Unknown';
  List<CameraDescription> _cameras = <CameraDescription>[];
  int _cameraIndex = 0;
  int cameraIds = -1;
  bool _initialized = false;
  Timer? _timerTakeQr;
  Uint8List? _capturedImage;
  XFile? _imgTmp;
  Size cameraPreviewSize = const Size(1080, 1920);

  final MediaSettings _mediaSettings = const MediaSettings(
    resolutionPreset: ResolutionPreset.max,
    fps: 30,
    enableAudio: false,
  );

  StreamSubscription<CameraErrorEvent>? _errorStreamSubscription;
  StreamSubscription<CameraClosingEvent>? _cameraClosingStreamSubscription;

  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized();
    _status = CameraStatusOpened('Open');
    _openCam();
    _camC = CameraWindowsController()
      ..openCam = _openCam
      ..retry = _retry
      ..pause = _pause
      ..stop = _stop
      ..resume = _resume
      ..capture = _capture;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _stop();
    super.dispose();
  }

  Future<void> _openCam() async {
    String cameraInfo;
    List<CameraDescription> cameras = <CameraDescription>[];

    // int cameraIndex = 0;
    try {
      cameras = await CameraPlatform.instance.availableCameras();
      log(cameras.toString());
      if (cameras.isEmpty) {
        cameraInfo = 'No available cameras';
        _status = CameraStatusNotConnected(cameraInfo);
      } else {
        // cameraIndex = _cameraIndex % cameras.length;
        cameraInfo = 'Found camera: ${cameras[0].name}';
        if (mounted) {
          setState(() {
            // _cameraIndex = cameraIndex;
            _cameras = cameras;
            cameraLogInfo = cameraInfo;
          });
          await _initializeCamera();
        }
      }
    } on PlatformException catch (e) {
      cameraInfo = 'Failed to get cameras: ${e.code}: ${e.message}';
    }
  }

  Future<void> _initializeCamera() async {
    if (_cameras.isEmpty) {
      return;
    }

    int cameraId = 1;
    // final int cameraIndex = (_cameraIndex + 1) % _cameras.length;
    final CameraDescription camera = _cameras[1];

    cameraId = await CameraPlatform.instance.createCameraWithSettings(
      camera,
      _mediaSettings,
    );

    // AppStorage.saveCameraId(cameraId);

    unawaited(_errorStreamSubscription?.cancel());
    _errorStreamSubscription =
        CameraPlatform.instance.onCameraError(cameraId).listen(_onCameraError);

    unawaited(_cameraClosingStreamSubscription?.cancel());
    _cameraClosingStreamSubscription = CameraPlatform.instance
        .onCameraClosing(cameraId)
        .listen(_onCameraClosing);

    final Future<CameraInitializedEvent> initialized =
        CameraPlatform.instance.onCameraInitialized(cameraId).first;

    await CameraPlatform.instance.initializeCamera(
      cameraId,
    );

    final CameraInitializedEvent event = await initialized;

    cameraPreviewSize = Size(
      event.previewWidth,
      event.previewHeight,
    );

    try {
      if (mounted) {
        if (widget.type == CameraType.scan) {
          readQr();
        } else {}
        setState(() {
          _status = CameraStatusOpened('Open');
          _initialized = true;
          cameraIds = cameraId;
          cameraLogInfo = 'Capturing camera: ${camera.name}';
        });
      }
    } on CameraException {
      try {
        if (cameraId >= 0) {
          await CameraPlatform.instance.dispose(cameraId);
        }
      } on CameraException catch (e) {
        debugPrint('Failed to dispose camera: ${e.code}: ${e.description}');
      }
    }
  }

  Future<void> _disposeCurrentCamera() async {
    try {
      await CameraPlatform.instance.dispose(cameraIds);
      _initialized = false;
      cameraIds = -1;
      // AppStorage.saveCameraId(cameraIds);
      cameraLogInfo = 'Camera disposed';
    } on CameraException catch (e) {
      if (mounted) {
        setState(() {
          cameraLogInfo =
              'Failed to dispose camera: ${e.code}: ${e.description}';
        });
      }
    }
  }

  void _onCameraError(CameraErrorEvent event) {
    if (mounted) {
      _status = CameraStatusError(event.description);
      setState(() {});
    }
  }

  void readQr() async {
    if (_camC.onScan != null) {
      _timerTakeQr = Timer.periodic(2.seconds, (timer) async {
        final XFile file = await CameraPlatform.instance.takePicture(cameraIds);
        final result = await zx.readBarcodeImagePath(
            file, DecodeParams(imageFormat: ImageFormat.rgb));
        if (result.text != null) {
          _timerTakeQr?.cancel();
          _deleteImageTemp(file);
          _camC.onScan!(result.text!);
        } else {
          _deleteImageTemp(file);
        }
      });
    }
  }

  void _deleteImageTemp(XFile? file) async {
    try {
      final filePath = file?.path ?? '';
      final fileToDelete = File(filePath);
      if (await fileToDelete.exists()) {
        await fileToDelete.delete();
      }
    } catch (e) {
      log("Gagal menghapus file: $e");
    }
  }

  void _onCameraClosing(CameraClosingEvent event) {
    if (mounted) {
      // AppStorage.saveCameraId(0);
    }
  }

  Future<void> _retry() async {
    if (_cameras.isNotEmpty) {
      _cameraIndex = (_cameraIndex + 1) % _cameras.length;
      if (_initialized && cameraIds >= 0) {
        await _disposeCurrentCamera();
        await _openCam();
        if (_cameras.isNotEmpty) {
          await _initializeCamera();
        }
      } else {
        await _openCam();
      }
    }
  }

  void _restart() {
    _stop();
    _openCam();
  }

  void _pause() async {
    await CameraPlatform.instance.pausePreview(cameraIds);
    _status = CameraStatusPaused('Camera Paused');
    if (mounted) setState(() {});
  }

  void _resume() async {
    await CameraPlatform.instance.resumePreview(cameraIds);
    _status = CameraStatusOpened('Camera Opened');
    if (widget.type == CameraType.scan) {
      readQr();
    } else {
      if (_capturedImage != null) {
        _deleteImageTemp(_imgTmp);
      }
    }
    setState(() {});
  }

  void _stop() {
    _disposeCurrentCamera();
    _errorStreamSubscription?.cancel();
    _errorStreamSubscription = null;
    _cameraClosingStreamSubscription?.cancel();
    _cameraClosingStreamSubscription = null;
    if (_capturedImage != null) _deleteImageTemp(_imgTmp);
  }

  Future<void> _capture() async {
    if (widget.type == CameraType.selfie && widget.onCapture != null) {
      _timer?.cancel();

      _timer = Timer.periodic(const Duration(seconds: 1), (value) async {
        countTakePhoto--;
        if (mounted) setState(() {});

        if (countTakePhoto == 0) {
          _timer?.cancel();
          _triggerFlash();
          countTakePhoto = 4;
          final XFile file =
              await CameraPlatform.instance.takePicture(cameraIds);
          Uint8List capturedImage = await file.readAsBytes();
          img.Image? image = img.decodeImage(capturedImage);

          if (image != null) {
            img.Image rotatedImage = img.copyRotate(image, angle: -90);
            img.Image flipImage = img.copyFlip(rotatedImage,
                direction: img.FlipDirection.horizontal);
            File outputFile = File(file.path);
            await outputFile.writeAsBytes(img.encodeJpg(flipImage));
            widget.onCapture!(outputFile);

            if (mounted) setState(() {});
            _pause();
            if (mounted) setState(() {});
          } else {
            log("Failed to decode the image");
          }
        }
      });
    }
  }

  void _triggerFlash() {
    if (mounted) {
      setState(() {
        _opacity = 1.0;
      });
    }
    Timer(const Duration(milliseconds: 20), () {
      if (mounted) {
        setState(() {
          _opacity = 0.0;
        });
      }
    });
  }

  Widget get _previewSelfie {
    return Column(
      children: [
        Gap(cameraPreviewSize.height / 18),
        Transform.rotate(
          angle: 3.14159 / 2,
          child: AspectRatio(
            aspectRatio: (cameraPreviewSize.aspectRatio),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Transform.flip(
                    flipY: true,
                    child: CameraPlatform.instance.buildPreview(cameraIds)),
                ),
                if (widget.overlayWidget != null)
                  Positioned.fill(
                    child: SizedBox(
                      width: cameraPreviewSize.width,
                      height: cameraPreviewSize.height,
                      child: widget.overlayWidget,
                    ),
                  ),
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: _opacity,
                    duration: const Duration(milliseconds: 20),
                    child: Container(
                      color: Colors.white,
                      width: cameraPreviewSize.width,
                      height: cameraPreviewSize.height,
                    ),
                  ),
                ),
                Positioned.fill(
                    child: Transform.rotate(
                  angle: 3.14159 / -2,
                  child: Visibility(
                    visible: countTakePhoto < 4 && countTakePhoto != 0,
                    child: Center(
                        child: GradientText(
                            Text('$countTakePhoto',
                                style: const TextStyle(
                                    fontSize: 142, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center),
                            type: Type.linear,
                            radius: 1,
                            colors: const [Color(0xffAD9A4A), Colors.white])),
                  ),
                ))
              ],
            ),
          ),
        ),
        Gap(cameraPreviewSize.height / 16),
      ],
    );
  }

  Widget get _previewScan {
    return _initialized
        ? Column(
            children: [
              Gap(cameraPreviewSize.height / 20),
              Transform.rotate(
                angle: 3.14159 / 2,
                child: AspectRatio(
                    aspectRatio: (cameraPreviewSize.aspectRatio),
                    child: LayoutBuilder(builder: (_, constraints) {
                      return Stack(children: [
                        Transform.scale(
                            scale: .96,
                            child: Center(
                                child: CameraPlatform.instance
                                    .buildPreview(cameraIds))),
                        Positioned(
                            bottom: 0,
                            top: 0,
                            left: 0,
                            child: Container(
                              color: Colors.black,
                              width: constraints.maxWidth / 4,
                            )),
                        Positioned(
                            bottom: 0,
                            top: 0,
                            right: 0,
                            child: Container(
                              color: Colors.black,
                              width: constraints.maxWidth / 4,
                            )),
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: constraints.maxWidth / 4.2,
                          right: constraints.maxWidth / 4.2,
                          child: Container(
                            decoration: BoxDecoration(
                                border: DashedBorder.all(
                                  color: const Color(0xffAD9A4A),
                                  dashLength: 60,
                                  width: 5,
                                  isOnlyCorner: true,
                                  strokeAlign: BorderSide.strokeAlignOutside,
                                  strokeCap: StrokeCap.round,
                                ),
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        )
                      ]);
                    })),
              ),
            ],
          )
        : const SizedBox.shrink();
  }

  Widget get _connectedWidget {
    return widget.connectedWiget != null
        ? widget.connectedWiget!
        : Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(_status.message),
                ElevatedButton(
                    onPressed: _openCam, child: const Text("Open Camera"))
              ],
            ),
          );
  }

  Widget get _notConnectedWidget {
    return widget.notConnectedWidget != null
        ? widget.notConnectedWidget!
        : Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(_status.message),
                ElevatedButton(
                    onPressed: _restart, child: const Text("Restart"))
              ],
            ),
          );
  }

  Widget get _errorWidget {
    return widget.errorWidget != null
        ? widget.errorWidget!
        : Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(_status.message),
                ElevatedButton(onPressed: _retry, child: const Text("Retry"))
              ],
            ),
          );
  }

  Widget get _openedWidget {
    return widget.openedWidget != null
        ? widget.openedWidget!(
            widget.type == CameraType.scan ? _previewScan : _previewSelfie)!
        : Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.type == CameraType.selfie) _previewSelfie,
                if (widget.type == CameraType.scan) _previewScan,
                Text(_status.message),
                ElevatedButton(onPressed: _pause, child: const Text("Pause")),
                ElevatedButton(onPressed: _stop, child: const Text("Stop")),
                ElevatedButton(
                    onPressed: _capture, child: const Text("Capture Image")),
              ],
            ),
          );
  }

  Widget get _pausedWidget {
    return widget.pausedWidget != null
        ? widget.pausedWidget!(
            widget.type == CameraType.scan ? _previewScan : _previewSelfie)!
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.type == CameraType.selfie) _previewSelfie,
                if (widget.type == CameraType.scan) _previewScan,
                Text(_status.message),
                ElevatedButton(
                  onPressed: _resume,
                  child: const Text("Resume"),
                ),
                ElevatedButton(
                  onPressed: _stop,
                  child: const Text("Stop"),
                ),
              ],
            ),
          );
  }

  Widget get _closedWidget {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(_status.message),
          ElevatedButton(onPressed: _openCam, child: const Text("Open Camera"))
        ],
      ),
    );
  }

  Widget get _child {
    if (_status is CameraStatusConnected) {
      return _connectedWidget;
    } else if (_status is CameraStatusNotConnected) {
      return _notConnectedWidget;
    } else if (_status is CameraStatusError) {
      return _errorWidget;
    } else if (_status is CameraStatusOpened) {
      return _openedWidget;
    } else if (_status is CameraStatusPaused) {
      return _pausedWidget;
    } else if (_status is CameraStatusClosed) {
      return _closedWidget;
    }

    return Center(child: Text(_status.message));
  }

  @override
  Widget build(BuildContext context) {
    return _child;
  }
}

enum CameraType { init, scan, selfie }
