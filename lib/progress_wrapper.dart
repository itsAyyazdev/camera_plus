import 'package:flutter/material.dart';

class ProgressWrapper extends StatelessWidget {
  final double? progress;
  const ProgressWrapper({Key? key, this.progress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: 64,
        width: 64,
        child: CircularProgressIndicator(
          strokeWidth: 8,
          value: progress,
          valueColor:
              AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
          backgroundColor: Colors.black12,
        ),
      ),
    );
  }
}
