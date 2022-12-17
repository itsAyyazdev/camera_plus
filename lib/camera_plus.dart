import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera_plus/camera_page.dart';

class CameraPlus {
  static Future startCamera(BuildContext context,
      {required Function(File?) onComplete}) async {
    var file = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (builder) => CameraPage(
                  allowedTimeInMinutes: 2,
                )));
    onComplete(file);
  }
}
