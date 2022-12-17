import 'dart:io';

import 'package:camera_plus/library.dart';
import 'package:flutter/material.dart';

class CameraPlus {
  static Future startCamera(BuildContext context,
      {required Function(File?) onComplete,
      int? allowedVideoTimeInSeconds = 120}) async {
    var file = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (builder) => CameraPage(
                  allowedTimeInSeconds: allowedVideoTimeInSeconds,
                )));
    onComplete(file);
  }
}
