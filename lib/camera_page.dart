import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/countdown_timer_controller.dart';

import 'library.dart';

class CameraPage extends StatefulWidget {
  final int? allowedTimeInSeconds;
  const CameraPage({Key? key, this.allowedTimeInSeconds}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  bool _isLoading = true;
  bool _isRecording = false;
  CameraController? _cameraController;
  List<CameraDescription> cameras = [];
  double? _maxAvailableZoom;
  double? _minAvailableZoom;
  CameraDescription? currentCamera;
  late CountdownTimerController _timerController;
  int allowedTimeInSeconds = 120;
  double progressValue = 0;

  @override
  void initState() {
    if (widget.allowedTimeInSeconds != null) {
      allowedTimeInSeconds = widget.allowedTimeInSeconds!;
    }

    _timerController = CountdownTimerController(
      endTime: DateTime.now()
          .add(Duration(seconds: allowedTimeInSeconds))
          .millisecondsSinceEpoch,
    );
    _initCamera();
    super.initState();
  }

  void startTimer() {
    _timerController = CountdownTimerController(
      endTime: DateTime.now()
          .add(Duration(seconds: allowedTimeInSeconds))
          .millisecondsSinceEpoch,
    );
    _timerController.start();
    int allowedMilliSeconds = allowedTimeInSeconds * 1000;
    _timerController.addListener(() {
      var secFromMin = (_timerController.currentRemainingTime?.min ?? 0) * 60;
      var sec = _timerController.currentRemainingTime?.sec! ?? 0;
      var totalSec = (secFromMin + sec) * 1000;
      debugPrint(totalSec.toString());
      debugPrint((totalSec / allowedMilliSeconds).toString());
      progressValue = 1 - (totalSec / allowedMilliSeconds);
      setState(() {});
    });
  }

  void stopTimer() {
    if (_timerController != null) {
      _timerController.removeListener(() {});
    }
    if (_timerController.isRunning) {
      _timerController.dispose();
    }
  }

  @override
  void dispose() {
    if (_cameraController != null) {
      _cameraController!.dispose();
    }
    super.dispose();
  }

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    final CameraController? oldController = _cameraController;
    if (oldController != null) {
      _cameraController = null;
      await oldController.dispose();
    }

    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.max,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _cameraController = cameraController;
    setState(() {
      currentCamera = cameraDescription;
    });

    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (cameraController.value.hasError) {
        showInSnackBar('An unknown error occurred');
      }
    });

    try {
      await cameraController.initialize();
      await Future.wait(<Future<Object?>>[
        cameraController
            .getMaxZoomLevel()
            .then((double value) => _maxAvailableZoom = value),
        cameraController
            .getMinZoomLevel()
            .then((double value) => _minAvailableZoom = value),
      ]);
    } on CameraException catch (e) {
      switch (e.code) {
        case 'CameraAccessDenied':
          showInSnackBar('You have denied camera access.');
          break;
        case 'CameraAccessDeniedWithoutPrompt':
          showInSnackBar('Please go to Settings app to enable camera access.');
          break;
        case 'CameraAccessRestricted':
          showInSnackBar('Camera access is restricted.');
          break;
        case 'AudioAccessDenied':
          showInSnackBar('You have denied audio access.');
          break;
        case 'AudioAccessDeniedWithoutPrompt':
          showInSnackBar('Please go to Settings app to enable audio access.');
          break;
        case 'AudioAccessRestricted':
          showInSnackBar('Audio access is restricted.');
          break;
        default:
          showInSnackBar(e.description.toString());
          break;
      }
    } catch (e) {
      showInSnackBar(e.toString());
    }

    if (mounted) {
      setState(() {});
    }
  }

  void showInSnackBar(String message) {
    debugPrint(message);
  }

  _initCamera() async {
    cameras = await availableCameras();
    final front = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front);
    _cameraController = CameraController(front, ResolutionPreset.high);
    await _cameraController!.initialize();
    currentCamera = front;
    setState(() => _isLoading = false);
  }

  _recordVideo() async {
    if (_isRecording) {
      stopTimer();
      final file = await _cameraController!.stopVideoRecording();
      setState(() => _isRecording = false);
      final route = MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => VideoPage(filePath: file.path),
      );
      var viewedFile = await Navigator.push(context, route);
      Navigator.pop(context, viewedFile);
    } else {
      await _cameraController!.prepareForVideoRecording();
      await _cameraController!.startVideoRecording();
      setState(() => _isRecording = true);
      startTimer();
    }
  }

  void onSetFlashModeButtonPressed(FlashMode mode) {
    setFlashMode(mode).then((_) {
      if (mounted) {
        setState(() {});
      }
      showInSnackBar('Flash mode set to ${mode.toString().split('.').last}');
    });
  }

  Future<void> setFlashMode(FlashMode mode) async {
    if (_cameraController == null) {
      return;
    }

    try {
      await _cameraController!.setFlashMode(mode);
    } on CameraException catch (e) {
      showInSnackBar(e.toString());
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    if (_isLoading) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
          ),
          backgroundColor: Colors.black,
          body: SizedBox(
            height: size.height,
            width: size.width,
            child: Stack(
              children: [
                ClipRRect(
                    child: SizedOverflowBox(
                        size: Size(size.width, size.height / 1.2),
                        child: CameraPreview(_cameraController!))),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 32,
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_timerController.isRunning)
                          MyCountDown(
                              allowedTimeInSeconds: allowedTimeInSeconds,
                              onEnd: () {
                                log("Recording ended::::");
                                if (!_isRecording) {
                                  _recordVideo();
                                }
                              }),
                        const SizedBox(
                          height: 16,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _isRecording
                                ? const SizedBox()
                                : _flashModeControlRowWidget(),
                            SizedBox(
                              height: 64,
                              width: 64,
                              child: Stack(
                                children: [
                                  ProgressWrapper(
                                    progress: progressValue,
                                  ),
                                  Center(
                                    child: FloatingActionButton(
                                      backgroundColor: Colors.red,
                                      child: Icon(_isRecording
                                          ? Icons.stop
                                          : Icons.circle),
                                      onPressed: () => _recordVideo(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _isRecording
                                ? const SizedBox()
                                : IconButton(
                                    onPressed: () {
                                      var back = cameras
                                          .where((element) =>
                                              element.lensDirection ==
                                              CameraLensDirection.back)
                                          .first;
                                      var front = cameras
                                          .where((element) =>
                                              element.lensDirection ==
                                              CameraLensDirection.front)
                                          .first;

                                      if (currentCamera == front) {
                                        onNewCameraSelected(back);
                                      } else {
                                        onNewCameraSelected(front);
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.cameraswitch_outlined,
                                      color: Colors.white,
                                    )),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _flashModeControlRowWidget() {
    var color = Colors.white;
    return ClipRect(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          if (_cameraController?.value.flashMode == FlashMode.off)
            IconButton(
              icon: Icon(
                Icons.flash_off,
                color: color,
              ),
              color: _cameraController?.value.flashMode == FlashMode.off
                  ? Colors.orange
                  : Colors.blue,
              onPressed: _cameraController != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.auto)
                  : null,
            ),
          if (_cameraController?.value.flashMode == FlashMode.auto)
            IconButton(
              icon: Icon(
                Icons.flash_auto,
                color: color,
              ),
              color: _cameraController?.value.flashMode == FlashMode.auto
                  ? Colors.orange
                  : Colors.blue,
              onPressed: _cameraController != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.always)
                  : null,
            ),
          if (_cameraController?.value.flashMode == FlashMode.always)
            IconButton(
              icon: Icon(
                Icons.flash_on,
                color: color,
              ),
              color: _cameraController?.value.flashMode == FlashMode.always
                  ? Colors.orange
                  : Colors.blue,
              onPressed: _cameraController != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.off)
                  : null,
            ),
        ],
      ),
    );
  }
}
