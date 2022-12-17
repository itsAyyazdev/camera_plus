import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/countdown_timer_controller.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:camera_plus/progress_wrapper.dart';
import 'package:camera_plus/video_page.dart';

class CameraPage extends StatefulWidget {
  int? allowedTimeInMinutes;
  CameraPage({Key? key, this.allowedTimeInMinutes}) : super(key: key);

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
  int allowedTimeInMinutes = 2;
  double loaderValue = 0;
  @override
  void initState() {
    if (widget.allowedTimeInMinutes != null) {
      allowedTimeInMinutes = widget.allowedTimeInMinutes!;
    }
    _timerController = CountdownTimerController(
      endTime: DateTime.now()
          .add(Duration(minutes: allowedTimeInMinutes))
          .millisecondsSinceEpoch,
    );
    _initCamera();
    super.initState();
  }

  void startTimer() {
    _timerController = CountdownTimerController(
      endTime: DateTime.now()
          .add(Duration(minutes: allowedTimeInMinutes))
          .millisecondsSinceEpoch,
    );
    _timerController.start();
    int allowedMilliSeconds = (allowedTimeInMinutes * 60) * 1000;
    _timerController.addListener(() {
      var secFromMin = (_timerController.currentRemainingTime!.min ?? 0) * 60;
      var sec = _timerController.currentRemainingTime!.sec!;
      var totalSec = (secFromMin + sec) * 1000;
      print(totalSec);
      print((totalSec / allowedMilliSeconds));
      loaderValue = 1 - (totalSec / allowedMilliSeconds);
      setState(() {});
    });
  }

  void stopTimer() {
    if (_timerController.isRunning) {
      _timerController.dispose();
    }
  }

  @override
  void dispose() {
    _cameraController!.dispose();
    super.dispose();
  }

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    final CameraController? oldController = _cameraController;
    if (oldController != null) {
      // `controller` needs to be set to null before getting disposed,
      // to avoid a race condition when we use the controller that is being
      // disposed. This happens when camera permission dialog shows up,
      // which triggers `didChangeAppLifecycleState`, which disposes and
      // re-creates the controller.
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
    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (cameraController.value.hasError) {
        showInSnackBar(
            'Camera error ${cameraController.value.errorDescription}');
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
          // iOS only
          showInSnackBar('Please go to Settings app to enable camera access.');
          break;
        case 'CameraAccessRestricted':
          // iOS only
          showInSnackBar('Camera access is restricted.');
          break;
        case 'AudioAccessDenied':
          showInSnackBar('You have denied audio access.');
          break;
        case 'AudioAccessDeniedWithoutPrompt':
          // iOS only
          showInSnackBar('Please go to Settings app to enable audio access.');
          break;
        case 'AudioAccessRestricted':
          // iOS only
          showInSnackBar('Audio access is restricted.');
          break;
        default:
          showInSnackBar(e);
          break;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  showInSnackBar(m) {
    print(m);
  }

  _initCamera() async {
    cameras = await availableCameras();
    final front = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front);
    _cameraController = CameraController(front, ResolutionPreset.max);
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
      print(e);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Scaffold(
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            CameraPreview(_cameraController!),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_isRecording)
                    CountdownTimer(
                      controller: _timerController,
                      widgetBuilder: (context, crt) {
                        if (crt != null) {
                          return Text(
                            "${crt.min ?? "00"}:${crt.sec ?? "0"}",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w300,
                                shadows: [
                                  BoxShadow(
                                      color: Colors.black54.withOpacity(0.6)),
                                  BoxShadow(
                                      color: Colors.black54.withOpacity(0.6))
                                ]),
                          );
                        } else {
                          return SizedBox();
                        }
                      },
                      onEnd: () {
                        stopTimer();
                      },
                    ),
                  SizedBox(
                    height: 16,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _isRecording ? SizedBox() : _flashModeControlRowWidget(),
                      SizedBox(
                        height: 64,
                        width: 64,
                        child: Stack(
                          children: [
                            ProgressWrapper(
                              progress: loaderValue,
                            ),
                            Center(
                              child: FloatingActionButton(
                                backgroundColor: Colors.red,
                                child: Icon(
                                    _isRecording ? Icons.stop : Icons.circle),
                                onPressed: () => _recordVideo(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _isRecording
                          ? SizedBox()
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
                              icon: Icon(
                                Icons.cameraswitch_outlined,
                                color: Colors.white,
                              )),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _flashModeControlRowWidget() {
    // onSetFlashModeButtonPressed(FlashMode.always);
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
